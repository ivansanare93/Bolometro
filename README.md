# 🎳 Bolómetro

<p align="center">
  <img src="assets/logo_bolometro.png" alt="Bolómetro Logo" width="200"/>
</p>

<p align="center">
  <strong>La aplicación definitiva para jugadores de bolos</strong>
</p>

<p align="center">
  Registra, analiza y mejora tu rendimiento en cada sesión y partida
</p>

---

## 📋 Descripción

**Bolómetro** es una aplicación móvil multiplataforma desarrollada en Flutter que permite a los jugadores de bolos llevar un seguimiento completo de su rendimiento. Diseñada tanto para jugadores aficionados como profesionales, Bolómetro te ayuda a:

- 📊 **Registrar** sesiones de entrenamiento y competición
- 🎯 **Analizar** estadísticas detalladas de tu juego
- 📈 **Visualizar** tu evolución a lo largo del tiempo
- 🏆 **Mejorar** tu técnica con datos objetivos
- 💾 **Guardar** todas tus partidas de forma local y segura
- ☁️ **Sincronizar** tus datos en la nube con tu cuenta de Google

## ✨ Características Principales

### 🎯 Registro de Partidas
- **Marcador completo de bolos** con validación en tiempo real
- Registro rápido de partidas individuales
- Sesiones completas con múltiples partidas
- Soporte para frames especiales (strike, spare, décimo frame)
- Notas y observaciones para cada sesión

### 🏆 Sistema de Gamificación
- **15 Logros Únicos**: Desbloquea logros jugando y mejorando
- **Sistema de Niveles**: Gana XP y sube de nivel con cada logro desbloqueado
- **4 Niveles de Rareza**: Común, Raro, Épico y Legendario
- **Seguimiento de Progreso**: Visualiza tu progreso hacia cada logro
- **Notificaciones de Logros**: Recibe notificaciones al desbloquear logros
- **Insignia de Nivel**: Muestra tu nivel actual en tu perfil
- **Barra de Progreso**: Visualiza tu avance hacia el siguiente nivel

### 👥 Sistema de Amigos y Rankings
- **Gestión de Amistades**: Busca y añade amigos por correo electrónico o código de amigo
- **Solicitudes de Amistad**: Acepta o rechaza solicitudes de amistad
- **Notificaciones Push**: Recibe notificaciones cuando recibes o aceptan solicitudes de amistad
- **Rankings entre Amigos**: Compara tus estadísticas con tus amigos
- **Múltiples Categorías de Ranking**: Rankings por promedio, mejor partida, % de strikes, % de spares y consistencia
- **Clasificación Automática**: Rankings ordenados por la métrica seleccionada
- **Filtros de Periodo**: Compara estadísticas por semana, mes, trimestre o todo el tiempo
- **Visualización de Medallas**: Los 3 primeros lugares destacados con medallas (oro, plata, bronce)
- **Gráficos Comparativos**: Compara tu rendimiento con el de tus amigos mediante gráficos visuales
  - Comparación de estadísticas clave (promedio, mejor partida, strikes%, spares%)
  - Tendencia de puntuaciones a lo largo del tiempo
  - Distribución de strikes/spares/fallos (gráficos de pastel)

### 📊 Estadísticas Avanzadas
- **KPIs dinámicos**: promedio, mejor partida, total de partidas
- **Análisis de rachas**: strikes y spares consecutivos
- **Gráficos visuales**:
  - Histograma de distribución de puntuaciones
  - Gráfico de promedio móvil
  - Diagrama de pastel de strikes/spares
  - Mapa de calor por calendario
- **Top partidas**: ranking de mejores puntuaciones
- Filtros por tipo de sesión y rango de fechas

### 👤 Perfil de Usuario
- Gestión de perfil personal
- Avatar personalizable (desde galería o cámara)
- Información del jugador: club, mano dominante, fecha de nacimiento
- Biografía y notas personales

### 🎨 Personalización
- **Temas**: Modo claro, oscuro o automático según el sistema
- **Idiomas**: Español e Inglés
- Interfaz intuitiva y moderna con Material Design

### 💾 Almacenamiento y Sincronización
- **Almacenamiento local** con Hive (funciona sin internet)
- **Autenticación con Google** para sincronización en la nube
- **Sincronización automática** de datos con Firebase Firestore
- **Cambio de dispositivo** sin perder datos
- Exportación de datos a formato compartible
- Respaldo en la nube con autenticación segura

