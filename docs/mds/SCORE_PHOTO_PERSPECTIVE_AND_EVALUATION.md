# Preparacion del marcador y evaluacion de exactitud

Fecha: 2026-11-20.
Repositorio: C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro.

## Flujo normal

Registrar partida > escaner > elegir foto > preparar foto (opcional) > OCR >
propuesta completa > Es correcto, usar esta partida > formulario habitual.

En Preparar foto se puede pulsar Leer foto sin corregir directamente.
Para enderezar: incluir las cabeceras 1..10, los tiros y sus acumulados; marcar
1 superior izquierda, 2 superior derecha, 3 inferior derecha, 4 inferior izquierda.
El selector permite volver a cualquier esquina; tocar coloca la esquina y pasa
a la siguiente. Arrastrar ajusta la esquina seleccionada. Mover / zoom permite
ampliar y desplazar sin cambiar los puntos. Restablecer devuelve la foto completa.

Enderezar y previsualizar genera una imagen nueva en memoria. Revisarla antes de
Leer este encuadre. Un cambio de puntos invalida la previsualizacion anterior.
Las esquinas cruzadas, repetidas, fuera de imagen, mal ordenadas o casi colineales
no se aceptan. No se ordenan automaticamente ni se adivina el marcador.

La foto de galeria permanece intacta. El OCR y las vistas posteriores utilizan
exactamente el PNG elegido (original normalizado o rectificado). La revision por
frame y su relectura trabajan sobre esas mismas coordenadas.

La preparacion aun no es un borrador recuperable: se conserva solo al leer la
imagen y comprometer el borrador habitual. Cancelar no ejecuta OCR ni sustituye
la revision anterior. Cambiar de cuenta oculta la imagen y descarta su resultado.
Una correccion aceptada no guarda automaticamente la partida ni la sesion.

## Geometria y recursos

ScorePhotoReader separa loadImage de readPrepared y conserva read para sus
consumidores anteriores. Se mantiene el PNG orientado comun para OCR e interfaz.
La normalizacion admite hasta 20 MiB de entrada y 16 millones de pixeles.

ScorePhotoPerspective resuelve una homografia con coordenadas normalizadas y
pivoteo; valida convexidad, orden, estabilidad y denominadores. No tiene ninguna
relacion con calibracion fisica de pistas ni permite calcular velocidad.
Usa Canvas.transform, sin dependencias nuevas ni servicios externos:
https://api.flutter.dev/flutter/dart-ui/Canvas/transform.html

La salida toma la mayor longitud de los lados opuestos; no presupone una relacion
de aspecto fisica conocida. Es una aproximacion visual, no recupera dimensiones
reales ni detalle perdido. Cada lado se limita a 4096 px y la salida a 16 MP.
Las fotos mayores pueden reducirse durante esta preparacion; se puede elegir
leer la original sin corregir. La imagen previa y la rectificada se previsualizan
sin deformaciones adicionales, con BoxFit.contain.

No elimina reflejos, desenfoque ni saturacion. Un recorte que excluya una cabecera,
un tiro o un acumulado puede empeorar el OCR. No se anuncia una mejora de exactitud
hasta medirla con referencias revisadas y resultados nativos independientes.

## Primera foto y expedientes

C:\puntosBolos.jpeg, SHA-256
1bfccf05e19adc880d548106cb48ddf423ad5438d66130bc8ae7debfbe74061f.
La transcripcion contiene 17 tiros, total 207 y total con handicap 247.

- scoreboard_207_reference.json: transcripcion manual separada, pendiente de
  confirmacion humana independiente. No se presenta como salida OCR.
- scoreboard_207_evaluation_demo.json: ejemplo SINTETICO del evaluador.
- orientation_6_synthetic.jpeg: patron de colores propio con EXIF 6; no es un
  marcador comercial ni una fotografia de usuario.
- scoreboard_207_perspective_native_config.json: esquinas y fila estimadas a mano
  para comparar geometria; no son una deteccion automatica ni una seleccion
  confirmada por el usuario. La fila manual del diagnostico debe revisarse.

Demostracion local producida sin ejecutar ML Kit:
- build/score_photo_perspective/puntosBolos_corners.png
- build/score_photo_perspective/puntosBolos_rectified.png

Se ha revisado visualmente que el recorte conserva las diez cabeceras, tiros y
acumulados y excluye la zona de total con handicap. No hay evidencia todavia de
que el OCR nativo interprete mas tiros correctamente. Las fotos reales y las
salidas privadas permanecen fuera de assets y pubspec, en build ignorado por Git.

## Evaluacion reproducible

