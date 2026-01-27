# Sincronización a la Nube - Implementación Completa

## Resumen

Se ha completado la implementación de la función `sincronizarANube` en el repositorio de datos para garantizar la sincronización correcta de datos locales (Hive) con Firebase Firestore.

## Cambios Implementados

### 1. Validación de Firebase
✅ **Dependencias verificadas en `pubspec.yaml`:**
- `firebase_core: ^2.31.0`
- `firebase_auth: ^4.19.3`
- `cloud_firestore: ^4.16.1`
- `google_sign_in: ^6.2.1`

✅ **Archivo de configuración:**
- `android/app/google-services.json` está presente y configurado correctamente

### 2. Mejoras en `sincronizarANube` (data_repository.dart)

**Validaciones agregadas:**
- ✅ Verificación de autenticación del usuario antes de sincronizar
- ✅ Validación de modo online
- ✅ Prevención de sincronizaciones simultáneas
- ✅ Uso de excepciones personalizadas para manejo de errores tipo-seguro

**Funcionalidades implementadas:**
- ✅ Iteración completa sobre datos locales en Hive (sesiones y perfil)
- ✅ Sincronización de todas las sesiones almacenadas localmente
- ✅ Sincronización del perfil de usuario
- ✅ Logs detallados del progreso de sincronización
- ✅ Manejo robusto de errores con excepciones específicas:
  - `NetworkException` para problemas de red/conectividad
  - `PermissionException` para errores de permisos de Firestore
  - `AuthenticationException` para usuarios no autenticados
  - `OfflineModeException` para intentos de sync en modo offline
  - `SyncException` para errores generales de sincronización

### 3. Mejoras en FirestoreService

**Método `sincronizarDatosLocales`:**
- ✅ Sincronización resiliente que continúa incluso si fallan sesiones individuales
- ✅ Contador de progreso configurable (cada N sesiones, definido en constantes)
- ✅ Resumen detallado de sincronización (sesiones exitosas vs errores)
- ✅ Creación automática de colecciones y documentos en Firestore
- ✅ Uso de excepciones personalizadas para mejor manejo de errores

**Método `guardarSesion`:**
- ✅ Uso de `SetOptions(merge: true)` para actualizar sesiones existentes
- ✅ Creación automática de colecciones si no existen
- ✅ Excepciones específicas para permisos y problemas de red

**Método `guardarPerfil`:**
- ✅ Uso de `SetOptions(merge: true)` para no sobrescribir otros campos
- ✅ Creación automática de documentos si no existen
- ✅ Excepciones específicas para permisos y problemas de red

### 4. Constantes y Configuración (app_constants.dart)

**Nueva constante agregada:**
- ✅ `intervaloLogSincronizacion = 10` - Define cada cuántas sesiones se registra el progreso durante la sincronización

### 5. Excepciones Personalizadas (exceptions/sync_exceptions.dart)

**Nuevas clases de excepción:**
- ✅ `NetworkException` - Problemas de conectividad
- ✅ `PermissionException` - Errores de permisos en Firestore
- ✅ `AuthenticationException` - Usuario no autenticado
- ✅ `OfflineModeException` - Operación no disponible sin conexión
- ✅ `SyncException` - Errores generales de sincronización con causa opcional

**Ventajas:**
- Manejo de errores tipo-seguro (no depende de strings)
- Mejor experiencia de desarrollo con autocompletado
- Facilita testing con tipos específicos
- Permite catch selectivo de diferentes tipos de errores

### 6. Estructura de Datos en Firestore

**Colecciones creadas automáticamente:**

```
/users/{userId}/
  ├── perfil (documento)
  │   └── {datos del perfil}
  └── sesiones/ (colección)
      ├── {timestamp1}/
      │   ├── fecha
      │   ├── lugar
      │   ├── tipo
      │   ├── notas
      │   └── partidas[]
      └── {timestamp2}/
          └── ...
```

**Ejemplo de sesión en Firestore:**
```json
{
  "fecha": "2024-01-27T12:00:00.000Z",
  "lugar": "Bowling Center",
  "tipo": "Entrenamiento",
  "notas": "Sesión de práctica",
  "partidas": [
    {
      "fecha": "2024-01-27T12:00:00.000Z",
      "lugar": "Bowling Center",
      "total": 150,
      "frames": [...],
      "pinesPorTiro": [...]
    }
  ]
}
```

### 7. Confirmación de Autenticación

✅ **Validación implementada:**
- El método `sincronizarANube` verifica que `_userId != null` antes de proceder
- Lanza `AuthenticationException` si el usuario no está autenticado
- El `AuthService` ya maneja la autenticación con Google

### 8. Manejo de Errores

**Excepciones lanzadas:**

1. **`AuthenticationException`:**
   - Cuando: Usuario no autenticado
   - Mensaje: "No se puede sincronizar: usuario no autenticado. Por favor, inicia sesión antes de sincronizar."

