# C4 — Resultados de verificación local

Fecha: 2026-10-28. Workspace PRO. No APK generada, acceso a Firebase, datos reales, descargas comerciales ni dependencias nuevas.

## Resultado

- **184 pruebas superadas en la batería final completa**. Incluye regresiones para índices manipulados y para conservar la foto personal guardada si la nueva selección resulta ilegible.
- **21 pruebas nuevas C4**: 19 de medios/registro/caché/aislamiento y 2 del flujo normal de formulario.
- **Análisis estático de 14 archivos: sin incidencias**.
- **15 archivos protegidos idénticos por SHA-256** a la instantánea anterior a C4: reglas, pubspec/lock, modelos/adaptadores personales, repositorio de datos, servicios del respaldo y datasets C2. No se han cambiado flags.
- Generador offline: **0 imágenes comerciales aprobadas**, ningún archivo de imagen descargado.
- Investigación: 28 modelos, 20 candidatas pendientes, 8 todavía no utilizables. Catálogo técnico: 28 modelos / 134 variantes sin cambios, todas con `photo: null`.

## Comandos ejecutados

```powershell
flutter test --no-pub test/ball_media_test.dart test/catalog_flow_test.dart test/catalog_c3_local_test.dart test/catalog_ball_test.dart test/catalog_c2_review_test.dart test/catalog_c1_contract_test.dart test/catalog_build_configuration_test.dart test/ball_catalog_repository_test.dart test/bowling_ball_model_test.dart test/data_repository_ball_test.dart test/ball_stats_service_test.dart test/arsenal_preservation_test.dart test/arsenal_conflict_screen_test.dart test/mis_bolas_screen_test.dart --reporter expanded

flutter test --no-pub test/ball_media_test.dart test/catalog_flow_test.dart --reporter expanded
flutter test --no-pub test/ball_media_test.dart --reporter expanded

flutter analyze --no-pub lib/repositories/ball_media_repository.dart lib/services/ball_image_service.dart lib/widgets/ball_photo.dart lib/widgets/catalog_ball_image.dart lib/data/authorized_catalog_photos.dart lib/screens/editar_bola_screen.dart lib/screens/mis_bolas_screen.dart lib/screens/ball_catalog_screen.dart lib/screens/catalog_ball_detail_screen.dart lib/main.dart test/ball_media_test.dart test/catalog_flow_test.dart test/catalog_c3_local_test.dart tool/catalog/generate_authorized_photos.dart

dart run tool/catalog/generate_authorized_photos.dart
```

Evidencia final en `build/c4_tests_final.log` (184 pruebas) y `build/c4_analyze_final.log` (14 archivos sin incidencias). Los logs `build/c4_tests_last_changes.log` (27) y `build/c4_media_final.log` (18) corresponden a verificaciones intermedias anteriores a la última regresión de prioridad personal. La batería final se ejecutó tras cerrar esas correcciones.

El formateador `dart format` mostró un aviso de resolución de `flutter_lints/flutter.yaml` en este entorno. No se instalaron paquetes para remediarlo; `flutter analyze --no-pub` terminó correctamente y sin diagnósticos. Los mensajes de errores de red simulados dentro de los tests de arsenal son escenarios esperados, no acceso al servidor.

## Alcance de las pruebas

- Persistencia real de fotos y metadatos en directorios temporales, prioridad personal, aislamiento cuenta/invitado, conservación ante sustitución fallida e índices dañados/manipulados.
- Caché permitida reutilizable sin red, revocación, límites de archivos, rechazo de permisos incompletos y registro vacío. Red sustituida por un downloader sintético: no se prueba disponibilidad real de los CDN ni se permite descargar fotos pendientes.
- UI: carga/error/genérica con proporciones conservadas; cambio de cuenta sin mostrar datos del Future anterior; vinculación desde el formulario normal sin cambiar la foto personal/ID/mantenimientos; fallo de disco después del guardado sin duplicar la bola.
- Regresiones: 28 fichas, 134 pesos, campos desconocidos, búsqueda/filtros, entrada manual, varias unidades, IDs previos, estadísticas/mantenimientos, cierre de sesión, errores de red y conflictos del arsenal con almacenes de prueba.
- No se ha cambiado ni desplegado ninguna regla. No se ha repetido un ensayo contra Firebase de producción ni se ha afirmado que las reglas publicadas estén comprobadas en esta fase.

## Pendientes manuales

Selector de galería y permisos Android reales, apariencia en móvil, actualización con firma original, lectura tras reinicio y permisos de las fotografías. En iOS no se ha localizado `NSPhotoLibraryUsageDescription` en el Info.plist actual; no se ha modificado iOS y será necesario revisar su configuración antes de validar el selector en esa plataforma. C4 se prepara para la prueba Android solicitada.

No hay prueba privada con fotos comerciales pendientes: primero deben existir permiso verificable, revisión visual y aprobación expresa del propietario de Bolómetro para su incorporación. Ver [informe C4](../../mds/BALL_CATALOG_PHASE_C4_PHOTOS.md).
