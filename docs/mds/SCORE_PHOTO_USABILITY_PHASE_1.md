# Lectura del marcador: fase 1 de facilidad de uso y conservacion

Fecha: 2026-11-19.
Repositorio: C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro.

## Resultado

Integracion en el flujo habitual de Registrar partida, con el mismo punto de entrada lib/main.dart y las mismas condiciones de confirmacion y guardado. No se cambia el motor OCR ni se atribuye una mejora de precision al reconocimiento por estas modificaciones de interfaz.

- Mover / zoom: pellizco, desplazamiento y botones de acercar, alejar y ajustar imagen.
- Seleccion: modo separado para dibujar la fila y mover sus divisiones. Mover o ampliar la foto no cambia las referencias en pixeles originales.
- Divisiones numeradas 1..10, selector de division y deslizador para ajustes finos. El cambio se conserva cuando termina el gesto.
- Revision por frames: acceso directo por numero, Anterior / Siguiente y Confirmar y siguiente. Una sola coleccion de campos y tarjetas, sin formularios duplicados. La navegacion desplaza la pantalla hasta la tarjeta correspondiente y retira el foco del teclado.
- Celda original ampliada junto a los tiros; admite ampliar con pellizco.
- Errores por tiro: falta un tiro, simbolo desconocido, spare en posicion incorrecta, tiro sobrante o incompatible, suma superior a 10 y remate que debe expresarse con /.
- La validacion estricta previa se conserva. Un frame incompatible no se puede confirmar; modificar un tiro invalida su confirmacion y la del total.
- La lectura nunca rellena tiros para hacer coincidir un total, y 207/247 del caso anterior conservan sus validaciones.
- Cambiar de foto o volver a extraer despues de corregir pide confirmacion. Entrar en edicion o tocar una division sin moverla no descarta las correcciones.

## Recuperacion local

Nuevo ScorePhotoDraftStore, independiente de Hive, Firebase y DraftService:

- Una revision actual por UID y otra distinta para invitado. UID codificado como componente seguro de ruta.
- Guarda una copia PNG de la foto normalizada, el OCR recibido, seleccion, divisiones, correcciones, total, confirmaciones y frame activo.
- Se escribe la imagen/OCR una vez por foto. Las ediciones posteriores actualizan un pequeno JSON, sin recodificar ni reescribir la foto en cada pulsacion.
- Operaciones serializadas, escritura a temporal con flush y sustitucion por rename. La imagen y sus metadatos se comprometen antes del puntero actual.
- Un fallo conserva la ultima copia comprometida. Los archivos corruptos se rechazan sin borrado automatico. Se muestra un aviso y Reintentar guardado local, sin presentar el ultimo estado como guardado.
- Las copias anteriores se retiran solo despues de comprometer una sustitucion explicita. Se limita la cache en memoria a un documento.
- Al abrir la pantalla se ofrece Retomar revision. No se aplica automaticamente ni se vuelve a ejecutar OCR al retomar.
- Cambiar de cuenta o de generacion de acceso bloquea la pantalla abierta. Las escrituras ya iniciadas siguen destinadas al UID original.
- Borrar revision guardada pide confirmacion y elimina solo los archivos propios de esa revision/cuenta. No modifica la imagen original, partidas, notas, bolas ni mantenimientos.

La copia de revision se mantiene incluso despues de Usar estos tiros. Esto permite recuperarla si, al volver al formulario, se cancela la sustitucion o el guardado. Se puede borrar explicitamente desde la pantalla o reemplazar al seleccionar otra foto y confirmar.

Almacenamiento: subdirectorio score_photo_reviews_v1 del directorio privado de soporte de la app. La foto y OCR pueden contener nombres del marcador: permanecen como copia local; no se adjuntan a la partida ni se envian a Firebase. Las copias del sistema operativo dependen de su configuracion; esta fase no cambia las reglas de backup del sistema ni del arsenal. La pantalla informa de la nueva conservacion local.

Es una recuperacion local, no un respaldo remoto ni una garantia frente a reinstalacion o borrado de datos. Esperar a Revision conservada antes de forzar el cierre. Si Android termina el proceso antes de completar una escritura, se recuperara como minimo la ultima copia comprometida; una operacion todavia pendiente puede no haberse conservado. Si aparece un error, mantener la app/datos y reintentar.

## Archivos

Nuevos:
- lib/services/score_photo_draft_store.dart.
- lib/widgets/score_photo_region_selector.dart.
- test/score_photo_draft_store_test.dart.
- test/score_photo_phase1_ui_test.dart.
- test/support/memory_score_photo_draft_store.dart.