2. **`OfflineModeException`:**
   - Cuando: Modo offline
   - Mensaje: "No se puede sincronizar: modo offline. Por favor, verifica tu conexión a Internet."

3. **`NetworkException`:**
   - Cuando: Errores de red durante la sincronización
   - Mensaje: "Error de conexión durante la sincronización. Por favor, verifica tu conexión a Internet e intenta nuevamente."

4. **`PermissionException`:**
   - Cuando: Errores de permisos en Firestore
   - Mensaje: "Error de permisos durante la sincronización. Por favor, verifica que tienes los permisos necesarios en Firebase."

5. **`SyncException`:**
   - Cuando: Otros errores de sincronización
   - Mensaje: "Error durante la sincronización. Por favor, intenta nuevamente más tarde."

### 9. Tests Implementados

✅ Archivo: `test/data_repository_test.dart`

**Tests incluidos:**
- Validación de autenticación antes de sincronizar (usando `AuthenticationException`)
- Verificación del flag `isSyncing`
- Comportamiento de `isOnlineMode`
- Operaciones básicas de guardar/obtener sesiones
- Operaciones básicas de guardar/obtener perfil

## Uso de la Función

```dart
// Ejemplo de uso con manejo de errores específicos
final repository = DataRepository();
final authService = AuthService();

// 1. Autenticar usuario
await authService.signInWithGoogle();

// 2. Configurar usuario en el repositorio
repository.setUser(authService.userId);

// 3. Sincronizar datos con manejo de errores específico
try {
  await repository.sincronizarANube();
  print('Sincronización exitosa');
} on AuthenticationException catch (e) {
  print('Error de autenticación: $e');
  // Redirigir al login
} on NetworkException catch (e) {
  print('Error de red: $e');
  // Mostrar mensaje para reintentar
} on PermissionException catch (e) {
  print('Error de permisos: $e');
  // Contactar soporte
} on SyncException catch (e) {
  print('Error de sincronización: $e');
  // Mensaje genérico de error
} catch (e) {
  print('Error inesperado: $e');
}
```

## Flujo de Sincronización

1. **Validaciones previas:**
   - ✅ Usuario autenticado (`AuthenticationException` si falla)
   - ✅ Modo online activo (`OfflineModeException` si falla)
   - ✅ No hay sincronización en curso (retorna silenciosamente)

2. **Obtención de datos locales:**
   - ✅ Leer todas las sesiones de Hive
   - ✅ Leer perfil de usuario de Hive

3. **Sincronización a Firestore:**
   - ✅ Iterar sobre cada sesión
   - ✅ Guardar sesión en Firestore (con manejo de errores individual)
   - ✅ Guardar perfil si existe
   - ✅ Logs de progreso (cada N sesiones, configurable)

4. **Finalización:**
   - ✅ Resumen de sincronización
   - ✅ Actualizar flag `isSyncing`
   - ✅ Notificar listeners

## Pruebas Recomendadas

### Pruebas con conexión
1. ✅ Crear sesiones localmente
2. ✅ Autenticarse con Firebase
3. ✅ Ejecutar sincronización
4. ✅ Verificar en Firebase Console que los datos aparecen

### Pruebas sin conexión
1. ✅ Desactivar red
2. ✅ Intentar sincronizar
3. ✅ Verificar `NetworkException` con mensaje apropiado
4. ✅ Reactivar red y reintentar

### Pruebas sin autenticación
1. ✅ No iniciar sesión
2. ✅ Intentar sincronizar
3. ✅ Verificar `AuthenticationException` con mensaje apropiado

## Reglas de Seguridad de Firestore Recomendadas

Para que la sincronización funcione correctamente, asegúrate de tener reglas apropiadas en Firestore:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir lectura/escritura solo a usuarios autenticados en sus propios datos
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Mejoras Implementadas Basadas en Code Review

### 1. Eliminación de Números Mágicos
- ✅ Agregado `AppConstants.intervaloLogSincronizacion` para configurar frecuencia de logs
- ✅ Uso consistente de constantes en toda la aplicación

### 2. Excepciones Tipo-Seguras
- ✅ Creadas clases de excepción personalizadas en lugar de detección basada en strings
- ✅ Mejor manejo de errores con tipos específicos
- ✅ Facilita testing y debugging

### 3. Lógica de Condiciones Mejorada
- ✅ Reordenamiento de condición a `sesionesSubidas == 0 && erroresSesiones > 0` para mayor claridad
- ✅ Mejor expresión de la intención del código

## Conclusión

La implementación está completa y cumple con todos los requisitos:
- ✅ Validación de configuración de Firebase
- ✅ Función `sincronizarANube` completamente implementada
- ✅ Manejo robusto de errores con excepciones tipo-seguras
- ✅ Creación automática de colecciones/documentos
- ✅ Autenticación verificada antes de sincronizar
- ✅ Tests básicos implementados
- ✅ Documentación completa
- ✅ Code review feedback implementado
- ✅ Sin vulnerabilidades de seguridad detectadas por CodeQL

