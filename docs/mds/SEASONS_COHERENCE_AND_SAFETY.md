# Temporadas: coherencia y operaciones seguras

Implementación local revisada el 3 de noviembre de 2026. Sin despliegue, cambios de reglas ni acceso a datos reales durante las pruebas.

## Comportamiento

- Registro, edición de sesión y asignación en lote utilizan `SeasonSelector`.
- Se combinan los nombres registrados con los encontrados en las sesiones. Recuperar sesiones en otro dispositivo permite gestionar sus temporadas aunque falten preferencias locales.
- Elegir «Sin temporada» guarda `null`. Se siguen leyendo sesiones antiguas con el texto «Sin temporada», cadenas vacías y valores ausentes.
- Se conserva la sugerencia histórica del año solo mientras nunca se haya guardado una elección predeterminada. Una elección explícita de «Sin temporada» se respeta. Un año archivado no se sugiere.
- Las archivadas no se ofrecen para asignaciones nuevas. Una asignación histórica archivada continúa visible; puede conservarse o sustituirse. Un borrador archivado se conserva y exige elegir otra temporada o restaurarla antes de guardar una sesión nueva.
- Crear desde el selector registra el nombre. Se reutiliza un nombre existente aunque cambien sus mayúsculas; no se fusionan automáticamente nombres antiguos que ya sean distintos.
- Renombrar muestra una confirmación con el número de sesiones, actualiza sus asignaciones y conserva el estado archivado y la selección predeterminada cuando procede.
- Retirar una temporada permite archivar o reasignar sus sesiones a otra temporada o a «Sin temporada». Se solicita confirmación antes de aplicar la reasignación. Nunca se elimina una sesión como parte de esta operación.
- Si cambian las sesiones afectadas después de cargar la pantalla, la operación se rechaza para volver a revisar la selección.
- En una cuenta, renombrar o retirar una temporada requiere leer la lista completa desde el servidor (`Source.server`). Si no se puede confirmar, se rechaza antes de modificar datos: una caché parcial no se interpreta como todas las sesiones. Las asignaciones individuales o de un lote explícitamente seleccionado sí pueden quedar pendientes sin conexión.

## Persistencia y red

`SeasonAssignmentStore` conserva un diario de escritura en Hive, `season_assignments_<UID>` (o `season_assignments_guest`). No requiere adaptadores nuevos ni modifica los existentes.

Cada entrada contiene la sesión previa, el nombre esperado, el destino y el estado local/remoto. Se registra antes de cambiar la sesión. Al reabrir, se puede completar una escritura local interrumpida. No se alteran claves existentes de Hive, fechas identificadoras, partidas, referencias a bolas, puntuaciones, notas ni datos de pines.

La subida usa una transacción de Firestore que modifica exclusivamente `temporada` en `users/<UID>/sesiones/<fechaEnMilisegundos>`:

1. Si el destino ya está aplicado, se confirma sin repetir cambios.
2. Si el nombre anterior coincide, se cambia solo ese campo.
3. Si ha cambiado, se conserva el conflicto y no se sobrescribe.
4. Si falta la sesión remota, la operación queda pendiente. «Respaldar sesión ausente» solicita aprobación explícita para crearla con sus partidas. La transacción comprueba otra vez que no exista; nunca reemplaza un documento aparecido entretanto.

Un fallo de red conserva la entrada. La pantalla de temporadas muestra el número pendiente y un botón «Reintentar». Un conflicto ofrece «Revisar conflicto»: muestra fecha y temporadas del dispositivo y de la cuenta y requiere elegir. La elección se vuelve a validar; un cambio remoto posterior obliga a revisarla de nuevo.

Las listas muestran el destino local pendiente sobre la respuesta remota, sin reemplazar otros campos obtenidos del servidor. El cierre de sesión no borra el diario y otra cuenta no lo utiliza.

Mientras una sesión tenga una asignación pendiente se bloquean su edición completa y su eliminación. Las sincronizaciones completas se bloquean mientras existan asignaciones pendientes, para evitar que una escritura de sesión completa evite la comprobación de conflictos. Resolver o confirmar los pendientes habilita de nuevo esas operaciones.

No se cambia el respaldo del arsenal, sus flags ni sus reglas. Las escrituras utilizan las rutas y permisos de sesiones existentes; no se ha desplegado nada.

## Archivos

- Nuevos: `lib/services/season_assignment_store.dart`, `lib/services/season_management_service.dart`, `lib/widgets/season_selector.dart`.
- Modificados: `temporada_service.dart`, `data_repository.dart`, `firestore_service.dart`, `temporadas_screen.dart`, `registro_completo_sesion.dart`, `ver_sesion.dart`, `lista_sesiones.dart` y traducciones ES/EN generadas.
- Pruebas nuevas: `test/season_safety_test.dart`, `test/season_ui_test.dart`.

