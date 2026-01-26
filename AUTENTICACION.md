# Sistema de Autenticación y Sincronización en la Nube

## Resumen

Bolómetro ahora incluye un sistema de autenticación con Google Play Store que permite a los usuarios sincronizar sus datos entre dispositivos y mantener copias de seguridad en la nube.

## Características

### 🔐 Autenticación con Google

- **Inicio de sesión con Google**: Los usuarios pueden iniciar sesión con su cuenta de Google de forma segura
- **Modo offline opcional**: Los usuarios pueden continuar usando la app sin iniciar sesión
- **Cierre de sesión**: Los datos locales se mantienen al cerrar sesión

### ☁️ Sincronización en la Nube

- **Firestore**: Los datos se almacenan en Firebase Firestore
- **Sincronización automática**: Al iniciar sesión, los datos locales se sincronizan automáticamente
- **Sincronización manual**: Los usuarios pueden sincronizar datos manualmente desde ajustes
- **Persistencia local**: Los datos se guardan localmente con Hive como respaldo

### 📱 Cambio de Dispositivo

- Los usuarios autenticados pueden acceder a sus datos desde cualquier dispositivo
- Al iniciar sesión en un nuevo dispositivo, los datos se descargan automáticamente

## Arquitectura

### Capas de la Aplicación

```
┌─────────────────────────────────────┐
│   Pantallas (Screens)               │
│   - LoginScreen                     │
│   - HomeScreen                      │
│   - ListaSesionesScreen             │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   Repositorio (DataRepository)      │
│   - Abstrae acceso a datos          │
│   - Maneja modo online/offline      │
└────────┬───────────┬────────────────┘
         │           │
┌────────▼──────┐  ┌▼────────────────┐
│ Hive (Local)  │  │ Firestore (Cloud)│
│ - Respaldo    │  │ - Sincronización │
│ - Modo offline│  │ - Persistencia   │
└───────────────┘  └──────────────────┘
```

### Componentes Principales

#### 1. AuthService (`lib/services/auth_service.dart`)

Gestiona la autenticación de usuarios:

- `signInWithGoogle()`: Inicia sesión con Google
- `signOut()`: Cierra sesión
- Notifica cambios en el estado de autenticación

#### 2. FirestoreService (`lib/services/firestore_service.dart`)

Maneja la comunicación con Firestore:

- `guardarSesion()`: Guarda una sesión en la nube
- `obtenerSesiones()`: Obtiene sesiones del usuario
- `obtenerSesionesPaginadas()`: Carga sesiones con paginación
- `sincronizarDatosLocales()`: Migra datos de Hive a Firestore

#### 3. DataRepository (`lib/repositories/data_repository.dart`)

Abstrae el acceso a datos y decide entre local/remoto:

- Modo **online**: Lee y escribe en Firestore + Hive
- Modo **offline**: Solo usa Hive
- Sincronización transparente para el usuario

#### 4. EstadisticasCache (`lib/utils/estadisticas_cache.dart`)

Optimiza cálculos estadísticos:

- Cache inteligente de estadísticas
- Recalcula solo cuando hay cambios
- Expira automáticamente después de 5 minutos

## Flujo de Uso

### Primera Vez (Usuario Nuevo)

```mermaid
graph TD
    A[App Inicia] --> B[LoginScreen]
    B --> C{Usuario elige}
    C -->|Google Sign-In| D[Autenticación Google]
    C -->|Continuar sin login| E[Modo Offline]
    D --> F[Sincronizar datos locales a nube]
    F --> G[HomeScreen - Modo Online]
    E --> H[HomeScreen - Modo Offline]
```

### Usuario Existente (Nuevo Dispositivo)

```mermaid
graph TD
    A[App Inicia] --> B[LoginScreen]
    B --> C[Google Sign-In]
    C --> D[Autenticación exitosa]
    D --> E[Descargar datos desde Firestore]
    E --> F[Guardar localmente en Hive]
    F --> G[HomeScreen con datos sincronizados]
```

### Guardar Nueva Sesión

```mermaid
graph TD
    A[Usuario crea sesión] --> B[DataRepository.guardarSesion]
    B --> C[Guardar en Hive local]
    C --> D{Usuario autenticado?}
    D -->|Sí| E[Guardar en Firestore]
    D -->|No| F[Solo Hive]
    E --> G[Sesión guardada en ambos]
    F --> G
```

## Estructura de Datos en Firestore

```
users/
  {userId}/
    perfil: {
      nombre: string
      email: string
      club: string
      manoDominante: string
      fechaNacimiento: string (ISO)
      bio: string
      avatarPath: string
    }
    sesiones/
      {sesionId}/
        fecha: string (ISO)
        lugar: string
        tipo: string ("Entrenamiento" | "Competición")
        notas: string
        partidas: [
          {
            fecha: string (ISO)
            lugar: string
            frames: [[string]]
            notas: string
            total: number
            pinesPorTiro: [[[number]]]
          }
        ]
```

