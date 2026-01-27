# Guía de Analytics

Bolometro utiliza Firebase Analytics para rastrear el comportamiento del usuario y el rendimiento de la aplicación.

## Descripción General

El `AnalyticsService` proporciona una forma centralizada de registrar eventos de analytics en toda la aplicación.

## Configuración

### 1. Configuración de Firebase

Asegúrate de que Firebase esté configurado correctamente:
- `android/app/google-services.json` - Configuración Android
- `ios/Runner/GoogleService-Info.plist` - Configuración iOS

### 2. Habilitar Analytics en la Consola de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Navega a Analytics
4. Habilita Google Analytics

## Usar el Servicio de Analytics

### Instancia Singleton

```dart
import 'package:bolometro/services/analytics_service.dart';
import 'package:provider/provider.dart';

// Obtener instancia vía Provider
final analytics = Provider.of<AnalyticsService>(context, listen: false);

// O usar singleton directamente
final analytics = AnalyticsService();
```

## Eventos Disponibles

### Vistas de Pantalla

Se rastrean automáticamente al usar el observer de analytics, o manualmente:

```dart
analytics.logScreenView('home_screen');
analytics.logScreenView('statistics_screen');
```

### Eventos de Sesión

```dart
// Al crear una nueva sesión
analytics.logSessionCreated('training'); // o 'competition'

// Al editar una sesión
analytics.logSessionEdited();

// Al eliminar una sesión
analytics.logSessionDeleted();
```

### Eventos de Partida

```dart
// Al crear una nueva partida
analytics.logGameCreated(150); // Pasar la puntuación

// Al editar una partida
analytics.logGameEdited();

// Al eliminar una partida
analytics.logGameDeleted();
```

### Autenticación de Usuario

```dart
// Cuando el usuario inicia sesión
analytics.logLogin('google'); // u otro método

// Cuando el usuario cierra sesión
analytics.logSignOut();

// Establecer ID de usuario (llamado automáticamente en login)
analytics.setUserId('user123');
```

### Sincronización de Datos

```dart
// Al sincronizar datos con la nube
analytics.logSync();
```

### Eventos de Estadísticas

```dart
// Al ver la página de estadísticas
analytics.logStatisticsViewed('all'); // o 'training', 'competition'

// Al ver un gráfico específico
analytics.logChartViewed('histogram');
analytics.logChartViewed('moving_average');
analytics.logChartViewed('heatmap');
```

### Eventos de Perfil

```dart
// Al actualizar el perfil
analytics.logProfileUpdated();

// Al cambiar el avatar
analytics.logAvatarChanged();
```

### Eventos de Configuración

```dart
// Al cambiar el tema
analytics.logThemeChanged('dark'); // 'light', 'dark', 'system'

// Al cambiar el idioma
analytics.logLanguageChanged('en'); // 'es', 'en'
```

### Eventos de Compartir

```dart
// Al compartir contenido
analytics.logShare('session'); // o 'statistics', 'game'
```

### Propiedades de Usuario

```dart
// Establecer propiedades de usuario personalizadas
analytics.setUserProperty('preferred_hand', 'right');
analytics.setUserProperty('skill_level', 'intermediate');
```

## Ejemplos de Implementación

### Rastrear Clics de Botones

```dart
ElevatedButton(
  onPressed: () async {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    await analytics.logGameCreated(score);
    
    // Continuar con tu lógica
    Navigator.push(...);
  },
  child: Text('Guardar Partida'),
)
```

### Rastrear Navegación de Pantallas

Las vistas de pantalla se rastrean automáticamente vía `FirebaseAnalyticsObserver` en el navigator.

Para rastreo manual:

```dart
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    analytics.logScreenView('my_screen');
  });
}
```

### Rastrear Envíos de Formularios

```dart
void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    final analytics = Provider.of<AnalyticsService>(context, listen: false);
    
    // Registrar el evento
    await analytics.logSessionCreated(selectedType);
    
    // Guardar datos
    await _saveSession();
  }
}
```

## Eventos Personalizados

Para eventos no cubiertos por el servicio:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

final analytics = FirebaseAnalytics.instance;

await analytics.logEvent(
  name: 'custom_event_name',
  parameters: {
    'parameter1': 'value1',
    'parameter2': 123,
  },
);
```

## Parámetros de Eventos

La mayoría de los eventos incluyen parámetros relevantes:

```dart
// Sesión creada
{
  'session_type': 'training' // o 'competition'
}

// Partida creada
{
  'score': 150
}

