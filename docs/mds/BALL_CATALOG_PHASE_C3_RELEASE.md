# Fase C3 — catálogo en el flujo normal con activación por compilación

> **Configuración anterior:** por instrucción posterior del usuario el catálogo
> está ahora habilitado por defecto para todas las compilaciones. Consultar
> [BALL_CATALOG_DEFAULT_ENABLED.md](BALL_CATALOG_DEFAULT_ENABLED.md).
> Las afirmaciones de este documento sobre el valor predeterminado desactivado
> y los binarios generados corresponden a la verificación histórica anterior.

Fecha: 28-10-2026. Este diseño sustituye el punto de entrada alternativo de la
primera C3. Por indicación posterior del usuario, **la APK la genera y firma el
usuario**; aquí se preparan el código, pruebas y verificaciones release sin APK.

## Comportamiento final

`lib/main.dart` es el único punto de entrada de la aplicación. Siempre crea
`BallCatalogRepository`; no hay un repositorio de revisión ni una interfaz de
pruebas. La APK privada y una futura pública habilitada usan los mismos modelos,
pantallas, filtros, selección de peso, formulario, IDs personales, almacenamiento
Hive y flujo habitual de respaldo. No hay banners o confirmaciones especiales
para los modelos reales. El demo ficticio preexistente conserva su identificación.

La única activación está en `lib/config/catalog_config.dart`:

```dart
static const commercialEnabled = bool.fromEnvironment(
  'COMMERCIAL_CATALOG_ENABLED',
  defaultValue: false,
);
```

| Compilación | Configuración | Catálogo comercial visible |
| --- | --- | --- |
| Pública actual por defecto | Sin define | Vacío |
| Privada release | `COMMERCIAL_CATALOG_ENABLED=true` | 28 modelos / 134 variantes |
| Pública desactivada explícitamente | `COMMERCIAL_CATALOG_ENABLED=false` | Vacío |
| Futura pública aprobada | Mismo define `true` | Mismo código y comportamiento que la privada |

El flag es de compilación: cambiarlo requiere otra compilación y reiniciar la
app. No es un Remote Config ni un cambio en Firebase. No hay flavors, cambio de
applicationId, segundo Firebase ni dependencias nuevas.

## Datos y almacenamiento

El expediente y `docs/catalog/c2/catalog_real_v2.review.json` se conservan sin
cambios: 3 listos técnicamente, 25 con campos desconocidos, 2 bloqueados excluidos
(IDOL y BVP Sidewinder), 28 modelos, 134 variantes y ninguna fotografía.
RG/diferenciales siguen asociados a su peso. No se completan nulos ni se
confunden resultados indexados de MOTIV con disponibilidad comercial en vivo.

`tool/catalog/generate_commercial_catalog.dart` valida el expediente C2 y genera
`lib/data/commercial_catalog_data.dart`. El archivo generado queda preparado en
el repositorio, sin una copia de JSON comercial en los assets. La rama constante
del cargador solo referencia esos datos cuando el flag está habilitado; la
compilación AOT pública elimina el conjunto real, como se verificó más abajo.
Generar el archivo de datos no activa el flag ni concede derechos de distribución.

El seed público `assets/catalog/catalog_seed.json` continúa vacío. El demo
ficticio está separado. No se modifica `pubspec.yaml` en este cambio.

Con el flag habilitado se usa la caché Hive comercial existente, la misma que
usará una futura versión pública habilitada. **Con el flag deshabilitado no se
lee ni instala una actualización comercial**, aunque haya una versión previa
en caché. No se borra esa caché: habilitar de nuevo permite recuperarla. Se evita
que instalar una versión pública después de la privada deje visibles modelos
comerciales por una caché residual.

Esta decisión afecta solo al catálogo compartido. Las bolas personales creadas
desde él permanecen en el arsenal, con sus IDs, sesiones, estadísticas y
mantenimientos. Desactivar el catálogo no las elimina ni archiva.

## Respaldo: configuración intacta

No se modifica `DataRepository`, ningún servicio de sincronización, las reglas
Firebase ni los adaptadores Hive. No se pasan nuevos valores a
`ARSENAL_BACKUP_ENABLED` o `ARSENAL_BACKUP_TEST_UIDS` en los comandos de abajo.
El valor predeterminado que ya tenía el proyecto para el respaldo sigue siendo
`true`; el flag del catálogo no lo activa, desactiva o redefine.