## Validación local

```powershell
flutter test --no-pub test/season_safety_test.dart test/season_ui_test.dart test/temporada_service_test.dart test/sesion_model_test.dart test/utils/stats_filter_test.dart test/estadisticas_utils_test.dart test/game_keyboard_controls_test.dart test/arsenal_preservation_test.dart
```

Las pruebas utilizan directorios temporales exclusivos, preferencias simuladas y dobles de Firestore. Verifican recuperación al reabrir Hive, reintentos, confirmaciones perdidas, conflictos, creación remota ausente bajo aprobación, conservación de claves y partidas, aislamiento del diario, cierre de sesión, selectores, borradores y cancelación. No certifican conectividad ni reglas desplegadas de un Firebase real.

Resultado final: **141 pruebas superadas**, incluidas 31 nuevas de seguridad e interfaz de temporadas. El análisis estático de los seis módulos/archivos de prueba específicos no encuentra incidencias. El análisis de las pantallas y servicios compartidos mantiene avisos anteriores por APIs obsoletas y un cast innecesario en actividad diaria; no detecta errores de compilación. El formateador también informa de que no puede resolver el include de `flutter_lints` en este entorno; no se han instalado paquetes para cambiarlo.

## Comprobación manual en la APK

1. Con una cuenta ficticia, crear «Liga prueba», elegirla para nuevas sesiones y registrar una sesión de prueba.
2. Elegir después «Sin temporada» como predeterminada y comprobar un registro nuevo sin borrador previo. Un borrador existente mantiene su selección.
3. Renombrar «Liga prueba». Revisar el número indicado, cancelar una vez y confirmar después. Comprobar sesión, estadísticas y bola asociada.
4. Archivar. Verificar que se puede consultar, que no se ofrece para asignar y que renombrarla archivada conserva ese estado. Restaurar cuando se quiera usar otra vez.
5. Retirar una temporada de prueba: cancelar primero y luego reasignar a otra o a «Sin temporada». Comprobar que siguen presentes todas las sesiones y partidas.
6. Desconectar la red y reasignar una sesión ya respaldada. Confirmar el aviso de pendiente, cerrar y reabrir la aplicación. Reconectar y pulsar «Reintentar» en Temporadas hasta confirmar la subida.
7. Para un conflicto controlado, mantener una sesión de prueba cargada en un dispositivo y cambiar su temporada desde otro. Reasignar desde la copia anterior y revisar las dos opciones. No usar documentos reales para esta comprobación.
8. Cerrar sesión con un pendiente de prueba. Otra cuenta no debe mostrarlo; al regresar a la primera debe poder recuperarse.

## Límites y siguiente fase

- La lista de nombres, el archivo y la selección predeterminada siguen en las preferencias globales históricas del dispositivo. Su aislamiento y respaldo por cuenta requieren una fase propia y una importación explícita; este trabajo no los migra.
- El diario protege las asignaciones de sesiones, no convierte varias escrituras de SharedPreferences y Firestore en una transacción distribuida. Si falla la actualización de nombres después de modificar sesiones, sus nombres se siguen descubriendo desde estas y se muestra error para revisión; no se deshacen cambios remotos automáticamente.
- Una sesión borrada remotamente no se recrea por un reintento ordinario: requiere aprobar «Respaldar sesión ausente».
- Los cambios en otros campos de sesión siguen usando la arquitectura existente. No se ha implementado un sistema general de revisiones de sesiones ni se garantiza el comportamiento de una versión antigua que desconozca este diario.
- Fechas, identificadores estables de temporada, nuevas tarjetas y comparativas quedan pendientes.
- Queda por ejecutar la comprobación manual con Firebase y una cuenta ficticia. No se generó ni publicó una APK en esta fase.

## Integración en el repositorio PRO

Las mejoras se han integrado y validado también en el repositorio indicado por el usuario como destino exclusivo de los cambios de Flutter:

```text
C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro
```

Los siete archivos existentes afectados coincidían con la base de la implementación; no hubo conflictos. Se añadieron los módulos y pruebas nuevos, se combinaron las traducciones sin reemplazar entradas previas y se regeneraron las localizaciones.

Validación ejecutada desde PRO: **141 pruebas superadas**; análisis estático de los seis archivos específicos sin incidencias; 186 archivos protegidos comprobados por SHA-256 sin cambios inesperados. Se conservaron los cambios previos del catálogo, fotografías y arsenal, así como la configuración del proyecto.

Copia previa del código y manifiesto de verificación:

```text
build/season_transfer_f536c98bb1/original/
build/season_transfer_f536c98bb1/manifest.json
```

Esta copia respalda archivos de código; no contiene una copia de los datos del móvil. No se ha generado ni instalado una APK, accedido a Firebase real, realizado commits, push o despliegues durante este traslado.
