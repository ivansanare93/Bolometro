# Registro de partidas desde una foto del marcador

Fecha: 2026-11-19.
Repositorio: C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro.

## Alcance implementado

Primera version para Android, integrada en Registrar partida, dentro del flujo normal de sesiones. Lee simbolos con OCR local, permite seleccionar la fila de un jugador y sus diez frames y exige revision antes de transferir los tiros al formulario. No es una captura desatendida ni una prueba de precision OCR validada con marcadores reales.

El usuario autorizo expresamente instalar ML Kit. No se han modificado modelos/adaptadores Hive, IDs personales, repositorio, sincronizacion, reglas Firebase, Flutter applicationId ni Bolometro Vision. No se ha generado APK, firmado, publicado ni desplegado nada.

## Uso en el movil

1. Detener la ejecucion anterior y volver a compilar: el plugin nativo necesita reinicio completo, no basta hot reload.
2. Desde este repositorio: flutter run. Para generar la APK con la configuracion de firma habitual: flutter build apk --release.
3. Crear o abrir una sesion y pulsar Anadir partida.
4. En Registrar partida, pulsar el icono de escaner situado arriba, junto a Inicio.
5. Seleccionar de la galeria una foto del marcador. Se puede tomar previamente con la camara del movil.
6. Arrastrar un rectangulo sobre la fila de TIROS de UN jugador, desde el primer frame hasta el decimo. Excluir encabezados, nombres, puntuaciones acumuladas, handicap y otros jugadores.
7. Las divisiones iniciales son equidistantes, no un layout detectado. Si no coinciden, pulsar Editar fila y divisiones y arrastrar una linea. Repetir para otras divisiones. Al terminar un gesto se libera el desplazamiento de la pagina.
8. Pulsar Leer fila seleccionada. Cada frame muestra una ampliacion de su celda original.
9. Corregir los simbolos y marcar cada frame como Revisado. X = strike, / = spare, - o 0 = fallo. ? es ambiguo y debe corregirse. Un strike normal no tiene segundo tiro.
10. Introducir el total SIN handicap, o elegirlo de los numeros reconocidos. La lista contiene candidatos, NO identifica automaticamente cual es el total correcto. Revisarlo y marcar su casilla.
11. Solo se permite Usar estos tiros con diez frames validos, sus diez confirmaciones, total confirmado de 0 a 300 y coincidencia con la suma calculada.
12. Al volver al formulario, revisar bolas por tiro y notas y pulsar Guardar Partida. Guardar despues la sesion como siempre. Si ya habia tiros o selecciones de pines, se pide confirmacion antes de sustituirlos.

Cancelar la galeria o la revision no aplica tiros. Cancelar la seleccion de otra foto conserva las correcciones previas. Volver a extraer una fila crea una revision nueva. La revision fotografica sin aplicar vive en memoria; si el sistema cierra la app hay que repetirla. Una vez aplicada utiliza el borrador existente, separado por cuenta.

## Componentes y archivos

- lib/services/score_photo_reader.dart: lectura local, normalizacion a PNG, adaptacion de simbolos y posiciones OCR y extraccion espacial de la fila.
- lib/services/score_photo_review.dart: candidato inmutable, validacion estricta de diez frames y bonus del decimo, comparacion del total y requisito de revision.
- lib/screens/score_photo_screen.dart: galeria, seleccion y divisiones, ampliaciones, correccion y confirmacion.
- lib/screens/registro_sesion.dart: entrada por escaner y transferencia al formulario normal; confirmacion de sustitucion y comprobacion de UID/generacion de cuenta.
- lib/l10n/app_es.arb, app_en.arb y tres archivos generados: textos ES/EN.
- pubspec.yaml y pubspec.lock: dependencia aprobada y resolucion fijada.
- test/score_photo_review_test.dart y test/score_photo_screen_test.dart: pruebas aisladas sin datos reales.

La partida conserva el esquema existente: tiros normalizados, total calculado y las asignaciones personales que el usuario haya indicado. No se persiste la foto, el texto OCR completo ni los nombres de otros jugadores. No se deducen identidades de pines, splits ni bolas desde una puntuacion. Al sustituir tiros, las selecciones visuales de pines previas se retiran solo despues de confirmacion, pues dejarian de describir observaciones fiables.

