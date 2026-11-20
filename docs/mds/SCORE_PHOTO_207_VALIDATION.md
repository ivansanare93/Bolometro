# Validacion del ejemplo de marcador: 207 puntos

Fecha: 2026-11-19.
Repositorio: C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro.
Archivo proporcionado: C:\puntosBolos.jpeg (66.418 bytes).
SHA-256: 1bfccf05e19adc880d548106cb48ddf423ad5438d66130bc8ae7debfbe74061f.

## Referencia visual humana

La imagen permite distinguir una fila de tiros, una fila inferior de puntuaciones acumuladas y dos cifras finales bajo Tot + hdcp. La lectura visual es:

| Frame | Tiros | Acumulado |
|---|---|---|
| 1 | 9 / | 20 |
| 2 | X | 49 |
| 3 | X | 69 |
| 4 | 9 / | 89 |
| 5 | X | 109 |
| 6 | 9 / | 128 |
| 7 | 9 / | 148 |
| 8 | X | 168 |
| 9 | 6 / | 187 |
| 10 | 9 / X | 207 |

El total sin handicap es 207. La otra cifra visible es 247; su diferencia respecto a 207 es 40. No se registra handicap en el modelo personal ni se inventan tiros para obtener 247.

Esta referencia se ha transcrito manualmente de la imagen. Es un caso de regresion de puntuacion y revision, NO la salida del OCR ni una medida de su precision.

## Cambios seguros realizados

- El validador devuelve acumulados calculados por frame, inmutables. Solo se calculan cuando los diez frames pasan la validacion estricta; los desconocidos quedan null, sin completar tiros.
- La pantalla muestra esos acumulados junto a los frames, para compararlos con la fila inferior del marcador.
- Los candidatos numericos que coinciden con el total calculado se muestran primero y se identifican como coincidencia a verificar. No se seleccionan ni confirman automaticamente.
- Se explicita la diferencia entre total y total + handicap. Elegir 247 para estos tiros bloquea Usar estos tiros, aunque 247 este dentro de 0..300.
- Cambiar el total invalida su confirmacion anterior.
- El lector admite un callback opcional de etapas fijas para diagnosticar ensayos nativos, sin registrar fotos, rutas personales, nombres ni texto completo. El flujo normal no activa esos registros.

No se han cambiado reglas Firebase, respaldo del arsenal, repositorio, modelo/adaptador Partida, identificadores personales ni configuracion Android/R8. Los siete archivos protegidos conservan sus hashes. No hay nuevas dependencias ni modificaciones a Bolometro Vision.

## Ensayos automatizados

257 pruebas correctas: las 246 de regresion anteriores mas 11 casos especificos del ejemplo. Entre los casos nuevos:

- Coincidencia de los diez acumulados y del total 207.
- Rechazo de 247 por discrepancia, no por estar fuera del rango.
- Tiro legal cambiado sin alterar los demas para forzar el total.
- Slash ausente: acumulados null.
- Geometrias OCR SINTETICAS a escalas 0.5, 1 y 2, conservando fuera cabeceras y acumulados.
- Seleccionar la fila de acumulados como tiros no produce una partida valida.
- Ordenacion de candidatos sin seleccion automatica.
- Corregir 247 a 207 sigue exigiendo revisar otra vez el total.

Los 500 juegos sinteticos de la prueba general tambien verifican que el ultimo acumulado coincide con el total independiente.
Analisis estatico de los seis archivos revisados: No issues found.
Registros: build/score_photo_sample_regression.log y build/score_photo_sample_analysis.log.

## Intento de OCR nativo: NO completado

Se intento ejecutar el mismo ScorePhotoReader de la app con el JPEG real en emuladores Android, sin instalar ni sustituir la app del telefono fisico.

