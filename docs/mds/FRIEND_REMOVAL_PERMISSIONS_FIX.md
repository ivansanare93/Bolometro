# Fix: Permisos de Firebase para Eliminar Amigos

## Problema Identificado

Al intentar eliminar un amigo, el código de la aplicación intentaba realizar una operación batch de Firestore que eliminaba documentos de las colecciones de amigos de **ambos** usuarios:
1. Eliminar al amigo de la lista del usuario actual ✅
2. Eliminar al usuario actual de la lista del amigo ❌

Sin embargo, las reglas de Firebase solo permitían a cada usuario eliminar de su propia colección, causando un error `PERMISSION_DENIED` en la segunda operación.

### Escenario del Error

**Usuario A** y **Usuario B** son amigos.

Cuando **Usuario A** intenta eliminar a B como amigo:
- ✅ Elimina `users/A/friends/B` (A puede eliminar de su propia colección)
- ❌ Intenta eliminar `users/B/friends/A` (A NO podía eliminar de la colección de B)

**Resultado**: Error de permisos y la amistad no se elimina completamente (queda solo en la colección de B).

## Solución Implementada

### Cambios en firestore.rules

Se añadió una regla especial en la sección de amigos que permite al usuario eliminar su propia entrada de la colección de amigos de otro usuario:

```javascript
match /friends/{friendId} {
  // Regla original: solo el propietario puede escribir/eliminar
  allow write: if request.auth != null && request.auth.uid == userId;
  
  // Nueva regla: permitir eliminar propia entrada cuando se elimina un amigo
  allow delete: if request.auth != null && 
                request.auth.uid == friendId &&
                resource.data.userId == request.auth.uid;
}
```

### Explicación de la Regla

La nueva regla permite que:
- `request.auth != null`: El usuario esté autenticado
- `request.auth.uid == friendId`: El usuario autenticado sea el mismo que el ID del documento (el amigo)
- `resource.data.userId == request.auth.uid`: El documento que se está eliminando contenga el userId del usuario autenticado

Esta validación asegura que:
1. Un usuario solo puede eliminar su propia entrada, no entradas arbitrarias
2. No se pueden eliminar amistades entre otros usuarios
3. Se mantiene la simetría con la regla `create` para aceptar solicitudes
4. Se mantiene la seguridad: no se permite eliminar datos arbitrarios

### Flujo Actualizado

Ahora cuando **Usuario A** elimina a **Usuario B** como amigo:

1. ✅ Usuario A elimina `users/A/friends/B`
   - Permitido por: `request.auth.uid == userId` (A == A)
   
2. ✅ Usuario A elimina `users/B/friends/A`
   - Permitido por la nueva regla:
     - `request.auth.uid == friendId` (A == A) ✓
     - `resource.data.userId == request.auth.uid` (A == A) ✓

## Consideraciones de Seguridad

### ✅ Seguridad Mantenida

La nueva regla NO compromete la seguridad porque:

1. **Validación de identidad**: Solo permite eliminar documentos que corresponden al usuario autenticado
2. **Operación específica**: Solo permite `delete`, no `update` o `create`
3. **Datos validados**: El campo `userId` del documento debe coincidir con el usuario autenticado
4. **No permite eliminación arbitraria**: No se puede eliminar información de otros usuarios

### ✅ Prevención de Ataques

**Escenario 1**: Usuario malicioso intenta eliminar todas las amistades de otro usuario
- ❌ **BLOQUEADO**: `request.auth.uid == friendId` requiere que el ID del usuario coincida con el friendId

**Escenario 2**: Usuario intenta eliminar una amistad entre otros dos usuarios
- ❌ **BLOQUEADO**: El usuario autenticado debe ser uno de los dos amigos (validado por friendId)

**Escenario 3**: Usuario intenta eliminar una entrada que no es suya
- ❌ **BLOQUEADO**: `resource.data.userId == request.auth.uid` requiere que el documento contenga el userId del usuario autenticado

### ✅ Simetría con Regla Create

Esta regla de `delete` es simétrica con la regla de `create` implementada para aceptar solicitudes de amistad:

- **Create**: Permite que un usuario agregue su propia entrada a la colección de amigos de otro usuario (al aceptar una solicitud)
- **Delete**: Permite que un usuario elimine su propia entrada de la colección de amigos de otro usuario (al eliminar un amigo)

Esta simetría asegura consistencia en el modelo de permisos y facilita el mantenimiento.

## Ejemplo Práctico

### Caso de Uso Válido

Usuario A (uid: "user123") elimina a Usuario B (uid: "user456"):