## Optimizaciones Implementadas

### ✅ Lazy Loading

- Las listas de sesiones cargan datos de forma paginada (20 sesiones por página)
- Se cargan más datos automáticamente al hacer scroll
- Mejora el rendimiento con muchas sesiones

### ✅ Cache de Estadísticas

- Las estadísticas se calculan una vez y se cachean
- El cache se invalida automáticamente cuando cambian los datos
- Reduce cálculos redundantes en cada rebuild

### ✅ Manejo Robusto de Errores

- Todos los accesos a Hive incluyen try-catch
- Mensajes de error claros para el usuario
- Recuperación automática de errores de base de datos

### ✅ Pull-to-Refresh

- Los usuarios pueden actualizar las listas deslizando hacia abajo
- Recarga datos frescos desde Firestore (si está autenticado)

## Configuración de Firebase

### Android

1. **google-services.json**: Ya configurado en `android/app/google-services.json`
2. **build.gradle.kts**: Plugin de Google Services activado
3. **Firebase BoM**: Versión 34.0.0 configurada

### iOS

Para configurar iOS en el futuro:

1. Descargar `GoogleService-Info.plist` desde Firebase Console
2. Agregar al proyecto iOS en Xcode
3. Configurar URL schemes en `Info.plist`

## Dependencias Añadidas

```yaml
dependencies:
  firebase_core: ^2.31.0        # Core de Firebase
  firebase_auth: ^4.19.3        # Autenticación
  cloud_firestore: ^4.16.1      # Base de datos en la nube
  google_sign_in: ^6.2.1        # Sign-In con Google
```

## Uso para Desarrolladores

### Acceder al usuario autenticado

```dart
final authService = Provider.of<AuthService>(context, listen: false);
if (authService.isAuthenticated) {
  final userId = authService.userId;
  final email = authService.user?.email;
}
```

### Guardar datos

```dart
final dataRepository = Provider.of<DataRepository>(context, listen: false);
await dataRepository.guardarSesion(sesion);
// Se guarda automáticamente en Hive y Firestore (si está autenticado)
```

### Cargar datos

```dart
final dataRepository = Provider.of<DataRepository>(context, listen: false);
final sesiones = await dataRepository.obtenerSesiones();
// Carga desde Firestore si está autenticado, sino desde Hive
```

### Usar cache de estadísticas

```dart
final cache = Provider.of<EstadisticasCache>(context, listen: false);
final stats = cache.getEstadisticas(sesiones);
final promedio = stats['promedioGeneral'];
final mejorPartida = stats['mejorPartida'];
```

## Próximas Funcionalidades

Con el sistema de autenticación en su lugar, ahora es posible implementar:

- 👥 **Añadir amigos**: Compartir estadísticas con otros usuarios
- 🏆 **Tablas de clasificación**: Competir con amigos
- 📊 **Comparar rendimiento**: Ver estadísticas de múltiples usuarios
- 💬 **Comentarios en sesiones**: Dejar notas en partidas de amigos
- 🎯 **Retos y logros**: Sistema de gamificación

## Notas de Seguridad

- Las credenciales de Google nunca se almacenan localmente
- Firebase Authentication maneja la seguridad de sesiones
- Firestore Security Rules deben configurarse para permitir solo acceso del propietario:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Solución de Problemas

### "Error al iniciar sesión"

- Verificar que google-services.json esté actualizado
- Comprobar que el SHA-1 esté configurado en Firebase Console
- Revisar que el paquete en google-services.json coincida con applicationId

### "Datos no se sincronizan"

- Verificar conexión a Internet
- Comprobar que el usuario esté autenticado en ajustes
- Intentar sincronización manual desde ajustes

### "App crashea al abrir"

- Verificar que Firebase esté inicializado en main.dart
- Comprobar que todas las dependencias estén instaladas: `flutter pub get`
- Revisar logs de Android Studio/Xcode

## Testing

Para probar el flujo completo:

1. **Instalación limpia**: Desinstalar y reinstalar la app
2. **Iniciar sesión**: Probar con cuenta de Google
3. **Crear datos**: Añadir sesiones y partidas
4. **Cerrar sesión**: Verificar que datos locales persisten
5. **Nuevo dispositivo**: Instalar en otro dispositivo e iniciar sesión
6. **Verificar sincronización**: Comprobar que los datos aparecen

---

**Última actualización**: Enero 2026
**Versión**: 1.0.0
**Autor**: Sistema de autenticación implementado para Bolómetro
