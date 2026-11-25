# Relectura local de un frame del marcador

Fecha: 2026-11-20.
Repositorio: C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro.

## Uso

Registrar partida > escaner > seleccionar foto > Corregir lectura.
En cada tarjeta, pulsar Volver a leer este frame.
Se muestra el recorte original ampliado y una propuesta OCR nueva.
Conservar lo anterior cancela sin modificar las correcciones.
Usar esta propuesta cambia solo los tiros de ese frame, tras confirmacion expresa.
Un frame incompleto o incompatible con las reglas no puede aceptarse.

Los otros nueve frames, sus confirmaciones y el texto del total se conservan.
El frame sustituido y el total deben confirmarse de nuevo. No se ajusta el total
para hacer coincidir una lectura. Sigue siendo necesario guardar partida y sesion.
Las correcciones aceptadas usan el mismo borrador por cuenta y su recuperacion
existente. No se guarda una partida automaticamente ni se modifica la foto fuente.

Si el recorte no corresponde a los tiros, ajustar primero fila y columnas.
Una relectura no corrige por si sola una division equivocada ni la perspectiva.
El texto OCR original del documento se conserva; el cuadro de propuesta muestra
la lectura nueva y los tiros aceptados se conservan como correcciones del borrador.
No se mantiene un historial separado de todas las relecturas descartadas.

## Implementacion

- lib/services/score_photo_frame_reader.dart: valida coordenadas y resolucion,
  recorta los pixeles de la imagen normalizada y relee solo esa celda.
- Ampliacion de hasta 2x, limitada a 4096 pixeles por lado. No recupera informacion
  inexistente ni garantiza mejorar el reconocimiento.
- Reutiliza ScorePhotoReader y su modelo Latin local, sin nuevas dependencias.
- No sustituye simbolos dudosos ni completa tiros mediante puntuaciones.
- El decimo frame admite sus tres tiros; los anteriores no aceptan un tercer tiro.
- Los temporales propios se eliminan en finally, tambien cuando falla el OCR.
- Pantalla bloqueada durante la solicitud; pulsaciones repetidas no duplican OCR.
- Cancelacion, salida y fallo conservan los valores anteriores.
- Cambio de UID o generacion de cuenta descarta la respuesta; el dialogo oculta
  el recorte y deshabilita aplicar si cambia la cuenta durante su revision.

## Verificacion

Regresion conjunta: 320 pruebas correctas. Analisis estatico: sin incidencias.

12 pruebas nuevas: simbolos ambiguos, tres tiros del decimo, indices invalidos,
recorte real PNG y dimensiones, imagen fuente intacta, limites geometricos,
fallo del reconocedor inyectado, cancelacion, cambio limitado a un frame,
invalidacion de confirmaciones, lectura incompatible, error OCR, cambio de
cuenta durante solicitud y durante dialogo, y pulsaciones repetidas.

Los recortes se renderizan realmente en las pruebas; la salida del reconocedor
se simula. No son medidas de precision del SDK nativo sobre fotos reales.

Registros:
- build/score_photo_reread_new_tests.log
- build/score_photo_reread_regression.log
- build/score_photo_reread_analysis.log

Comando dedicado:
flutter test --no-pub test/score_photo_frame_reader_test.dart test/score_photo_reread_ui_test.dart

Sin cambios en dependencias, Hive, IDs, respaldo, Firebase, estadisticas,
Bolometro Vision, firma o applicationId. No se genera ni publica una APK.

## Pruebas recomendadas en Android

Generar desde este repositorio: flutter build apk --release.
Actualizar la instalacion conservando sus datos.

1. Leer C:\puntosBolos.jpeg y abrir Corregir lectura.
2. Corregir manualmente dos frames y releer otro: comprobar que no cambian.
3. Comparar el recorte con la propuesta, cancelar y comprobar los valores.
4. Releer y aceptar: comprobar solo ese frame, total pendiente y calculo normal.
5. Salir y retomar la revision: comprobar que las correcciones aceptadas persisten.
6. Probar el decimo frame con tres tiros y una foto de baja calidad.
7. Una lectura dudosa debe permitir cancelar y corregir manualmente, sin inventar
   observaciones. La coincidencia del total no demuestra que el OCR sea correcto.