```
Batch Operation:
1. DELETE /users/user123/friends/user456
   - Permitido por: allow write (user123 == user123)
   
2. DELETE /users/user456/friends/user123
   - Permitido por: allow delete
     - request.auth.uid ("user123") == friendId ("user123") ✓
     - resource.data.userId ("user123") == request.auth.uid ("user123") ✓
```

### Caso de Uso Inválido

Usuario A (uid: "user123") intenta eliminar la amistad entre Usuario B y Usuario C:

```
Intento de Operación:
DELETE /users/user456/friends/user789

Validación:
- request.auth.uid ("user123") == friendId ("user789")? ✗
  
Resultado: PERMISSION_DENIED
```

## Testing

### Tests Manuales Recomendados

1. **Test básico de eliminación**:
   - Crear amistad entre Usuario A y Usuario B
   - Usuario A elimina a Usuario B
   - Verificar que:
     - `users/A/friends/B` ya no existe
     - `users/B/friends/A` ya no existe
     - La operación se completa sin errores

2. **Test de seguridad**:
   - Usuario A intenta eliminar directamente `users/B/friends/C` (amistad entre B y C)
   - Debe ser rechazado con error de permisos

3. **Test de reciprocidad**:
   - Usuario A elimina a Usuario B
   - Usuario B intenta eliminar a Usuario A (que ya no es amigo)
   - Debe fallar gracefully (el documento ya no existe)

### Tests Automatizados

Los tests existentes de modelos (`friend_model_test.dart` y `friend_request_model_test.dart`) continúan pasando ya que no dependen de las reglas de Firestore.

Para tests de integración con Firestore, se recomienda usar el Firebase Emulator Suite para validar:
- Permisos de eliminación bidireccional
- Rechazo de eliminaciones no autorizadas
- Comportamiento de operaciones batch

## Código Relacionado

### friends_service.dart

El método `eliminarAmigo` (líneas 288-308) implementa la operación batch:

```dart
Future<bool> eliminarAmigo(String userId, String friendId) async {
  try {
    final batch = _firestore.batch();

    // Eliminar de la colección del usuario actual
    batch.delete(_getFriendsCollection(userId).doc(friendId));

    // Eliminar de la colección del amigo
    batch.delete(_getFriendsCollection(friendId).doc(userId));

    await batch.commit();

    debugPrint('Amistad eliminada: $userId <-> $friendId');
    return true;
  } catch (e) {
    debugPrint('Error al eliminar amistad: $e');
    return false;
  }
}
```

Este código permanece **sin cambios** - solo las reglas de Firestore fueron modificadas.

## Cambios Realizados

### Archivos Modificados

1. **firestore.rules**
   - Añadida regla especial de `delete` en la sección de amigos (líneas 52-57)
   - Comentarios explicativos agregados

2. **docs/FRIENDS_SYSTEM.md**
   - Actualizada documentación de seguridad para reflejar la nueva regla de eliminación

3. **docs/FRIEND_REMOVAL_PERMISSIONS_FIX.md** (nuevo)
   - Documentación detallada del problema y la solución

### Archivos NO Modificados

- `lib/services/friends_service.dart`: El código de servicio permanece sin cambios
- `lib/screens/friends_screen.dart`: La UI permanece sin cambios
- Modelos: Sin cambios
- Tests: Sin cambios

## Historial de Cambios Relacionados

Este fix complementa el trabajo previo realizado en:
- **FRIEND_REQUEST_PERMISSIONS_FIX.md**: Fix para aceptar solicitudes de amistad
- **FRIENDS_SYSTEM.md**: Documentación general del sistema de amigos

Juntos, estos cambios completan el sistema de permisos para:
- ✅ Enviar solicitudes de amistad
- ✅ Aceptar solicitudes de amistad (bidireccional)
- ✅ Rechazar solicitudes de amistad
- ✅ **Eliminar amigos (bidireccional)** ← Este fix

## Conclusión

Esta solución mínima corrige el problema de permisos al eliminar amigos, permitiendo que la operación batch se complete exitosamente mientras mantiene la seguridad de Firestore.

La implementación es:
- ✅ **Mínima**: Solo una regla adicional en firestore.rules
- ✅ **Segura**: Validaciones estrictas para prevenir abuso
- ✅ **Compatible**: No requiere cambios en el código de la aplicación
- ✅ **Documentada**: Explicación clara del problema y la solución
- ✅ **Simétrica**: Consistente con la regla de create existente
- ✅ **Testeada**: Validación de seguridad mediante análisis de casos de uso

---

**Fecha**: 2026-02-05  
**Implementado por**: GitHub Copilot Agent  
**Issue**: "Revisa las reglas para eliminar amigos, ya que lo he testeado y ha dado error"
