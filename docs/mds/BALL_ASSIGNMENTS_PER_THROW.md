# Bolas por tiro e intervalos de frames

Fecha: 2026-11-19. Repositorio: `C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro`.

## Uso en la aplicación

En registrar o editar partida:

1. Elegir Bola predeterminada (la asignación de partida existente).
2. Abrir Bolas por tiro. Se puede editar un tiro individual o elegir un rango
   inclusivo Desde el frame / Hasta el frame y Todos los tiros, Tiro 1,
   Tiro 2 o Tiro 3. El tercer tiro solo se aplica al frame 10.
3. Pulsar Asignar bola al intervalo y elegir la bola. La selección es local
   hasta pulsar Guardar asignaciones; Cancelar no altera el formulario.
4. Guardar partida y, si se está creando una sesión, Guardar sesión.
   Guardar asignaciones no sustituye esos dos pasos de guardado.

Ejemplo solicitado: bola A predeterminada; intervalo de frames 5 a 10,
Todos los tiros, bola B. Los frames 1–4 heredan A. También se puede aplicar
B solo a segundos tiros para usar otra bola en los remates. Un intervalo
puede configurar tiros futuros: las estadísticas solo cuentan los que
realmente tienen un valor registrado en el marcador.

Cambiar la predeterminada no elimina excepciones. Restablecer a la bola
predeterminada elimina las excepciones del borrador del editor; requiere
Guardar asignaciones para aceptarlo. Sin especificar es una elección
explícita distinta de cancelar. Una bola archivada ya referenciada sigue
siendo elegible para corregir ese historial; una referencia sin metadatos
conserva su ID. El selector es desplazable y mantiene cancelación por
atrás, barrera y arrastre.

## Persistencia y compatibilidad

`Partida` conserva `ballId` como bola predeterminada. Se añade el campo Hive
opcional 7 `ballIdsByThrow`, mapa de claves frame:tiro con índices desde cero:
`4:0` significa frame 5, primer tiro; `9:2`, tercer tiro del frame 10.
Un valor null significa Sin especificar; una clave ausente hereda ballId.

- El typeId sigue siendo 0 y los campos 0–6 conservan su significado.
- El mapa es inmutable, admite copias y valida posiciones/tipos. Una
  estructura inválida provoca error, no una eliminación silenciosa.
- JSON solo añade `ballIdsByThrow` si no está vacío. Las partidas antiguas
  mantienen su forma JSON y se leen con mapa vacío.
- El adaptador de Partida se regeneró con el generador existente. Los otros
  ocho adaptadores se comprobaron byte a byte y permanecen iguales.
- Sesion.toJson/fromJson, copias de sesión/partida y almacenamiento Hive
  preservan las excepciones. No se cambian IDs de bolas, claves Hive,
  fechas identificadoras de sesión, notas, pines ni mantenimientos.
- Las reglas actuales de sesiones no restringen esta propiedad anidada;
  no se modifican ni despliegan reglas ni se crean colecciones. La ruta de
  guardado existente usa la serialización de sesión, ahora con el nuevo mapa.
  Solo se probó transporte JSON/local y dobles; falta prueba controlada en
  Firebase desde un dispositivo, no se certifica servidor actualizado.

### Precaución de actualización

**Actualizar todos los dispositivos que editen estas partidas antes de
utilizar asignaciones múltiples.** Una versión anterior puede leer la
puntuación y la bola predeterminada, pero ignora el campo nuevo, muestra
una asignación incompleta y puede perder las excepciones al guardar o
resincronizar la sesión. Se ha reproducido la lectura con un adaptador
antiguo en ficheros temporales. No se ha desplegado un bloqueo de versiones
antiguas; hacerlo requeriría una decisión adicional.

Antes de instalar, guardar las sesiones/borradores en curso. Los borradores
nuevos de partida y sesión se separan por UID, con un espacio distinto para
invitado. Los borradores antiguos sin propietario no se vinculan
automáticamente a una cuenta: sus claves originales se conservan en el
espacio local antiguo/invitado. No se elimina ni reclama esa copia.
Los borradores son locales, no se garantiza recuperarlos tras reinstalar.

## Atribución de estadísticas

No se divide ni duplica la puntuación final entre bolas: los bonus de strike
/spare pueden depender de lanzamientos realizados con otra bola.

- Participación: una partida puede contar como usada por varias bolas. No se
  deben sumar esas participaciones para obtener el número global de partidas.
- Tiros/frames con uso y pines derribados: se atribuyen según la asignación
  efectiva de cada tiro registrado. Un frame puede tener uso de dos bolas.
  Los pines son cantidades físicas derivadas de los símbolos del marcador,
  no puntos con bonus; no se inventan identidades de pines ni selecciones
  visuales.
- Strikes: conversiones sobre tiros que empiezan con un rack nuevo, incluidos
  bonus aplicables del frame 10. Un segundo tiro después de un cero no es
  inicio de rack nuevo, aunque sigan en pie diez pines.
- Spares: oportunidades de remate y conversiones de esa bola. Si A deja
  dos pines y B los remata, el spare pertenece a B, no a A.
