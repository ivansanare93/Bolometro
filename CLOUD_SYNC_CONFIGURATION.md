# Configuración de Sincronización en la Nube

## Resumen

Este documento describe la configuración y funcionamiento de la sincronización de datos en la nube para la aplicación Bolómetro. La sincronización incluye sesiones de bolos, perfil de usuario y **datos de gamificación** (progreso y logros).

## Cambios Recientes

### 1. Reglas de Seguridad de Firestore

Se agregaron reglas de seguridad para la subcolección de gamificación en `firestore.rules`:

```firestore
match /users/{userId}/gamification/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

**Qué permite:**
- Lectura y escritura del documento `progress` (progreso del usuario)
- Lectura y escritura de la subcolección `achievements` (logros)
- Solo para usuarios autenticados que son propietarios de los datos

**Por qué es importante:**
Sin estas reglas, todas las operaciones de gamificación fallarían con error `PERMISSION_DENIED`.

### 2. Integración de Gamificación en DataRepository

Se actualizó `lib/repositories/data_repository.dart` para incluir datos de gamificación en todas las operaciones de sincronización:

#### a) subirANube() - Subir a la Nube

**Antes:**
- Subía solo sesiones y perfil

**Ahora:**
- Sube sesiones
- Sube perfil
- **Sube datos de gamificación** (UserProgress y Achievement)

**Flujo de datos:**
```
1. Validar autenticación y conexión
2. Obtener sesiones locales de Hive
3. Obtener perfil local de Hive
4. Obtener gamificación local de Hive (userProgress y achievements boxes)
5. Eliminar sesiones remotas existentes en Firestore
6. Subir sesiones a Firestore
7. Subir gamificación a Firestore usando sincronizarGamificacion()
```

#### b) descargarDesdeNube() - Descargar desde la Nube

**Antes:**
- Descargaba solo sesiones y perfil

**Ahora:**
- Descarga sesiones
- Descarga perfil
- **Descarga datos de gamificación** (UserProgress y Achievement)

**Flujo de datos:**
```
1. Validar conexión y usuario
2. Descargar sesiones desde Firestore
3. Limpiar y guardar sesiones en Hive
4. Descargar perfil desde Firestore
5. Limpiar y guardar perfil en Hive
6. Descargar gamificación desde Firestore (obtenerProgreso() y obtenerLogros())
7. Limpiar y guardar gamificación en Hive boxes correspondientes
```

#### c) sincronizarANube() - Sincronización Inteligente

**Antes:**
- Sincronizaba solo sesiones y perfil

**Ahora:**
- Sincroniza sesiones (merge inteligente)
- Sincroniza perfil
- **Sincroniza datos de gamificación**

**Flujo de datos:**
```
1. Validar autenticación y conexión
2. Obtener sesiones remotas (fuente de verdad)
3. Obtener sesiones locales
4. Filtrar sesiones nuevas (que no existen en remoto)
5. Subir solo sesiones nuevas y perfil
6. Sincronizar gamificación usando sincronizarGamificacion()
7. Descargar estado final de sesiones
8. Actualizar almacenamiento local
```

## Estructura de Datos en Firestore

```
users/{userId}/
  ├── perfil (documento)
  ├── sesiones/{sesionId} (subcolección)
  ├── friends/{friendId} (subcolección)
  ├── friendRequests/{requestId} (subcolección)
  ├── notifications/{notificationId} (subcolección)
  └── gamification/ (subcolección) ← NUEVO
      └── progress (documento)
          └── achievements/{achievementId} (subcolección)
