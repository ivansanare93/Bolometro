# Integración en el workspace PRO

Fecha: 28-10-2026. Integración autorizada por el usuario, realizada sin commits,
push, despliegues ni publicación o instalación de APK.

## Carpetas y causa del problema

Los cambios se estaban preparando en:

```text
C:\Users\ivans\App_Bolometro\Bolometro
```

La app que probaba el usuario se compilaba desde:

```text
C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro
```

El PRO partía del commit `cf4e38b`; el otro workspace incorporaba también
`75e9b5f` y los cambios locales posteriores del catálogo y conflictos. El PRO
abría directamente el formulario manual y su respaldo quedaba desactivado sin
un define explícito. Esa diferencia explica las dos capturas comunicadas.

## Integración realizada

Se integraron 42 archivos nuevos/modificados y se añadió este informe. Se
copiaron solo diferencias de contenido relacionadas con catálogo, respaldo
predeterminado, corrección de conflictos, pruebas y documentación. No se
sustituyó el proyecto completo ni se cambiaron ramas, commits o claves.

El único cambio local previo del PRO era `version: 1.7.0+16`. Se conservó esa
versión y en su `pubspec.yaml` solo se añadieron los dos assets de catálogo
existentes en la implementación. Las dependencias y `pubspec.lock` no cambian.

Quedan disponibles en el PRO:

- `lib/main.dart` como entrada normal, sin variantes de desarrollo.
- Catálogo habilitado por defecto: 28 modelos y 134 variantes, campos
  desconocidos conservados, sin IDOL, BVP Sidewinder o fotografías.
- «Mis bolas → + → Buscar en catálogo / Añadir manualmente».
- Respaldo habilitado por defecto, conservando la posibilidad de desactivación
  explícita o restricción de cuentas ya contemplada por el código revisado.
- Revisión de conflictos que recupera y conserva ambas versiones antes de
  ofrecer «Usar cuenta» o «Usar dispositivo».

No se modifican adaptadores Hive, modelos personales, IDs, sesiones,
estadísticas o mantenimientos. La integración de código no toca los datos
guardados en el móvil ni los datos de Firebase.

## Copia de seguridad y archivos protegidos

Copia previa de cada archivo existente afectado y manifiesto de integración:

```text
C:\Users\ivans\App_Bolometro\Bolometro\build\workspace_sync\pro_20261028_124825
```

`original/` contiene las versiones previas de los archivos reemplazados,
incluido el `pubspec.yaml` del PRO con 1.7.0+16. `manifest.json` registra archivos
creados/modificados y hashes para revisión. **Esta copia es del código, no es
una copia de seguridad de los datos personales del teléfono.**

Se verificaron 30 archivos protegidos por hash: configuración Android y de
firma existente, configuración Firebase, reglas, lockfile, autenticación y
modelos/adaptadores personales. No se copiaron contraseñas o claves privadas
al otro workspace ni al informe. No se modificó ningún archivo de Android.

La diferencia entre los dos `firestore.rules` afecta a validaciones de
notificaciones, no a la ruta del arsenal. Se conserva intacto el archivo del
PRO. También se conserva su test JavaScript de reglas: no se trasladaron las
pruebas adicionales de notificaciones que requieren la otra variante de reglas.
No se desplegó ni se consultó el estado de las reglas de producción durante
esta integración. Cualquier conciliación futura de esa diferencia es separada.

## Validación desde el PRO

**145 pruebas superadas, cero fallos**, ejecutadas con el directorio de trabajo
del PRO. Incluyen conservación de datos, aislamiento por cuenta, conflictos,
errores de red, búsqueda/filtros, interfaz de catálogo y sus 134 pesos, y
validación del catálogo habilitado por defecto.

**Análisis estático sin incidencias** en los 18 archivos de aplicación,
herramientas y pruebas revisados. Se usaron las dependencias ya existentes;
no se instalaron paquetes nuevos. Hive temporal y servicios de respaldo
simulados: no se inicializa Firebase ni se utilizan datos reales en esas pruebas.

Comando de pruebas:

```powershell
cd C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro
flutter test --no-pub test/arsenal_preservation_test.dart test/arsenal_conflict_screen_test.dart test/mis_bolas_screen_test.dart test/catalog_ball_test.dart test/ball_catalog_repository_test.dart test/catalog_flow_test.dart test/catalog_c1_contract_test.dart test/catalog_c2_review_test.dart test/catalog_c3_local_test.dart test/catalog_build_configuration_test.dart
```

No se ejecutó el emulador de seguridad de Firestore en esta integración: sus
reglas y test JavaScript del PRO permanecen sin cambios.

## Generar y probar tu APK

Detener cualquier ejecución anterior de Flutter y, desde el PRO:

```powershell
cd C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro
flutter build apk --release
```

Salida esperada:

```text
C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro\build\app\outputs\flutter-apk\app-release.apk
```

Se mantienen la firma existente del PRO y `com.bolometro`. Instalar como
actualización compatible sin desinstalar ni borrar datos. No se ha generado o
firmado la APK desde esta sesión: el usuario indicó que lo hará él.

Para ejecutar directamente la app actualizada desde el IDE/terminal:

```powershell
flutter run
```

Ese comando instala una compilación debug, también con catálogo y respaldo
predeterminados habilitados. No equivale a ejecutar la APK release recién
generada. Si hay rechazo por firma, no desinstalar para resolverlo: usar la
actualización release compatible o un entorno de pruebas.

Al abrir «Mis bolas», pulsar «+» debe mostrar las dos opciones. Si un conflicto
está pendiente, «Revisar…» recupera las versiones antes de elegir. Si continúa
apareciendo respaldo desactivado, comprobar que no se estén inyectando
`ARSENAL_BACKUP_ENABLED=false` o una lista `ARSENAL_BACKUP_TEST_UIDS` restrictiva;
una lista definida pero vacía bloquea todas las cuentas.

Las restricciones de fuentes y redistribución de los datos del catálogo siguen
documentadas en C1/C2. Esta integración no concede permisos de terceros ni
publica la app. Bolómetro Vision no se modifica.
