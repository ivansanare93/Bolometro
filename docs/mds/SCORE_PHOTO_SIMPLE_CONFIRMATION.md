# Lectura fotografica: propuesta completa y confirmacion unica

Fecha: 2026-11-19.
Repositorio: C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro.

## Flujo actual

1. Registrar partida > escaner > seleccionar foto.
2. El lector ML Kit sigue ejecutandose localmente. Conserva palabras OCR con sus posiciones ademas de simbolos.
3. El interprete busca cabeceras 1..10 y filas de tiros debajo. Si hay una propuesta, abre su resumen. Si hay varias filas, el usuario elige una; no se escoge por puntuacion.
4. El resumen presenta la foto con la fila marcada, diez frames, total calculado y total del marcador editable, SIN handicap.
5. Es correcto, usar esta partida constituye una confirmacion humana explicita para toda la propuesta. No requiere marcar diez casillas.
6. Los tiros vuelven al formulario habitual. Siguen siendo necesarios Guardar Partida y guardar la sesion. Se conservan las condiciones existentes para reemplazar un borrador, bolas por tiro y notas.
7. Corregir lectura abre el editor existente, con los mismos campos, errores, ampliaciones y revision individual. Volver al resumen conserva esas correcciones.
8. Ajustar fila y columnas permite modificar referencias manualmente. Si no se reconoce una estructura admitida, se muestra directamente el selector manual.

Nunca se aplica una propuesta al abrir la foto o recuperar un borrador. Las pulsaciones repetidas durante el guardado local devuelven un solo resultado.

## Que comprueba el boton de confirmacion

Debe haber diez frames completos y compatibles con las reglas y un total 0..300 coincidente con su calculo. La propuesta no debe tener interpretaciones de columnas alternativas igualmente plausibles. Los acumulados intermedios leidos, cuando existen, deben coincidir.

Los tiros validos y la suma coincidente son una comprobacion de coherencia, NO una demostracion de que ML Kit ha leido correctamente la imagen. El usuario sigue contrastando los datos con la foto y el boton lo expresa como una confirmacion humana.

El ultimo acumulado es la fuente inicial del campo de total. El usuario puede corregir ese campo expresamente si el OCR falla: la fuente original queda guardada por separado. No se cambia automaticamente 247 por 207 solo porque 207 sea la suma. Los acumulados intermedios incompatibles siguen bloqueando la confirmacion rapida; se dispone de la revision individual para resolver dudas.

No se sustituyen O por 0, I por /, 10 por X ni se completan tiros desde acumulados o totales.

## Interpretacion automatica inicial: alcance concreto

Esta version busca la estructura comun:
- Cabeceras numericas 1,2,...10, alineadas horizontalmente.
- Una o varias filas de tiros debajo de esas cabeceras.
- Acumulados debajo de cada fila; el ultimo acumulado dentro de la columna 10 se usa como total inicial.

Se contrastan alineaciones de texto izquierda, centro y derecha. Las variantes se ordenan por cobertura geometrica de simbolos y compatibilidad estructural de los frames, nunca por hacer que la puntuacion coincida con una cifra global de la foto. Si variantes igualmente respaldadas producen tiros distintos, se marca la asignacion como dudosa y se bloquea el boton rapido.

Se exige evidencia en al menos ocho celdas y seis frames compatibles para mostrar una propuesta. Estos son criterios conservadores de esta primera heuristica, no porcentajes de acierto ni umbrales calibrados estadisticamente.

Para reconocer acumulados se necesitan al menos cinco celdas numericas, incluida la ultima, en una fila inferior cercana. La busqueda no utiliza el total calculado como objetivo. Las cifras fuera de las diez columnas, incluido el total con handicap, no se eligen automaticamente como total. Si falta una referencia suficiente, el total queda vacio y debe revisarse/introducirse.

Una fila de acumulados como 9,18,27,... puede parecer otra fila de tiros numericos. Solo se excluye como duplicado cuando sus textos literales coinciden con acumulados coherentes de una propuesta completa superior. No se altera ninguna lectura para conseguir esa coincidencia.

Los nombres de varias letras situados completamente a la izquierda de la primera cabecera se excluyen de las celdas; no se eliminan simbolos desconocidos dentro de las columnas. Las opciones se identifican por Fila 1, Fila 2 y la foto marcada, sin adivinar a que cuenta o jugador pertenecen.

La busqueda tiene limites de cantidad de texto y variantes. Con muchos datos, cabeceras ausentes, perspectiva pronunciada, columnas muy irregulares o demasiados simbolos dudosos se utiliza el ajuste manual. No hay correccion de perspectiva, filtros de contraste ni relectura de recortes en esta entrega.

## Modulos y compatibilidad