## 🚀 Tecnologías

- **Framework**: Flutter (latest stable version)
- **Lenguaje**: Dart
- **Base de datos**: Hive (NoSQL local)
- **Gestión de estado**: Provider
- **Gráficos**: FL Chart
- **Backend**: Firebase (Auth, Firestore, Cloud Functions, Cloud Messaging)
- **Iconos**: Font Awesome, Material Design Icons

## 📱 Plataformas Soportadas

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🛠️ Requisitos Previos

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / Xcode (para desarrollo móvil)
- Git

## 📦 Instalación

### 1. Clonar el repositorio
```bash
git clone https://github.com/ivansanare93/Bolometro.git
cd Bolometro
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Generar archivos de Hive
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Ejecutar la aplicación
```bash
# Modo debug
flutter run

# Modo release
flutter run --release
```

### 5. Construir para producción

**Android (APK)**
```bash
flutter build apk --release
```

**Android (App Bundle)**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

**Web**
```bash
flutter build web --release
```

## 🏗️ Arquitectura

### Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/                   # Modelos de datos (Hive)
│   ├── partida.dart         # Modelo de partida individual
│   ├── sesion.dart          # Modelo de sesión (conjunto de partidas)
│   ├── perfil_usuario.dart  # Modelo de perfil de usuario
│   ├── achievement.dart     # Modelo de logros
│   ├── user_progress.dart   # Modelo de progreso del usuario
│   ├── friend.dart          # Modelo de amigo
│   └── friend_request.dart  # Modelo de solicitud de amistad
├── screens/                  # Pantallas principales
│   ├── home.dart            # Pantalla principal con navegación
│   ├── login_screen.dart    # Pantalla de inicio de sesión
│   ├── registro_sesion.dart # Registro rápido de partida
│   ├── registro_completo_sesion.dart # Registro de sesión completa
│   ├── lista_sesiones.dart  # Lista de todas las sesiones
│   ├── ver_sesion.dart      # Detalles de una sesión
│   ├── editar_partida.dart  # Edición de partida
│   ├── estadisticas.dart    # Dashboard de estadísticas
│   ├── perfil_usuario.dart  # Gestión de perfil
│   ├── achievements_screen.dart # Pantalla de logros y niveles
│   ├── friends_screen.dart  # Gestión de amigos
│   └── rankings_screen.dart # Rankings entre amigos
├── services/                # Servicios de backend
│   ├── auth_service.dart    # Autenticación con Google
│   ├── firestore_service.dart # Sincronización con Firestore
│   ├── analytics_service.dart # Analíticas con Firebase
│   ├── achievement_service.dart # Lógica de gamificación
│   └── friends_service.dart # Gestión de amigos
├── repositories/            # Capa de acceso a datos
│   └── data_repository.dart # Abstracción de Hive y Firestore
├── widgets/                 # Componentes reutilizables
│   ├── marcador_bolos.dart  # Marcador de bolos
│   ├── teclado_selector_pins.dart # Teclado para seleccionar pines
│   ├── skeleton_loaders.dart # Skeleton loaders para carga
│   ├── estadisticas/        # Widgets de estadísticas
│   └── ...
├── providers/               # Gestión de estado
│   ├── theme_provider.dart  # Tema de la aplicación
│   └── language_provider.dart # Idioma de la aplicación
├── utils/                   # Utilidades y helpers
│   ├── estadisticas_utils.dart # Cálculos estadísticos
│   ├── estadisticas_cache.dart # Cache de estadísticas
│   ├── registro_tiros_utils.dart # Lógica de registro de tiros
│   ├── database_utils.dart  # Utilidades de base de datos
│   └── app_constants.dart   # Constantes de la aplicación
├── theme/                   # Configuración de temas
│   └── app_theme.dart       # Temas claro y oscuro
└── l10n/                    # Localización
    ├── app_es.arb          # Traducciones en español
    └── app_en.arb          # Traducciones en inglés
```

### Patrón de Diseño