Tambien se permite guardar una partida completa de cero puntos: el validador anterior la confundia con una partida vacia. La excepcion requiere que los diez frames completos superen la validacion estricta.

## Dependencias y funcionamiento local

Instaladas con aprobacion:
- google_mlkit_text_recognition 0.15.0 (fijada).
- google_mlkit_commons 0.11.1 (transitiva).
No se han actualizado otras dependencias. La version de la app ya era 1.7.3+16 y se conserva.

La version fijada declara Dart >=2.16.0 <4.0.0 y Flutter >=2.5.0; su paquete Android usa compileSdk 35 y com.google.mlkit:text-recognition:16.0.1 con modelo latino incluido. El proyecto utiliza minSdk 23 y compileSdk al menos 35. Esta comprobacion de requisitos y el analisis Dart NO sustituyen una compilacion Gradle ni una ejecucion nativa.

El modelo incluido permite OCR sin descargar un modelo en el primer uso. Google estima aproximadamente 4 MB por escritura/arquitectura; no es una medida del aumento real de esta APK.
Fuente: https://developers.google.com/ml-kit/vision/text-recognition/v2/android

El puente Flutter es comunitario, no mantenido por Google. Su licencia publicada es MIT; el SDK nativo tiene terminos propios:
- https://pub.dev/packages/google_mlkit_text_recognition/versions/0.15.0
- https://pub.dev/packages/google_mlkit_text_recognition/versions/0.15.0/license
- https://developers.google.com/ml-kit/terms

Segun Google, las imagenes y los resultados se procesan en el dispositivo y no se envian a sus servidores. El SDK puede enviar metricas tecnicas de uso/rendimiento y realizar comunicaciones tecnicas. No debe describirse como un SDK sin ninguna comunicacion de red. La pantalla informa de este matiz. Antes de publicar, revisar los avisos de privacidad y la declaracion Data safety pertinentes, sin cambiar Firebase para habilitar OCR.

La foto se decodifica una sola vez y se crea un PNG temporal compartido por OCR y previsualizacion: ambos trabajan sobre la misma orientacion y resolucion. El temporal propio se retira al acabar; no se elimina el fichero seleccionado por el usuario. Puede existir cache temporal del selector del sistema; no es un adjunto de la partida. Limites: 20 MiB y 16 millones de pixeles; errores recuperables, sin bajar silenciosamente la resolucion de letras pequenas.

iOS no se ha configurado ni validado. El paquete requiere iOS 15.5; este repositorio carece de Podfile y requiere revisar su integracion nativa antes de compilar para esa plataforma. La lectura se limita expresamente a Android. No se han elevado objetivos iOS ni cambiado permisos nativos.

## Pruebas realizadas

246 pruebas correctas: 21 de esta funcionalidad y 225 de regresion de modelos, arsenal, asignaciones por tiro, estadisticas, temporadas, teclados y viewport.
La prueba sintetica incluye 500 partidas validas generadas con semilla fija, comparadas contra un calculador independiente de tiros planos; son casos dentro de una prueba, no 500 pruebas adicionales.

Se verifican: 300, cero, spares, extras, filas incompletas, caracteres ambiguos, totales ausentes/incompatibles, acumulados fuera de la fila, OCR que cruza divisiones, ajuste de divisiones, revision obligatoria, invalidacion al editar, cancelacion, recuperacion de errores, pantalla pequena con fuente 1.5, guardado por el formulario normal, cambio de generacion de cuenta, rechazo y aceptacion de sustitucion, conservacion de bolas/notas y retirada de pines anteriores.

Los tests de interfaz usan documentos OCR sinteticos e inyeccion de resultados; NO ejecutan el SDK ML Kit nativo en un movil ni acreditan la precision con fotos reales.

Analisis estatico de los seis archivos de implementacion/pruebas: sin errores ni warnings; permanece un info previo de withOpacity obsoleto en Registrar partida.
Registros:
- build/score_photo_regression.log
- build/score_photo_analysis.log
- build/score_photo_before/protected_hashes.json

Los seis archivos protegidos del manifiesto conservan exactamente su SHA-256: modelo y adaptador Partida, reglas, repositorio, sincronizacion del arsenal y pantalla de edicion.

Comando de pruebas especificas:
flutter test --no-pub test/score_photo_review_test.dart test/score_photo_screen_test.dart