ScorePhotoEvaluation compara propuestas SIN correcciones con una referencia,
comprobando ID y SHA-256 de la imagen. Cuenta tiros esperados, aciertos, faltantes
o incorrectos, tiros sobrantes, frames exactos, total correcto y partida exacta.
Identifica juegos estructuralmente coherentes pero incorrectos. Esa coherencia
solo cubre reglas de tiros y total; no equivale a que todos los controles de la
interfaz (columnas ambiguas/acumulados) permitan la confirmacion rapida.

Los datos nativos y sinteticos se etiquetan por separado. Una transcripcion sin
confirmacion humana independiente no es elegible para afirmar precision medida.
Los resultados nativos deben obtenerse antes de corregir manualmente la propuesta.
No se elige la fila usando el total esperado. Varias filas se registran como
necesidad de seleccion, no se fuerza una propuesta coincidente.

Ejemplo ejecutable sin OCR ni red, desde el repositorio:

dart tool/evaluate_score_photo.dart test/fixtures/score_photos/scoreboard_207_reference.json test/fixtures/score_photos/scoreboard_207_evaluation_demo.json build/score_photo_evaluation_demo.json

El ejemplo indica evidence=synthetic y eligible_for_accuracy_claim=false.
No es una medida de acierto sobre la foto.

El harness nativo existente sigue restringido a EMULADORES, sin instalar nada
en el telefono del usuario. Admite ReferenceFile y exporta propuestas originales
o rectificadas a build. Comando PowerShell, con Flutter/ADB en PATH y un emulador
aislado funcional:

./tool/test_score_photo_native.ps1 -ImagePath C:\puntosBolos.jpeg -EmulatorSerial emulator-5554 -LayoutConfig test/fixtures/score_photos/scoreboard_207_native_config.json -ReferenceFile test/fixtures/score_photos/scoreboard_207_reference.json

Repetir con scoreboard_207_perspective_native_config.json. Ambos usan el mismo
original y SHA-256, pero distinto preprocesado. Evaluar cada prediction.json con
el mismo fichero reference.json y tool/evaluate_score_photo.dart. El script no
cambia la transcripcion ni la marca como confirmada. Un OCR completado sin texto
es un resultado sin propuesta; un fallo del SDK es un fallo de ejecucion.

No se han repetido los ensayos nativos costosos de los emuladores que fallaron
en la revision anterior. La sintaxis PowerShell y el analisis estatico del harness
estan comprobados; su exportacion nueva necesita una ejecucion nativa completa.
El fichero de entrada privada permanece vacio y el helper restaura sus bytes en
finally. Las fotos nunca se importan desde lib/main.dart ni se empaquetan en APKs
normales. No ejecutar este harness en un dispositivo con datos reales.

## Ampliar el conjunto

Registrar nuevas fotos privadas con ID estable, SHA-256, condiciones (inclinacion,
reflejos, resolucion, filas, modelo de marcador) y transcripcion independiente.
Incluir juegos de cero, strikes, spares, decimo con extras, handicap y varios
jugadores. Confirmar cada transcripcion comparandola con la foto y el calculo.
No publicar nombres, fotos ni OCR completo de usuarios sin autorizacion.

Comparar siempre las mismas fotos, sin corregir los resultados evaluados. Medir
partidas exactas y coherentes incorrectas, no solo cantidad de propuestas.
Actualmente: 1 foto registrada, 0 referencias confirmadas independientemente,
0 comparaciones OCR nativas completadas; exactitud real desconocida.

## Compatibilidad y comprobacion en el movil

Sin cambios en Hive, IDs, sesiones, estadisticas, mantenimiento, respaldo,
Firebase, applicationId o dependencias. Sin commits, push, despliegues ni APK
release generada por el asistente. El usuario puede generar normalmente:

flutter build apk --release

Actualizar conservando datos. Comparar leer la misma foto sin corregir y con el
encuadre propuesto, antes de editar. Revisar especialmente 9/, X y 9/X del decimo,
207 frente a 247, cambios de jugador, esquinas cruzadas y cancelacion. Comprobar
que el resumen sigue exigiendo confirmacion y el formulario guardar partida.

Registros: build/score_photo_perspective_regression.log,
build/score_photo_perspective_analysis.log, build/score_photo_real_geometry.log.

## Resultados de esta entrega

340 pruebas correctas en la regresion conjunta (20 nuevas respecto a la entrega
anterior), incluida la demostracion geometrica sobre la foto real. Analisis
estatico de 12 archivos: sin incidencias. Sintaxis PowerShell: correcta.
Los siete archivos protegidos mantienen su SHA-256 respecto a
build/score_photo_perspective_before/protected_hashes.json.
La foto original mantiene tambien su SHA-256. No se han ejecutado pruebas nativas
OCR en esta entrega ni se han descargado imagenes o instalado dependencias.