- **Arquitectura**: MVVM (Model-View-ViewModel) con Repository Pattern
- **Gestión de estado**: Provider para temas, idiomas, autenticación y caché
- **Persistencia**: Hive (local) + Firestore (cloud) con sincronización
- **Autenticación**: Firebase Authentication con Google Sign-In
- **Navegación**: Navigator 2.0 con rutas nombradas

### Optimizaciones Implementadas

- ✅ **Lazy Loading**: Carga paginada de sesiones (20 por página)
- ✅ **Cache de Estadísticas**: Cálculos optimizados con invalidación inteligente (expiración de 5 minutos)
- ✅ **Manejo Robusto de Errores**: Try-catch en todos los accesos a base de datos
- ✅ **Pull-to-Refresh**: Actualización manual de datos en todas las listas
- ✅ **Sincronización en la Nube**: Backup automático con Firebase Firestore
- ✅ **Skeleton Loaders**: Indicadores de carga mejorados con efecto shimmer
- ✅ **Batch Writes**: Escrituras por lotes en Firestore para eficiencia
- ✅ **Gamificación Offline**: Sistema de logros funciona sin internet

## 📖 Guía de Uso

### Iniciar Sesión (Primera Vez)

1. Al abrir la app, verás la pantalla de bienvenida
2. **Opción 1**: Toca "Continuar con Google" para iniciar sesión
   - Tus datos se sincronizarán automáticamente en la nube
   - Podrás acceder desde cualquier dispositivo
3. **Opción 2**: Toca "Continuar sin iniciar sesión"
   - Los datos se guardarán solo localmente
   - Podrás iniciar sesión más tarde desde ajustes

### Registrar una Partida Rápida

1. Abre la aplicación
2. En la pantalla principal, toca el botón "+" flotante
3. Ingresa las puntuaciones frame por frame
4. El sistema validará automáticamente strikes, spares y puntuaciones
5. Guarda la partida con ubicación y notas opcionales

### Crear una Sesión Completa

1. Ve a la pestaña "Sesiones"
2. Toca "Nueva Sesión"
3. Selecciona el tipo (Entrenamiento/Competición)
4. Agrega múltiples partidas a la sesión
5. Guarda con notas y detalles

### Ver Estadísticas

1. Ve a la pestaña "Estadísticas"
2. Explora tus KPIs: promedio, mejor partida, rachas
3. Filtra por tipo de sesión o rango de fechas
4. Revisa gráficos de evolución y distribución

### Gestionar Amigos y Rankings

1. **Añadir Amigos**:
   - Ve a la pantalla "Amigos" desde el menú principal
   - Toca el botón "Añadir Amigo"
   - Busca a tu amigo por correo electrónico
   - Envía la solicitud de amistad

2. **Aceptar Solicitudes**:
   - Ve a la pestaña "Solicitudes" en la pantalla de amigos
   - Revisa las solicitudes pendientes
   - Acepta o rechaza según prefieras

3. **Ver Rankings**:
   - Ve a la pantalla "Rankings" desde el menú principal
   - Selecciona la categoría de ranking que deseas ver:
     - Promedio: Ordenado por puntuación promedio
     - % Strikes: Ordenado por porcentaje de strikes
     - % Spares: Ordenado por porcentaje de spares
     - Mejor Partida: Ordenado por la mejor puntuación
     - Consistencia: Ordenado por menor desviación estándar (más consistente)
   - Filtra por periodo (semana, mes, trimestre o todo el tiempo)
   - Visualiza tu posición en el ranking con medallas para los 3 primeros lugares
   - Toca en cualquier amigo o usa el botón de comparar para ver gráficos comparativos detallados

### Ver tus Logros y Nivel

1. **Acceder a Logros**:
   - Ve a la pantalla "Logros" desde el menú principal
   - Visualiza tu nivel actual y XP total
   - Ve tu progreso hacia el siguiente nivel

2. **Desbloquear Logros**:
   - Juega partidas y alcanza hitos específicos
   - Recibe notificaciones cuando desbloqueas logros
   - Gana XP y sube de nivel automáticamente
   - Revisa el progreso de logros bloqueados

3. **Categorías de Logros**:
   - Primeros Pasos: Comienza tu viaje
   - Partidas Jugadas: Alcanza hitos de partidas
   - Strikes: Consigue múltiples strikes
   - Puntuaciones Altas: Alcanza puntuaciones específicas
   - Partida Perfecta: Logra los 300 puntos
   - Rachas: Consigue strikes consecutivos
   - Spares: Acumula spares

