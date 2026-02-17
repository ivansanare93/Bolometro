# Changelog

Todos los cambios notables del proyecto Bolómetro se documentarán en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.3] - 2026-02-16

### Agregado
- **Rankings por Categorías Adicionales**: Ahora puedes clasificar amigos por múltiples métricas
  - Promedio de puntuación
  - Porcentaje de strikes
  - Porcentaje de spares
  - Mejor partida
  - Consistencia (desviación estándar - menor es mejor)
- **Gráficos Comparativos entre Amigos**: Nuevas visualizaciones para comparar rendimiento
  - Gráfico de barras comparativo para estadísticas principales
  - Gráfico de líneas para tendencia de puntuaciones
  - Gráficos de pastel para distribución de strikes/spares/fallos
  - Pantalla dedicada de comparación accesible desde el ranking
- **Estadísticas Extendidas**: Nuevos cálculos en `EstadisticasUtils`
  - Porcentaje de strikes
  - Porcentaje de spares
  - Métrica de consistencia (desviación estándar)
- **Localización**: Nuevas traducciones para las funcionalidades añadidas en español e inglés

### Mejorado
- `FriendsService.obtenerEstadisticasAmigo()` ahora incluye estadísticas extendidas
- `rankings_screen.dart` con selector de categorías y botones de comparación
- Interfaz de rankings con indicadores visuales mejorados para categorías destacadas

### Técnico
- Nuevo widget `comparison_chart.dart` con gráficos comparativos reutilizables
- Nueva pantalla `comparison_screen.dart` para visualización detallada de comparaciones
- Método `calcularEstadisticasExtendidas()` añadido a `EstadisticasUtils`

## [No Publicado]

### Agregado
- Documentación completa de todos los sistemas
- CHANGELOG.md para seguimiento de versiones

### Corregido
- Layout de estadísticas en rankings: los badges ahora se muestran en una línea horizontal con scroll en lugar de dividirse en múltiples líneas
- **Gráfico de tendencia de puntuaciones en pantalla de comparación**: Ahora muestra correctamente los datos de ambos usuarios
  - Corregido bug que mostraba las primeras 20 partidas en lugar de las últimas 20 (más recientes)
  - Implementado método `obtenerPuntuacionesAmigo()` en `FriendsService` para obtener puntuaciones individuales del amigo
  - El gráfico ahora se muestra si al menos un usuario tiene datos (anteriormente requería datos de ambos)

## [1.0.0] - 2026-02-02

### Agregado
- Sistema de gamificación con logros y niveles
- Sistema de amigos y rankings
- Autenticación con Google Sign-In
- Sincronización en la nube con Firebase Firestore
- Internacionalización completa (Español e Inglés)
- Analytics con Firebase Analytics
- CI/CD con GitHub Actions
- Skeleton loaders para mejor UX
- Testing comprehensivo (unit, widget, integration)
- Lazy loading en listas de sesiones
- Cache de estadísticas
- Manejo robusto de errores
- Sistema de perfil de usuario personalizable
- Registro de partidas y sesiones
- Estadísticas avanzadas con gráficos
- Marcador de bolos con validación en tiempo real
- Modo offline completo
- Temas claro y oscuro

### Optimizaciones
- Implementado lazy loading en listas (paginación de 20 items)
- Cache de cálculos estadísticos (expiración 5 minutos)
- Optimización de rendimiento de gráficos
- Reducción de uso de memoria con carga incremental

### Corregido
- Error ApiException: 10 en Google Sign-In
- Navegación al continuar sin iniciar sesión
- Sincronización de sesiones duplicadas
- Permisos de Firestore
- Error de estadísticas con Firebase
- Error de API Phenotype
- Colores en modo claro para pantalla de logros

### Documentación
- README.md completo y profesional
- 21 archivos de documentación técnica
- Guías de instalación y configuración
- Solución de problemas comunes
- Guía de testing
- Guía de contribución

### Seguridad
- Reglas de seguridad de Firestore implementadas
- Validación de entrada de usuario
- Autenticación segura con Firebase Auth
- Datos de usuario protegidos

## [0.1.0] - 2026-01-15

### Agregado
- Versión inicial de Bolómetro
- Funcionalidad básica de registro de partidas
- Almacenamiento local con Hive
- Interfaz de usuario básica

---

[No Publicado]: https://github.com/ivansanare93/Bolometro/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/ivansanare93/Bolometro/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/ivansanare93/Bolometro/releases/tag/v0.1.0
