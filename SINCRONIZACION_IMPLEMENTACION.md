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
- ✅ Mensajes de error específicos y descriptivos

**Funcionalidades implementadas:**
- ✅ Iteración completa sobre datos locales en Hive (sesiones y perfil)
- ✅ Sincronización de todas las sesiones almacenadas localmente
- ✅ Sincronización del perfil de usuario
- ✅ Logs detallados del progreso de sincronización
- ✅ Manejo robusto de errores con mensajes específicos para:
  - Problemas de red/conectividad
  - Errores de permisos de Firestore
  - Errores generales con contexto

### 3. Mejoras en FirestoreService

**Método `sincronizarDatosLocales`:**
- ✅ Sincronización resiliente que continúa incluso si fallan sesiones individuales
- ✅ Contador de progreso cada 10 sesiones
- ✅ Resumen detallado de sincronización (sesiones exitosas vs errores)
- ✅ Creación automática de colecciones y documentos en Firestore

**Método `guardarSesion`:**
- ✅ Uso de `SetOptions(merge: true)` para actualizar sesiones existentes
- ✅ Creación automática de colecciones si no existen
- ✅ Mensajes de error específicos para permisos y problemas de red

**Método `guardarPerfil`:**
- ✅ Uso de `SetOptions(merge: true)` para no sobrescribir otros campos
- ✅ Creación automática de documentos si no existen
- ✅ Mensajes de error específicos para permisos y problemas de red

### 4. Estructura de Datos en Firestore

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

### 5. Confirmación de Autenticación

✅ **Validación implementada:**
- El método `sincronizarANube` verifica que `_userId != null` antes de proceder
- Lanza excepción con mensaje claro si el usuario no está autenticado
- El `AuthService` ya maneja la autenticación con Google

### 6. Manejo de Errores

**Tipos de errores manejados:**

1. **Usuario no autenticado:**
   - Mensaje: "No se puede sincronizar: usuario no autenticado. Por favor, inicia sesión antes de sincronizar."

2. **Modo offline:**
   - Mensaje: "No se puede sincronizar: modo offline. Por favor, verifica tu conexión a Internet."

3. **Errores de red:**
   - Mensaje: "Error de conexión durante la sincronización. Por favor, verifica tu conexión a Internet e intenta nuevamente."

4. **Errores de permisos:**
   - Mensaje: "Error de permisos durante la sincronización. Por favor, verifica que tienes los permisos necesarios en Firebase."

5. **Errores generales:**
   - Mensaje: "Error durante la sincronización: {detalle}. Por favor, intenta nuevamente más tarde."

### 7. Tests Implementados

✅ Archivo: `test/data_repository_test.dart`

**Tests incluidos:**
- Validación de autenticación antes de sincronizar
- Verificación del flag `isSyncing`
- Comportamiento de `isOnlineMode`
- Operaciones básicas de guardar/obtener sesiones
- Operaciones básicas de guardar/obtener perfil

## Uso de la Función

```dart
// Ejemplo de uso
final repository = DataRepository();
final authService = AuthService();

// 1. Autenticar usuario
await authService.signInWithGoogle();

// 2. Configurar usuario en el repositorio
repository.setUser(authService.userId);

// 3. Sincronizar datos
try {
  await repository.sincronizarANube();
  print('Sincronización exitosa');
} catch (e) {
  print('Error: $e');
  // Mostrar mensaje al usuario
}
```

## Flujo de Sincronización

1. **Validaciones previas:**
   - ✅ Usuario autenticado
   - ✅ Modo online activo
   - ✅ No hay sincronización en curso

2. **Obtención de datos locales:**
   - ✅ Leer todas las sesiones de Hive
   - ✅ Leer perfil de usuario de Hive

3. **Sincronización a Firestore:**
   - ✅ Iterar sobre cada sesión
   - ✅ Guardar sesión en Firestore (con manejo de errores individual)
   - ✅ Guardar perfil si existe
   - ✅ Logs de progreso

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
3. ✅ Verificar mensaje de error apropiado
4. ✅ Reactivar red y reintentar

### Pruebas sin autenticación
1. ✅ No iniciar sesión
2. ✅ Intentar sincronizar
3. ✅ Verificar mensaje de error apropiado

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

## Conclusión

La implementación está completa y cumple con todos los requisitos:
- ✅ Validación de configuración de Firebase
- ✅ Función `sincronizarANube` completamente implementada
- ✅ Manejo robusto de errores
- ✅ Creación automática de colecciones/documentos
- ✅ Autenticación verificada antes de sincronizar
- ✅ Tests básicos implementados
- ✅ Documentación completa