### Sincronizar Datos (Usuario Autenticado)

1. Ve a "Ajustes" (icono de engranaje)
2. Verás tu estado de autenticación
3. Toca "Sincronizar datos" para guardar en la nube manualmente
4. La sincronización automática ocurre al guardar sesiones

### Personalizar la App

1. Ve a "Perfil"
2. Configura tu información personal
3. Cambia el tema (claro/oscuro/automático)
4. Selecciona tu idioma preferido (ES/EN)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Para cambios importantes:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Guías de Contribución

Para información detallada sobre cómo contribuir, consulta [CONTRIBUTING.md](CONTRIBUTING.md).

Puntos clave:
- Sigue las convenciones de código de Dart/Flutter
- Ejecuta `flutter analyze` antes de hacer commit
- Añade tests para nuevas funcionalidades
- Actualiza la documentación según sea necesario
- Verifica que los tests pasen con `flutter test`

### Documentación Adicional

El proyecto cuenta con documentación técnica extensa:

**Sistemas Principales**:
- [docs/GAMIFICATION.md](docs/GAMIFICATION.md) - Sistema de logros y niveles
- [docs/FRIENDS_SYSTEM.md](docs/FRIENDS_SYSTEM.md) - Sistema de amigos y rankings
- [docs/ANALYTICS.md](docs/ANALYTICS.md) - Firebase Analytics
- [docs/INTERNATIONALIZATION.md](docs/INTERNATIONALIZATION.md) - Internacionalización

**Implementación Técnica**:
- [docs/OPTIMIZACIONES.md](docs/OPTIMIZACIONES.md) - Optimizaciones de rendimiento
- [docs/AUTENTICACION.md](docs/AUTENTICACION.md) - Configuración de autenticación
- [docs/SINCRONIZACION_IMPLEMENTACION.md](docs/SINCRONIZACION_IMPLEMENTACION.md) - Sincronización en la nube
- [docs/SKELETON_LOADERS.md](docs/SKELETON_LOADERS.md) - Skeleton loaders
- [docs/TESTING.md](docs/TESTING.md) - Guía de testing

**Solución de Problemas**:
- [docs/FIRESTORE_PERMISSION_FIX.md](docs/FIRESTORE_PERMISSION_FIX.md) - Permisos de Firestore
- [docs/FIXES_IMPLEMENTADOS.md](docs/FIXES_IMPLEMENTADOS.md) - Correcciones implementadas

## 🧪 Testing