Nuevos:
- lib/services/score_photo_proposer.dart: interpretacion de posiciones OCR y filas.
- lib/widgets/score_photo_summary.dart: resumen y confirmacion unica.
- test/score_photo_proposer_test.dart.
- test/score_photo_simple_flow_test.dart.
- test/support/score_photo_proposal_fixture.dart.

Actualizados:
- lib/services/score_photo_reader.dart: conserva TextElement con posicion y confianza nativa, sin exponerla como precision.
- lib/screens/score_photo_screen.dart: propuesta, seleccion de fila, resumen, correccion y transferencia.
- lib/services/score_photo_draft_store.dart: palabras opcionales y validacion de indicadores de modo/acumulados.
- Textos ES/EN y archivos generados.
- Tests existentes de almacenamiento y entrada al editor detallado.

El formato de revision local mantiene version 1 y acepta paquetes anteriores sin palabras OCR. Los borradores antiguos abren su editor habitual; los nuevos recuperan el modo resumen y vuelven a exigir confirmacion. No se repite ML Kit para recuperar una revision; la eleccion de filas se puede recomponer del OCR ya guardado.

El bloqueo por cuenta tambien protege la vista ampliada, y un cambio de cuenta durante el guardado final impide devolver datos a la nueva cuenta.

Sin cambios en:
- Modelo/adaptador Hive de Partida, IDs personales, estadisticas, sesiones y mantenimientos.
- DataRepository, respaldo del arsenal o reglas Firebase.
- ApplicationId, flavors, firma Android, pubspec y dependencias.
- Bolometro Vision.

Los nueve archivos protegidos conservan sus SHA-256 respecto a build/score_photo_simple_before/protected_hashes.json.

## Pruebas y limites de evidencia

308 pruebas correctas en la regresion conjunta, incluyendo las anteriores y 32 nuevas comprobaciones del interprete, resumen, compatibilidad y privacidad.
Analisis estatico de los diez archivos revisados: sin incidencias.

Se prueban:
- Cabeceras alineadas a izquierda, centro y derecha en escalas 0.5,1,2.
- Varias filas, cabeceras ausentes, nombres a la izquierda y documentos sin palabras.
- Tiros numericos abiertos y partidas de cero.
- Simbolos desconocidos que permanecen desconocidos.
- Total global coincidente sin referencia posicional: no se adopta.
- Total incorrecto 247, correccion humana a 207 y discrepancias intermedias.
- Confirmacion unica, editor reutilizado, recuperacion sin aprobacion automatica y fallback manual.
- Doble pulsacion, cambio de cuenta durante el guardado y ocultacion de foto ampliada.
- Pantalla 360x740 con texto 1.5.
- Datos OCR nuevos y paquetes antiguos sin palabras posicionadas.

Los fixtures de posiciones son SIMULADOS e identificados como tales. No son la salida de ML Kit sobre C:\puntosBolos.jpeg. Estas pruebas no establecen una tasa de acierto del OCR sobre fotografias reales. No se han repetido los ensayos nativos costosos de emuladores de la revision anterior.

Registros:
- build/score_photo_simple_regression.log.
- build/score_photo_simple_analysis.log.
- build/score_photo_proposer_tests.log.
- build/score_photo_simple_ui_tests.log.

Comando especifico:
flutter test --no-pub test/score_photo_proposer_test.dart test/score_photo_simple_flow_test.dart test/score_photo_draft_store_test.dart test/score_photo_screen_test.dart

## Prueba privada en el telefono

Generar normalmente desde este repositorio:
flutter build apk --release

Actualizar la instalacion conservando los datos; no hace falta flutter clean ni nuevas dependencias.

Probar primero C:\puntosBolos.jpeg:
- Si las cabeceras y los simbolos se reconocen con claridad, debe aparecer el resumen 9/,X,X,9/,X,9/,9/,X,6/,9/X y total 207.
- Si el OCR no proporciona referencias suficientes, debe aparecer el selector manual o una propuesta marcada para corregir; no debe completarse por suposicion.
- Revisar la foto ampliada y pulsar Es correcto, usar esta partida solo si todo coincide.
- Comprobar que el formulario recibe 207, conserva bolas/notas y todavia requiere guardar.
- Probar 247: no debe admitirse para esos tiros sin correccion.
- Probar otra foto con varios jugadores: debe pedir elegir la fila.
- Salir antes de confirmar y retomar: no debe aplicarse automaticamente.
- Probar una lectura incompleta y usar Corregir lectura o Ajustar fila y columnas.

La validacion visual en el telefono con nuevos marcadores sigue siendo necesaria para evaluar esta heuristica. No se ha generado una APK release ni publicado, desplegado o realizado commits/push.