// Estadísticas vistas
{
  'filter_type': 'all' // o 'training', 'competition'
}

// Gráfico visto
{
  'chart_type': 'histogram' // o 'moving_average', 'heatmap'
}
```

## Ver Datos de Analytics

### Consola de Firebase

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Selecciona tu proyecto
3. Navega a Analytics > Events
4. Ver datos en tiempo real e históricos

### Métricas Clave a Monitorear

- **Usuarios Activos**: Usuarios activos diarios, semanales, mensuales
- **Eventos de Sesión**: Con qué frecuencia los usuarios crean/editan/eliminan sesiones
- **Eventos de Partida**: Frecuencia de creación de partidas y distribución de puntuaciones
- **Vistas de Pantalla**: Pantallas más visitadas
- **Retención**: Retención de usuarios a lo largo del tiempo
- **Propiedades de Usuario**: Distribución de características de usuarios

### Dashboards Personalizados

Crea dashboards personalizados en Firebase Console:
1. Analytics > Custom Dashboards
2. Agrega métricas y eventos relevantes
3. Filtra por propiedades de usuario o rangos de fechas

## Consideraciones de Privacidad

### Recolección de Datos

- Los datos de analytics son anónimos por defecto
- Los IDs de usuario son UIDs de Firebase Auth (no información personal)
- No se registra información personalmente identificable (PII)

### Opt-Out (Mejora Futura)

Considera agregar una opción de opt-out:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
```

### Cumplimiento GDPR

- Informa a los usuarios sobre analytics en la política de privacidad
- Proporciona opción para deshabilitar analytics
- No registres datos sensibles del usuario

## Probar Analytics

### Modo de Depuración

Habilita el modo de depuración de analytics para ver eventos en tiempo real:

#### Android
```bash
adb shell setprop debug.firebase.analytics.app com.example.bolometro
```

#### iOS
En Xcode, agrega `-FIRDebugEnabled` a Arguments Passed On Launch

### DebugView

1. Habilita el modo de depuración
2. Ve a Firebase Console > Analytics > DebugView
3. Ver eventos en tiempo real mientras usas la app

### Verificar Eventos

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

// En desarrollo, imprime eventos
if (kDebugMode) {
  print('Evento de Analytics: session_created');
}

await analytics.logSessionCreated('training');
```

## Mejores Prácticas

1. **Nombres de Eventos**: Usa snake_case para nombres de eventos
2. **Consistencia de Parámetros**: Usa los mismos nombres de parámetros en eventos similares
3. **No Exageres**: Rastrea eventos significativos, no cada toque
4. **Operaciones Asíncronas**: Las llamadas de analytics son async pero no bloqueantes
5. **Manejo de Errores**: Los fallos de analytics no deben bloquear la app
6. **Prueba a Fondo**: Usa DebugView durante el desarrollo

## Referencia de Eventos Comunes

| Nombre de Evento | Cuándo Registrar | Parámetros |
|------------------|------------------|------------|
| `screen_view` | Usuario navega a pantalla | `screen_name`, `screen_class` |
| `session_created` | Nueva sesión creada | `session_type` |
| `game_created` | Nueva partida creada | `score` |
| `login` | Usuario se autentica | `method` |
| `statistics_viewed` | Página de estadísticas abierta | `filter_type` |
| `theme_changed` | Preferencia de tema cambiada | `theme` |
| `language_changed` | Preferencia de idioma cambiada | `language` |
| `share` | Usuario comparte contenido | `content_type` |

## Solución de Problemas

### Eventos No Aparecen

- Verifica que los archivos de configuración de Firebase estén presentes
- Verifica que la app esté conectada a Firebase en Console
- Habilita el modo de depuración para ver eventos en tiempo real
- Espera hasta 24 horas para que aparezcan eventos de producción

### Nombres de Eventos Inválidos

- Deben tener 40 caracteres o menos
- Deben comenzar con letra
- Solo pueden contener letras, números, guiones bajos
- Sensible a mayúsculas/minúsculas

### Demasiados Parámetros

- Máximo 25 parámetros únicos por evento
- Los nombres de parámetros deben tener 40 caracteres o menos
- Los valores de parámetros deben tener 100 caracteres o menos

## Recursos

- [Documentación de Firebase Analytics](https://firebase.google.com/docs/analytics)
- [Paquete Flutter Firebase Analytics](https://pub.dev/packages/firebase_analytics)
- [Mejores Prácticas de Analytics](https://firebase.google.com/docs/analytics/best-practices)