```

## Almacenamiento Local (Hive)

Los datos de gamificación se almacenan en dos boxes de Hive:

1. **userProgress** - Box que contiene un único documento UserProgress con:
   - level (nivel del usuario)
   - xp (puntos de experiencia)
   - totalGames (total de partidas jugadas)
   - otros campos de progreso

2. **achievements** - Box que contiene múltiples Achievement identificados por ID:
   - id (identificador único del logro)
   - nameKey (clave de traducción del nombre)
   - descriptionKey (clave de traducción de la descripción)
   - icon (nombre del icono)
   - xpReward (recompensa de XP)
   - type (tipo de logro)
   - rarity (rareza)
   - targetValue (valor objetivo)
   - currentValue (progreso actual)
   - isUnlocked (si está desbloqueado)
   - unlockedAt (fecha de desbloqueo)

## Manejo de Errores

**Estrategia de Resiliencia:**
Todos los métodos de sincronización envuelven las operaciones de gamificación en bloques `try-catch` para asegurar que:

1. Una falla en la sincronización de gamificación NO rompa la sincronización de sesiones
2. Los errores se registren en el log para depuración
3. La sincronización continúe sin datos de gamificación si hay un error

**Ejemplo en subirANube():**
```dart
try {
  // Intentar subir gamificación
  await _firestoreService.sincronizarGamificacion(...);
} catch (e) {
  debugPrint('Error al sincronizar gamificación: $e');
  // Continuar sin gamificación
}
```

## Métodos de FirestoreService

El servicio de Firestore incluye los siguientes métodos para gamificación:

### guardarProgreso(userId, progress)
Guarda el progreso del usuario en Firestore.

**Ubicación:** `users/{userId}/gamification/progress`

### obtenerProgreso(userId)
Obtiene el progreso del usuario desde Firestore.

**Retorna:** `UserProgress?` (null si no existe)

### guardarLogro(userId, achievement)
Guarda un logro individual en Firestore.

**Ubicación:** `users/{userId}/gamification/progress/achievements/{achievementId}`

### obtenerLogros(userId)
Obtiene todos los logros del usuario desde Firestore.

**Retorna:** `List<Achievement>` (vacío si no hay logros)

### sincronizarGamificacion(userId, progress, achievements)
Sincroniza progreso y todos los logros en una operación batch (atómica).

**Ventajas:**
- Operación atómica: todo se guarda o nada se guarda
- Más eficiente que guardar uno por uno
- Reduce el número de operaciones de escritura en Firestore

## Uso en la Aplicación

### Desde la Interfaz de Usuario

Los usuarios pueden acceder a las opciones de sincronización desde:

**Home Screen → Settings (⚙️) → Sincronizar Datos**

Tres opciones disponibles:

1. **Subir a la Nube** (Upload to Cloud)
   - Descripción: "Sobrescribir la nube con los datos locales"
   - Acción: `dataRepository.subirANube()`
   - Uso: Cuando quieres que tus datos locales reemplacen todo en la nube

2. **Descargar desde la Nube** (Download from Cloud)
   - Descripción: "Sobrescribir los datos locales con los datos de la nube"
   - Acción: `dataRepository.descargarDesdeNube()`
   - Uso: Cuando quieres que los datos de la nube reemplacen tus datos locales

3. **Sincronización Inteligente** (Smart Sync)
   - Descripción: "Combinar datos locales y de la nube"
   - Acción: `dataRepository.sincronizarANube()`
   - Uso: Para una sincronización bidireccional que combina lo mejor de ambos

### Sincronización Automática

La sincronización inteligente se ejecuta automáticamente:
- Al iniciar sesión por primera vez
- Cuando el usuario se autentica

**Ubicación en código:** `lib/screens/login_screen.dart`

## Pruebas

### Tests Existentes

**Archivo:** `test/data_repository_test.dart`

Tests básicos que verifican:
- Validación de autenticación antes de sincronizar
- Manejo de errores cuando no hay conexión
- Comportamiento del flag `isSyncing`

### Tests de Gamificación

**Archivo:** `test/cloud_sync_gamification_test.dart`

Tests específicos que verifican:
- Existencia de métodos de gamificación en FirestoreService
- Documentación de flujos de datos
- Serialización de UserProgress y Achievement
- Estrategias de manejo de errores

## Verificación Manual

Para verificar que la configuración funciona correctamente:

### 1. Preparación
```bash
# Asegúrate de tener Firebase configurado
flutter pub get
```

### 2. Subir a la Nube
1. Inicia sesión en la app
2. Juega algunas partidas (genera sesiones y gamificación)
3. Ve a Settings → Sincronizar Datos → Subir a la Nube
4. Verifica en Firebase Console que los datos están en:
   - `users/{userId}/sesiones/`
   - `users/{userId}/gamification/progress`
   - `users/{userId}/gamification/progress/achievements/`

### 3. Descargar desde la Nube
1. Borra los datos locales de la app (reinstalar o limpiar caché)
2. Inicia sesión
3. Ve a Settings → Sincronizar Datos → Descargar desde la Nube
4. Verifica que las sesiones y gamificación se restauraron

### 4. Sincronización Inteligente
1. Crea sesiones locales nuevas
2. Ve a Settings → Sincronizar Datos → Sincronización Inteligente
3. Verifica que las sesiones nuevas se subieron
4. Verifica que las sesiones existentes se mantienen

## Solución de Problemas

### Error: PERMISSION_DENIED

**Causa:** Las reglas de Firestore no permiten el acceso a gamificación

**Solución:**
1. Verifica que `firestore.rules` incluye las reglas para `gamification/{document=**}`
2. Despliega las reglas con: `firebase deploy --only firestore:rules`

### Error: No se sincronizan logros

**Causa posible:** Los boxes de Hive no están abiertos

**Solución:**
Los boxes se abren automáticamente en los métodos de sincronización. Si hay error, revisa los logs.

### Error: Datos de gamificación no aparecen después de descargar

**Causa posible:** No hay datos en Firestore

**Solución:**
1. Verifica en Firebase Console que existen datos en `gamification/`
2. Sube datos primero con "Subir a la Nube"

## Mejoras Futuras

1. **Sincronización en tiempo real:** Usar Firestore listeners para actualizar datos automáticamente
2. **Resolución de conflictos:** Implementar estrategias más sofisticadas para conflictos de datos
3. **Sincronización parcial:** Permitir sincronizar solo ciertos tipos de datos
4. **Caché offline:** Mejorar el manejo de datos cuando no hay conexión

## Referencias

- **Código fuente:**
  - `lib/repositories/data_repository.dart` - Lógica de sincronización
  - `lib/services/firestore_service.dart` - Operaciones de Firestore
  - `lib/screens/home.dart` - UI de sincronización

- **Modelos:**
  - `lib/models/user_progress.dart` - Modelo de progreso
  - `lib/models/achievement.dart` - Modelo de logros

- **Configuración:**
  - `firestore.rules` - Reglas de seguridad
  - `firebase.json` - Configuración de Firebase

- **Tests:**
  - `test/data_repository_test.dart` - Tests básicos
  - `test/cloud_sync_gamification_test.dart` - Tests de gamificación