No se obtuvo un informe OCR nativo completo:
- Los procesos de ensayo del emulador API 37 terminan antes de producir una lectura verificable. Los registros de Android muestran terminacion de procesos, sin un resultado OCR que permita medir aciertos.
- API 36 no termino de quedar disponible por ADB, incluso en la instancia de solo lectura con 4096 MiB.
- Los primeros intentos de transferir la entrada fallaron por el limite de argumentos Windows, la limpieza de datos al instalar el test y la transferencia binaria por ADB. El helper final evita esos mecanismos: usa un fixture Dart exclusivo del test y lo restaura al terminar.
- Un ensayo omitido o una interrupcion NO se contabilizan como una prueba OCR correcta.
- Estas incidencias no demuestran un fallo del lector de ML Kit en el telefono del usuario. No se ha establecido una causa definitiva del fallo del entorno.

Por ello no hay porcentaje de aciertos, frames reconocidos ni total detectado por ML Kit para esta foto en esta sesion. Esos valores estan separados como desconocidos en docs/diagnostics/score_photo_207_validation.json. La cifra 207 proviene de la referencia humana y del calculo sobre esa transcripcion.

Los emuladores iniciados para las pruebas se han cerrado. No se han borrado ni modificado datos del telefono. No se ha generado APK release. Las APK debug generadas por Flutter durante los ensayos son artefactos de integracion, no una version de usuario: no distribuirlas ni instalarlas en el movil. Un flutter run o flutter build apk --release normal vuelve a compilar lib/main.dart.

## Ensayo nativo reproducible

Archivos:
- integration_test/score_photo_native_test.dart.
- integration_test/support/score_photo_private_input.dart: queda vacio despues del ensayo.
- tool/test_score_photo_native.ps1: solo acepta seriales emulator-NNNN.
- test/fixtures/score_photos/scoreboard_207_native_config.json: region/divisiones estimadas manualmente para ESTA foto y tiros esperados. No son un detector de layout ni parametros globales.
- test/fixtures/score_photos/scoreboard_207_manual.json: referencia humana sin nombre del jugador ni fotografia.

En un emulador compatible, arrancado en modo -read-only y sin datos personales, ejecutar desde este repositorio:

powershell -NoProfile -ExecutionPolicy Bypass -File tool/test_score_photo_native.ps1 -ImagePath C:\puntosBolos.jpeg -EmulatorSerial emulator-5580 -LayoutConfig test/fixtures/score_photos/scoreboard_207_native_config.json

Adaptar el serial al emulador real. El script rechaza los seriales de telefonos fisicos. La imagen solo entra en el fichero temporal de datos de esa compilacion de test; el helper restaura el stub mediante finally. La app normal no importa ese archivo y la foto no se ha anadido a pubspec ni a assets.

El informe se emite como PHOTO_OCR_REPORT, con simbolos/posiciones de la region elegida, candidatos numericos y comparacion con la transcripcion separada. Comparar resultados, no solo el estado passed del test de transporte/lectura.

## Proxima comprobacion en el movil

1. Recompilar normalmente con flutter build apk --release; conservar los datos al actualizar la instalacion.
2. Elegir esta foto desde Registrar partida > escaner.
3. Delimitar SOLO la franja de tiros: por debajo de las cabeceras 1..10 y por encima de los acumulados; excluir nombre y columnas finales.
4. Ajustar las divisiones a las lineas de cada frame y leer la fila.
5. Contrastar cada tiro con la tabla anterior. Si falta un slash, una X o un numero, corregirlo manualmente, sin inferirlo desde 207.
6. Verificar que los acumulados calculados coinciden con 20,49,69,89,109,128,148,168,187,207.
7. Seleccionar 247 y comprobar que no permite aplicar. Cambiar a 207, revisar las confirmaciones y aplicar.
8. Guardar partida y sesion y reabrir para comprobar los datos.
9. Anotar los frames que exigieron correccion y los simbolos que mostro el OCR. Esa evidencia del movil permitira mejorar la lectura sin atribuirle una precision no medida.

No ajustar sustituciones O->0, I->/ o 10->X solo para conseguir que este ejemplo sume 207. La suma coincidente puede ocultar errores que se compensan; mantener revision visual y probar mas marcadores y fotografias.