Bolómetro incluye cobertura de pruebas completa:

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar con cobertura
flutter test --coverage
```

Para información detallada, consulta [docs/TESTING.md](docs/TESTING.md).

### Cobertura de Tests

- ✅ Pruebas unitarias para modelos (Partida, Sesion, PerfilUsuario, Achievement, UserProgress, Friend, FriendRequest)
- ✅ Pruebas unitarias para proveedores (Theme, Language)
- ✅ Pruebas unitarias para servicios (Analytics, Auth, Firestore)
- ✅ Pruebas unitarias para utilidades (Statistics, Cache)
- ✅ Pruebas de widgets para componentes
- ✅ Framework de pruebas de integración

## 🌍 Internacionalización

La aplicación soporta múltiples idiomas:

- 🇪🇸 **Español** (Por defecto)
- 🇬🇧 **Inglés**

El idioma puede cambiarse en la pantalla de Ajustes. Para detalles de implementación, consulta [docs/INTERNATIONALIZATION.md](docs/INTERNATIONALIZATION.md).

## 📊 Analíticas

Firebase Analytics está integrado para rastrear el comportamiento del usuario y mejorar la aplicación. Eventos clave rastreados:

- Creación/edición/eliminación de sesiones y partidas
- Visualización y filtrado de estadísticas
- Autenticación y sincronización de usuarios
- Cambios de tema e idioma
- Desbloqueo de logros y progreso de niveles
- Gestión de amigos y solicitudes
- Visualización de rankings

Para documentación completa de analíticas, consulta [docs/ANALYTICS.md](docs/ANALYTICS.md).

## 🎨 Componentes de UI

### Skeleton Loaders

La aplicación utiliza skeleton loaders para mejorar el rendimiento percibido mientras se cargan los datos:

- Skeletons de tarjetas de sesión
- Skeletons de tarjetas de estadísticas
- Skeletons de gráficos
- Skeletons de elementos de lista

Para la guía de implementación, consulta [docs/SKELETON_LOADERS.md](docs/SKELETON_LOADERS.md).

## 🔄 CI/CD

El pipeline de CI/CD ha sido configurado para compilaciones manuales. Las compilaciones automáticas mediante GitHub Actions han sido eliminadas.

Para instrucciones de compilación local y detalles de configuración de CI/CD, consulta [docs/CICD.md](docs/CICD.md).

## 📝 Historial de Cambios

Para ver el historial completo de cambios y versiones del proyecto, consulta [CHANGELOG.md](CHANGELOG.md).

### Versión Actual: 1.0.2

**Características Principales**:
- ✅ Sistema de gamificación completo (15 logros únicos con sistema de niveles)
- ✅ Sistema de amigos y rankings (búsqueda, solicitudes, comparación de estadísticas)
- ✅ Autenticación con Google Sign-In y sincronización en la nube
- ✅ Internacionalización completa (Español e Inglés)
- ✅ Firebase Analytics integrado para seguimiento de uso
- ✅ Skeleton loaders para mejor experiencia de usuario
- ✅ Testing comprehensivo (modelos, servicios, widgets)
- ✅ Optimizaciones de rendimiento (lazy loading, cache, batch writes)
- ✅ Modo offline completo con sincronización automática

**Documentación Técnica**: 26+ documentos técnicos en el directorio [docs/](docs/)

## 📄 Licencia

Este proyecto es de código cerrado y uso personal. Todos los derechos reservados.

## 👨‍💻 Autor

**Iván Sanare**

- GitHub: [@ivansanare93](https://github.com/ivansanare93)

## 📞 Soporte

Para reportar bugs o solicitar nuevas características, por favor abre un [issue](https://github.com/ivansanare93/Bolometro/issues) en GitHub.

### 🔧 Solución de Problemas Comunes

#### Error de Permisos en Firestore

Si ves el siguiente error:
```
Error al obtener sesiones paginadas desde Firestore: [cloud_firestore/permission-denied]
```

**Solución**: Las reglas de seguridad de Firestore necesitan ser desplegadas a Firebase. Consulta el archivo [`FIRESTORE_PERMISSION_FIX.md`](FIRESTORE_PERMISSION_FIX.md) para instrucciones detalladas paso a paso.

#### Error de Configuración de Google Sign-In

Si ves errores de autenticación con Google, consulta el archivo [`AUTENTICACION.md`](AUTENTICACION.md) para configurar correctamente:
- SHA-1 en Firebase Console
- google-services.json actualizado
- Configuración del applicationId

## 🙏 Agradecimientos

- Comunidad de Flutter por el excelente framework
- Paquetes de código abierto utilizados en este proyecto:
  - Hive para almacenamiento local eficiente
  - FL Chart para visualizaciones de datos
  - Firebase para backend y analíticas
  - Shimmer para skeleton loaders
  - Provider para gestión de estado
- Jugadores de bolos que inspiraron esta aplicación
- Contribuidores y testers que ayudaron a mejorar Bolómetro

## 🚀 Estado del Proyecto

**Versión Actual**: 1.0.2  
**Estado**: ✅ En Producción  
**Última Actualización**: Febrero 2026

**Características Recientes**:
- Sistema de gamificación completo con 15 logros y sistema de niveles
- Sistema social de amigos y rankings comparativos
- **Rankings por categorías adicionales** (Promedio, Strikes%, Spares%, Mejor Partida, Consistencia)
- **Gráficos comparativos entre amigos** (estadísticas, tendencias, distribuciones)
- Mejoras de colores en modo claro para pantalla de logros
- Optimizaciones de rendimiento y cache
- Internacionalización completa (ES/EN)
- Documentación técnica exhaustiva (26+ documentos)
- Sistema de notificaciones push para interacciones sociales

**Próximas Mejoras**:
- Más logros y desafíos especiales
- Análisis avanzados de patrones de juego

---

<p align="center">
  Hecho con ❤️ y Flutter
</p>