## Validacion pendiente y limites

- No se ha proporcionado una foto real ni ejecutado OCR en un dispositivo Android en esta sesion. Es el siguiente paso necesario. No se afirma precision o porcentaje de aciertos.
- Probar fotos de varios marcadores, nítidas, frontales, y con tiros visibles. Si solo aparecen acumulados o total, los tiros no se pueden reconstruir.
- Una foto con varios jugadores se procesa un jugador/partida cada vez, mediante seleccion expresa. No hay importacion masiva ni identificacion automatica del jugador.
- El OCR no comprende reglas de bowling: confusiones X/numero, slash/reflejo, circunferencias de split, faltas F y texto pegado requieren correccion. No se convierten O en 0, 10 en X ni F en cero automaticamente.
- No hay correccion de perspectiva, deteccion automatica fiable de celdas ni captura directa de camara en esta primera version. Una foto muy inclinada puede mezclar filas.
- Probar rotacion EXIF, fotos verticales/horizontales, galeria cancelada, permisos denegados, oscuridad/reflejos, lectura sin conexion y limites de memoria/tamano. Reencuadrar antes en galeria si es necesario.
- Probar abrir con tiros previos y cancelar; despues aceptar sustitucion y comprobar bolas/notas. Confirmar que no aparecen estadisticas de pines identificados por una importacion numerica.
- Comprobar que 10 frames y total coinciden con la pantalla real, guardar la sesion, reabrir y verificar puntuacion y estadisticas.
- El total calculado coincidente es una comprobacion de coherencia, NO una demostracion de lectura correcta: dos errores pueden compensarse. La revision visual sigue siendo obligatoria.
- Una compilacion release real y la carga del plugin nativo siguen pendientes de la prueba local del usuario. El uso actual de firma se conserva; no se ha generado una firma alternativa ni una APK paralela.
## Correccion de compilacion release: R8 y modelos opcionales (2026-11-19)

Se reprodujo el bloqueo de clases ausentes indicado por la compilacion del usuario. El plugin 0.15.0 incluye referencias a reconocedores chinos, devanagari, japoneses y coreanos como opciones compileOnly. El lector de Bolometro solicita exclusivamente TextRecognitionScript.latin.

Cambios:
- android/app/proguard-rules.pro: ocho reglas -dontwarn exactas para las opciones y sus Builder, correspondientes al missing_rules.txt generado. No hay patrones globales.
- android/app/build.gradle.kts: proguardFiles("proguard-rules.pro") dentro del build type release, conservando firma y optimizacion.

No se han incorporado modelos de otros idiomas ni desactivado R8. Si se habilitan esas escrituras en el futuro, instalar sus dependencias de runtime y retirar las excepciones correspondientes; estas reglas no aportan soporte a esos idiomas.

Comprobacion nativa realizada:
cd android
.\gradlew.bat :app:minifyReleaseWithR8 --offline --console=plain

Resultado: BUILD SUCCESSFUL in 1m 4s; 319 tareas, 5 ejecutadas y 314 actualizadas. Registro: build/score_photo_r8_validation.log. Se ha validado la tarea release que fallaba, sin ejecutar assembleRelease ni firmar una APK.

Para terminar el empaquetado habitual:
flutter build apk --release

Siguen pendientes la instalacion y la prueba OCR con fotos reales. Los avisos de tree-shaking y operaciones Java unchecked del paquete no eran la causa del fallo.

Referencia Android sobre clases ausentes y excepciones concretas:
https://developer.android.com/build/releases/agp-8-0-0-release-notes

Revision del ejemplo de 207 puntos: ver SCORE_PHOTO_207_VALIDATION.md y docs/diagnostics/score_photo_207_validation.json. Incluye acumulados por frame, aviso de handicap y ensayos nativos no completados; no se afirma precision OCR.

Actualizacion de facilidad de uso: SCORE_PHOTO_USABILITY_PHASE_1.md. La foto y el progreso ahora se conservan como revision local por cuenta, con recuperacion y borrado explicitos; no se adjuntan a la partida.

Flujo actual simplificado: ver SCORE_PHOTO_SIMPLE_CONFIRMATION.md. La lectura propone una partida completa cuando encuentra una estructura compatible, requiere una confirmacion humana unica y conserva el editor/manual como alternativa.
