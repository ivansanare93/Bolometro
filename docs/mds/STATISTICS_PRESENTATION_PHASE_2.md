# Estadísticas: fase 2 de presentación

Fecha: 2026-11-04. Workspace: `C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro`.

## Pantalla normal de la aplicación

1. Filtros plegados inicialmente: resumen del tipo, temporada/sesión cuando
   aplican, fechas y límite de partidas. Al expandir aparecen los mismos
   controles y criterios de la fase 1. Restablecer limpia todos los filtros;
   los resultados vacíos también ofrecen esa acción.
2. Resumen adaptable en dos columnas (una con texto ampliado/ancho reducido):
   promedio, número de partidas, mejor puntuación y media reciente. Se indica
   el número real de partidas/sesiones filtradas y la muestra de la media
   reciente cuando hay menos de cinco partidas.
3. Evolución: puntuaciones reales y media móvil, alineada con la última
   partida de cada ventana de cinco. El eje X representa orden de partidas,
   no días transcurridos; el eje Y muestra 0–300 puntos. Tocar un punto
   actualiza el detalle con fecha, puntuación y bolera. También hay botones
   anterior/siguiente para acceder a los datos sin acertar en puntos pequeños.
   Si falta fecha de partida se muestra la fecha de su sesión.
4. Desgloses plegables: temporada completa (si se filtra una), rachas y
   porcentajes, distribución, destacados y pines. El resumen de temporada
   conserva la advertencia de alcance independiente de fechas/sesión/N.
   No se incorpora navegación a edición desde una sesión filtrada parcial.
5. Pines: número de partidas con algún dato, cantidad de primeros tiros y
   conversiones/oportunidades. Se advierte que las muestras pueden ser
   parciales. Sin oportunidades se muestra un guion, no un 0 % inventado;
   una oportunidad fallada real sí aparece como 0 %. Un array vacío de pines
   registrado representa cero pines caídos, no ausencia de observación.

## Detalles de presentación

- El histograma ordena rangos numéricamente y permite desplazamiento horizontal
  para conservar espacio para las etiquetas.
- El pastel mantiene sus valores, con leyenda externa adaptable y traducida.
- Los destacados permiten usar la fecha de sesión como fallback de lectura;
  no se modifica ninguna Partida para completar esa fecha.
- El mapa de pines ajusta separaciones y envuelve la leyenda. Se explica que
  agrupa dejes que incluyen un pin: no equivale a remates exclusivos de ese pin.
- La media móvil histórica duplica un valor cuando hay exactamente cinco
  partidas. El nuevo gráfico dibuja una sola observación de esa media,
  como punto visible. No se altera el cálculo ni su contrato existente.
- Colores y valores se acompañan de texto; soporte ES/EN y pruebas en temas
  claro/oscuro. No se han medido ni certificado requisitos completos WCAG.
- Filtros y despliegue son estado de pantalla, no preferencias persistentes.
  Una recarga puede plegar los detalles; no se modifica el almacenamiento.

## Archivos

- `lib/screens/estadisticas.dart`: integra la nueva jerarquía, sin duplicar
  repositorios ni usar otro punto de entrada.
- `lib/widgets/estadisticas/statistics_score_chart.dart`: nuevo gráfico.
- `lib/utils/statistics_samples.dart`: recuentos de muestra a partir de
  registros existentes, sin inferir pines a partir de puntuaciones.
- Widgets actualizados: `kpi_card_dinamico.dart` (presentación compacta
  opcional; resto de consumidores conserva su valor predeterminado),
  `histograma_puntuaciones.dart`, `top_partidas_widget.dart`,
  `pastel_porcentajes.dart` y `lib/widgets/per_pin_heatmap.dart`.
- Traducciones ES/EN y archivos generados de localización.
- `test/statistics_presentation_test.dart`: 14 pruebas nuevas.
- `test/statistics_reliability_test.dart`: se adapta la prueba de alcance
  para abrir filtros y temporada siguiendo el nuevo flujo; se conservan
  las verificaciones de cuentas, recargas, cronología y filtros.

## Validación reproducible

```powershell
flutter test --no-pub test/statistics_presentation_test.dart test/statistics_reliability_test.dart test/estadisticas_cache_test.dart test/estadisticas_utils_test.dart test/utils/stats_filter_test.dart test/ball_stats_service_test.dart test/season_ui_test.dart test/game_entry_viewport_test.dart
flutter analyze --no-pub --no-fatal-infos lib/screens/estadisticas.dart lib/utils/statistics_samples.dart lib/widgets/estadisticas/statistics_score_chart.dart lib/widgets/estadisticas/kpi_card_dinamico.dart lib/widgets/estadisticas/histograma_puntuaciones.dart lib/widgets/estadisticas/top_partidas_widget.dart lib/widgets/estadisticas/pastel_porcentajes.dart lib/widgets/per_pin_heatmap.dart test/statistics_presentation_test.dart test/statistics_reliability_test.dart
```

La selección conjunta contiene 103 pruebas. Las nuevas cubren filtros plegables
/restablecer, resultados vacíos, alineación de medias, gráfico de una partida,
selección/navegación y cambio de conjunto, tooltips, orden del histograma,
muestras parciales, cero frente a ausencia de datos, ES/EN y todos los
desgloses en 360 x 740 con texto al 150 %, tanto claro como oscuro.

Análisis sin errores ni advertencias; se mantienen avisos informativos de
estilo y APIs obsoletas en los archivos existentes. El formatter también
advierte de resolución de flutter_lints en este entorno; no se instala nada.
No se genera una APK ni se valida Firebase real. Permanecen las limitaciones
sobre procedencia/frescura del servidor documentadas en la fase 1.

## Prueba en dispositivo

Generar la APK habitual con `flutter build apk --release`. Instalar como
actualización, conservando datos, sin desinstalar.

- Abrir Estadísticas y comprobar resumen con filtros cerrados.
- Expandir Filtros, seleccionar fechas/temporada/últimas N, cerrarlos y
  comprobar el resumen; Restablecer debe recuperar el conjunto completo.
- Tocar puntos del gráfico y usar anterior/siguiente. Comprobar fecha y
  puntuación con las sesiones registradas.
- Abrir cada desglose, especialmente pines con muestras parciales o sin datos.
- Revisar un historial de menos de cinco partidas y otro con cinco o más.
- Probar texto grande y ambos temas, y verificar que el cambio de cuenta
  mantiene la protección de la fase 1.

Sin cambios en modelos, adaptadores Hive, IDs, sesiones almacenadas,
mantenimientos, motor/caché de cálculo, gestión de temporadas, respaldo,
catálogo, reglas/configuración Firebase, applicationId o dependencias.
Sin commits, push, despliegues, publicaciones ni cambios en Bolómetro Vision.