- Promedio/mejor partida/desviación de puntuación por bola: solo partidas
  cuya asignación registrada es exclusivamente esa bola, sin tiros
  desconocidos. Si no existen, se muestra ausencia de datos, no cero.
- La tendencia del detalle de bola usa los últimos cinco registros
  exclusivos frente a los cinco anteriores; requiere diez. El histórico
  por bola usa la cronología compartida, con fecha de sesión como fallback.
- Las asignaciones no realizadas (segundo tiro de un strike, bonus que no
  procede o posiciones todavía vacías) no generan participaciones ni tiros.
- El filtro por bola incluye partidas en que se utilizó esa bola, aunque
  fueran compartidas. Los resultados generales siguen describiendo esas
  partidas completas y una nota lo aclara. El desglose por bola atribuye
  sus tiros y calcula puntuaciones solo con registros exclusivos.
- Sin bola especificada incluye partidas con algún tiro desconocido, no
  solo partidas completamente sin asignación. Se indica en la pantalla.
- Los porcentajes por bola incluyen todos sus tiros aplicables, también
  los numéricos y los bonus. No son el mismo denominador que el porcentaje
  global por frames ni que el análisis limitado a datos visuales de pines.

No se introduce una validación nueva de completitud del historial importado:
los totales guardados siguen siendo la fuente para las puntuaciones.
`BallStatsService.calcular(..., ballId: id)` es la ruta para atribución
precisa. Se conserva la llamada antigua sin ID para compatibilidad de su
contrato; las pantallas reales pasan el ID personal.

## Protección de cuentas y respaldo

Las pantallas de partida/sesión ocultan el formulario al cambiar de cuenta;
no permiten guardar IDs de otra cuenta. Selector y editor comprueban UID y
generación tras sus operaciones asíncronas. Los borradores permanecen en el
espacio de su propietario. La importación de invitado comprueba todas las
referencias, incluidas excepciones, antes de vincular una sesión; la migración
automática no mueve sesiones con referencias por tiro. Una importación
explícita conserva fuente, IDs y excepciones y no se repite en otra cuenta.

No se modifica el motor del respaldo del arsenal, sus revisiones/conflictos,
reglas, flags, Firebase, applicationId ni dependencias. Solo se amplían los
chequeos de referencias del repositorio y su lectura de historial por bola.

## Archivos principales

- `lib/models/partida.dart` y `partida.g.dart`.
- `lib/utils/ball_throw_usage.dart` (nuevo): contadores de tiros reales.
- `lib/widgets/game_ball_assignments.dart` (nuevo) y selector existente.
- Pantallas de registrar/editar partida, registrar sesión, detalle de bola
  y estadísticas; panel de análisis de estadísticas.
- `lib/services/draft_service.dart`, `ball_stats_service.dart`.
- `lib/repositories/data_repository.dart`, `lib/utils/stats_selection.dart`
  y `statistics_metrics.dart`.
- ARB ES/EN y localización generada.
- Tests nuevos `ball_throw_usage_test.dart` y `game_ball_assignments_test.dart`;
  casos adicionales de preservación del arsenal y filtro de estadísticas.

También se corrigió el relleno con valores vacíos de frames cortos al editar;
el anterior cambio de longitud introducía null en listas de String y fallaba
al abrir determinadas partidas válidas con strikes.

## Validación y comandos

```powershell
flutter test --no-pub test/ball_throw_usage_test.dart test/game_ball_assignments_test.dart test/partida_model_test.dart test/sesion_model_test.dart test/seleccionar_bola_field_test.dart test/data_repository_ball_test.dart test/arsenal_preservation_test.dart test/ball_stats_service_test.dart test/statistics_metrics_test.dart test/statistics_analysis_ui_test.dart test/statistics_presentation_test.dart test/statistics_reliability_test.dart test/estadisticas_cache_test.dart test/estadisticas_utils_test.dart test/utils/stats_filter_test.dart test/season_ui_test.dart test/game_entry_viewport_test.dart test/game_keyboard_controls_test.dart
flutter build apk --release
```

**Resultado: 225 pruebas superadas** en la selección conjunta anterior.

Los tests usan directorios temporales, cuentas ficticias y dobles de red.
Cubren lecturas Hive antiguas/nuevas, JSON y copias, asignaciones nulas,
intervalos, cancelar, cuentas, bonus del décimo, cero seguido de spare,
estadísticas de partidas compartidas, borradores, importación explícita,
reapertura local y regresiones de teclado/foco. Texto ampliado probado en
360 x 740. Resultados en `build/ball_throw_regression.log`.

Análisis sin errores de Dart; queda un aviso de operador nulo redundante en
el adaptador generado por Hive y avisos informativos de APIs obsoletas/estilo.
El generador antiguo también advierte de diferencia de versión del analyzer.
No se actualizan paquetes ni se ocultan esos avisos. No se genera una APK,
no se prueban datos reales y no se cambia nada en Bolómetro Vision.

No se realizan commits, push, despliegues ni publicaciones. Instalar la APK
como actualización compatible de firma, sin desinstalar ni borrar datos,
y probar primero con una sesión ficticia.