Actualizados:
- lib/screens/score_photo_screen.dart.
- lib/services/score_photo_review.dart (explicacion de errores; mismas reglas de aceptacion).
- lib/l10n/app_es.arb, app_en.arb y archivos generados.
- test/score_photo_screen_test.dart: almacenamiento simulado y confirmacion al intentar sustituir la foto.

Sin dependencias nuevas. No se modifican modelo/adaptador Partida, DataRepository, sincronizacion del arsenal, DraftService, applicationId, configuracion de firma, reglas Firebase ni Bolometro Vision.

## Pruebas

276 pruebas correctas en la regresion conjunta; 19 nuevas: 10 de almacenamiento/validacion y 9 de interfaz.
Analisis estatico de los ocho archivos de implementacion/pruebas: sin incidencias.

Las nuevas pruebas comprueban:
- Recuperacion desde archivos reales en directorios temporales, con otra instancia del servicio.
- Separacion entre UID A, UID B e invitado, incluyendo UID con caracteres de ruta.
- Orden de escrituras concurrentes, reutilizacion de imagen, limpieza de copias obsoletas y ausencia de temporales pendientes tras exito.
- Fallo antes y despues de copiar una nueva imagen: la ultima revision comprometida sigue recuperable.
- Punteros corruptos, rutas manipuladas y propietario incoherente: rechazo sin eliminar datos.
- Zoom y seleccion: la region vuelve a los pixeles originales; mover o ajustar vista no altera coordenadas.
- Divisiones protegidas y confirmacion solo al terminar el ajuste.
- Navegacion, errores concretos y ausencia de guardado automatico de partidas.
- Cerrar/reabrir, confirmaciones conservadas y recuperacion sin repetir OCR.
- Error de almacenamiento y reintento, cambio de cuenta y descarte explicito.
- Pantalla de 360x740 con fuente 1.5, y gesto sin desplazamiento que conserva correcciones.

Registros:
- build/score_photo_phase1_regression.log.
- build/score_photo_phase1_analysis.log.
- build/score_photo_phase1_new_tests.log.
- build/score_photo_phase1_ui_tests.log.
- build/score_photo_phase1_before/protected_hashes.json.

Pruebas dedicadas:
flutter test --no-pub test/score_photo_draft_store_test.dart test/score_photo_phase1_ui_test.dart test/score_photo_screen_test.dart test/score_photo_review_test.dart test/score_photo_sample_test.dart

No se repiten los intentos costosos de OCR nativo ni se presentan pruebas sinteticas como aciertos de ML Kit sobre fotos reales. Estas pruebas validan la interfaz, geometria, calculo y conservacion local.

## Comprobacion en el movil

1. Generar e instalar normalmente con flutter build apk --release, actualizando la app sin borrar sus datos.
2. Registrar partida > escaner > seleccionar foto.
3. Pulsar Mover / zoom, ampliar y encuadrar. Volver a Editar fila y divisiones y delimitar solo los tiros del jugador.
4. Revisar los numeros de columna. Para ajustar una division, activar edicion y usar su linea o el deslizador.
5. Leer la fila. Utilizar los accesos por numero, Anterior / Siguiente y Confirmar y siguiente.
6. Probar un simbolo erroneo o un tiro ausente: comprobar que explica el problema y bloquea la confirmacion de ese frame.
7. Corregir varios frames, esperar Revision conservada y volver atras sin aplicar. Entrar de nuevo, pulsar Retomar revision y comprobar foto, seleccion, tiros y confirmaciones.
8. Probar segundo plano y cierre de la app despues del guardado, luego retomar. Comprobar teclado y desplazamiento de tarjetas en el dispositivo.
9. Verificar 207 frente a 247, confirmar y Usar estos tiros. La partida sigue exigiendo Guardar Partida y guardar la sesion.
10. Volver al lector y borrar la revision con confirmacion: la partida guardada y la foto de galeria deben mantenerse.

Limites: divisiones y filas siguen siendo manuales; el estado de zoom se reinicia al reabrir, pero la seleccion en pixeles se conserva. No se implementan todavia relectura de un frame, contraste, perspectiva, deteccion automatica de columnas ni lectura de acumulados impresos. El acumulado mostrado sigue siendo calculado.
Evolucion del flujo: SCORE_PHOTO_SIMPLE_CONFIRMATION.md introduce propuesta automatica inicial y confirmacion unica; los controles de esta fase siguen disponibles para corregir lecturas.