Guardar una bola desde la APK privada es una operación personal real y puede
sincronizarse con la cuenta conectada según la configuración existente. Para
datos ficticios, utilizar una cuenta ficticia. No se escribe en Firebase ni se
ejecuta la aplicación contra cuentas reales durante estas comprobaciones.

## Riesgo de actualización y conservación de datos

Se conserva **`com.bolometro`** y Firebase **`bolometro-f216b`**. La APK privada
no se instala en paralelo a otra con ese applicationId: si Android la acepta,
actualiza la instalación existente y comparte sus datos y cuentas.

Android exige mismo applicationId, certificado compatible y versionCode igual
o superior al instalado. Una actualización compatible conserva datos; desinstalar
antes elimina los datos locales. Una firma local puede diferir de la firma de
distribución de Google Play, aunque pertenezcan al mismo proyecto. No asumir
que la clave de subida equivale a la clave de firma de Play.
Fuentes: [actualizaciones Android](https://developer.android.google.cn/google/play/app-updates?hl=en),
[instalación mediante adb](https://developer.android.com/tools/adb).

Antes de instalar sobre el móvil habitual:

1. Mantener la instalación actual y comprobar, desde «Mis bolas», que el estado
   indica **«Respaldo confirmado en la última sincronización»**, sin operaciones
   pendientes, errores o conflictos. Confirmar la cuenta correcta. Esto verifica
   el arsenal; no demuestra por sí solo que todos los demás datos de la app
   tengan una copia remota.
2. No asumir respaldo de datos de invitado o cambios solo locales. No hay en
   este alcance una exportación completa de todas las boxes Hive; una exportación
   de partidas no equivale a una copia del arsenal. Si solo existe una copia
   local y no se puede respaldar, preservar esa instalación y probar primero en
   otro dispositivo/perfil Android o emulador, con el mismo código y APK.
3. Usar la firma habitual compatible y revisar la versión instalada. El proyecto
   declara `1.6.0+15`; no se cambia ni se fuerza una bajada de versión. Si necesitas
   `--build-number=N`, elegir un N adecuado y recordar que la siguiente pública
   debe poder actualizarlo. No usar un número desproporcionado sin plan de retorno.
4. Instalar como actualización, sin desinstalar ni «Borrar almacenamiento».
   Mediante adb, `adb install -r ruta.apk` conserva datos si la actualización es
   compatible. No se ejecuta aquí ninguna instalación.
5. Si aparece `UPDATE_INCOMPATIBLE` o `VERSION_DOWNGRADE`, detener la instalación:
   no desinstalar, borrar datos o forzar downgrade para resolverlo. Revisar firma
   y versión o usar otro entorno de instalación. No se puede garantizar que una
   operación incompatible permita recuperar una copia local no respaldada.

El código del catálogo no inicia una migración ni limpia boxes. Después de una
actualización, revisar el arsenal existente y su historial antes de añadir datos
de prueba. Volver a una compilación sin catálogo tampoco borra las nuevas bolas.

## Comandos exactos para generar las APK

Desde la raíz del proyecto, con tu configuración habitual de firma Android ya
disponible. No se crean o sustituyen claves. Si este workspace no tiene
`android/android_key.properties`, necesitarás tu configuración original para
que la configuración release existente de Gradle funcione; esa configuración no
se modifica en este trabajo.

Opcional, solo si cambiaste el JSON revisado y quieres regenerar sus datos:

```powershell
dart run tool/catalog/generate_commercial_catalog.dart
```

**Privada release con catálogo habilitado:**

```powershell
flutter build apk --release --target lib/main.dart --dart-define=COMMERCIAL_CATALOG_ENABLED=true
Copy-Item -LiteralPath build/app/outputs/flutter-apk/app-release.apk -Destination build/app/outputs/flutter-apk/bolometro-catalogo-privado.apk
```

**Pública actual por defecto, sin catálogo real:**

```powershell
flutter build apk --release --target lib/main.dart
Copy-Item -LiteralPath build/app/outputs/flutter-apk/app-release.apk -Destination build/app/outputs/flutter-apk/bolometro-publico-sin-catalogo.apk
```

Cada compilación reutiliza la salida `app-release.apk`; conservar la copia con
nombre claro evita confundirlas. Si esos nombres de copia ya existen, archivar
las anteriores antes de repetir. No publicar la APK privada. Revisar que CI,
scripts o archivos de defines no inyecten `COMMERCIAL_CATALOG_ENABLED=true` en
la compilación pública. También puedes forzar el bloqueo con:

```powershell
flutter build apk --release --target lib/main.dart --dart-define=COMMERCIAL_CATALOG_ENABLED=false
```

Estos comandos usan el mismo `main.dart`. No usar los comandos históricos de
`.dart_tool/catalog_review/main.dart`: se retiraron el generador, el repositorio
alternativo, los avisos especiales y el punto de entrada generado antiguo.

## Pruebas y verificación release realizadas

- **101 pruebas superadas** con configuración pública predeterminada: parser,
  fuentes, todos los pesos, búsqueda/filtros/fichas, manual, entrada normal,
  conservación del historial y bloqueo de caché residual.
- Prueba adicional del constructor normal con
  `--dart-define=COMMERCIAL_CATALOG_ENABLED=true`: **superada**, carga 28/134.
- Comprobación explícita de que ausencia del define significa `false`.
- **Análisis estático sin incidencias** en 11 archivos de la integración.
- La prueba de datos personales crea dos unidades reales del mismo modelo con
  IDs propios en Hive temporal y respaldo simulado; conserva el JSON previo,
  la clave de sesión, mantenimiento y referencias de partidas, promedio 175 y
  mejor partida 200. Nunca utiliza datos reales ni Firebase.
- Se preservan las verificaciones de los 134 pesos y nulos de C2/C3. Se
  mantienen las fuentes y restricciones previas.

Comandos de pruebas:

```powershell
flutter test --no-pub test/catalog_ball_test.dart test/ball_catalog_repository_test.dart test/catalog_flow_test.dart test/catalog_c1_contract_test.dart test/catalog_c2_review_test.dart test/catalog_c3_local_test.dart test/catalog_build_configuration_test.dart
flutter test --no-pub --dart-define=COMMERCIAL_CATALOG_ENABLED=true test/catalog_build_configuration_test.dart
```

Se compilaron además dos **bundles AOT release ARM64 desde `lib/main.dart`**,
sin APK, firma, instalación o despliegue. La inspección de los binarios encuentra
**0 IDs comerciales en el público y los 28 en el privado**, usando el privado
como control positivo. Esto comprueba la exclusión de los datos mediante la
rama constante, además del bloqueo de la interfaz y caché.

Resultado en `build/catalog_release_verification/verification.json`:

| Binario AOT ARM64 | Bytes | IDs comerciales detectados |
| --- | ---: | ---: |
| Público predeterminado | 9.110.432 | 0 |
| Privado habilitado | 9.175.968 | 28 |

Reproducción sin firma ni APK con el SDK local utilizado:

```powershell
flutter assemble --output=build/catalog_release_verification/public --define=TargetFile=lib/main.dart --define=TargetPlatform=android-arm64 --define=BuildMode=release android_aot_bundle_release_android-arm64
$catalogReleaseDefines = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('COMMERCIAL_CATALOG_ENABLED=true'))
flutter assemble --output=build/catalog_release_verification/private --define=TargetFile=lib/main.dart --define=TargetPlatform=android-arm64 --define=BuildMode=release "--define=DartDefines=$catalogReleaseDefines" android_aot_bundle_release_android-arm64
./tool/catalog/verify_release_catalog.ps1
```

La codificación es propia del comando interno `assemble` de este SDK; para
generar APK se usa el `--dart-define` normal mostrado antes. Se probaron ARM64
y el código Dart; **la APK firmada final y su actualización sobre el móvil las
validará el usuario**. No se afirma haber probado aquí su firma, otras ABI o
una instalación Android real.

## Archivos y restricciones pendientes

Se modifica el repositorio normal para aplicar el flag y proteger la lectura
de caché; `lib/main.dart` vuelve a su inicialización única. Las pantallas pierden
el comportamiento especial de revisión y conservan el formulario normal.
Se añaden `lib/config/catalog_config.dart`, el archivo generado en `lib/data/`,
su generador, la prueba del flag y el verificador de binarios. Se adaptan las
pruebas del flujo y caché; se retira el repositorio/generador de entrada alterna.
No se añaden dependencias, ni se cambia el ID Android o el respaldo del arsenal.

El código queda listo para la prueba privada autorizada. **La distribución
pública de los modelos sigue sin aprobarse**: permanecen pendientes las
condiciones de redistribución de datos y el tratamiento de fuentes indexadas,
igual que en los expedientes C1/C2. No hay imágenes autorizadas ni incorporadas.
Activar la privada no cambia `activationApproved` del expediente de publicación.

No se genera APK por petición final del usuario, ni se firma, publica, despliega,
hace commit o push. Bolómetro Vision no se modifica.
