> Actualización 2026-11-04: catálogo pausado por solicitud del usuario.
> `COMMERCIAL_CATALOG_ENABLED` ahora tiene `defaultValue: false`.
> La compilación normal abre directamente el formulario manual desde + y oculta
> el enlace de modelos para fotografías. No se borran el catálogo, la caché ni
> las bolas personales. El contenido restante de este documento es histórico.
>
> Compilar: `flutter build apk --release` (sin define `true`).
> Un define explícito `COMMERCIAL_CATALOG_ENABLED=true` permite reactivarlo;
> eliminarlo de configuraciones locales mientras esté pausado.

# Catálogo habilitado por defecto

Por instrucción del usuario el 28-10-2026, `COMMERCIAL_CATALOG_ENABLED` tiene
`defaultValue: true`. La app normal carga los 28 modelos y 134 variantes usando
`lib/main.dart`, el repositorio y las pantallas habituales. Ya no hace falta
añadir un `--dart-define` para mostrar el catálogo.

```powershell
flutter build apk --release --target lib/main.dart
```

Esto se aplica a las nuevas compilaciones que se instalen. No cambia por remoto
las versiones ya instaladas, no genera una APK y no publica en Google Play.
El usuario continúa generando y firmando su APK con su configuración habitual.

Se conserva una desactivación explícita de emergencia:

```powershell
flutter build apk --release --target lib/main.dart --dart-define=COMMERCIAL_CATALOG_ENABLED=false
```

Con ese valor se ignora la caché comercial sin borrarla y se mantiene disponible
la entrada manual. Las bolas personales guardadas permanecen en el arsenal.
Para el comportamiento normal, eliminar cualquier define antiguo `false` de
scripts, CI o configuraciones de ejecución. Un define explícito tiene prioridad
sobre el nuevo valor predeterminado.

No se modifican los flags de respaldo, Firebase, adaptadores Hive, IDs personales,
partidas, estadísticas ni mantenimientos. IDOL y BVP Sidewinder siguen excluidos;
se conservan los datos desconocidos, las fuentes y la ausencia de fotografías.

La autorización para habilitar el código no equivale a una licencia de los
fabricantes: las restricciones de fuentes y redistribución documentadas en
C1/C2 siguen pendientes. No se cambian los expedientes históricos ni se marca
automáticamente como verificado un permiso externo.

Antes de actualizar el móvil, confirmar el respaldo, comprobar firma y versión
compatibles e instalar como actualización sin desinstalar ni borrar datos.

Validación reproducible:

```powershell
flutter test --no-pub test/catalog_ball_test.dart test/ball_catalog_repository_test.dart test/catalog_flow_test.dart test/catalog_c1_contract_test.dart test/catalog_c2_review_test.dart test/catalog_c3_local_test.dart test/catalog_build_configuration_test.dart
flutter test --no-pub --dart-define=COMMERCIAL_CATALOG_ENABLED=false test/catalog_build_configuration_test.dart
```

Los binarios AOT y resultados de C3 anteriores al cambio son históricos: el
binario llamado público en aquella prueba se compiló con el antiguo valor
predeterminado `false`. Para comparar binarios ahora, compilar el control con
`COMMERCIAL_CATALOG_ENABLED=false` explícito; una compilación normal habilita
el catálogo. No se certifica aquí una APK firmada ni una instalación Android.

Resultados tras el cambio: **101 pruebas superadas**, prueba adicional con
desactivación explícita superada y análisis estático sin incidencias en los
cuatro archivos afectados. No se genera ni publica una APK.
