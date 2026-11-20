> Actualización posterior: la atribución multibola por tiro y las puntuaciones exclusivas se describen en [BALL_ASSIGNMENTS_PER_THROW.md](BALL_ASSIGNMENTS_PER_THROW.md).

# Estadísticas: fase 3 de nuevas métricas

Fecha: 2026-11-19. Repositorio: `C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro`.

## Alcance implementado

La pantalla normal conserva el resumen, gráfico y protecciones anteriores.
Después del gráfico aparecen los paneles plegables Consistencia y comparación
reciente, Rendimiento por bola y Rendimiento por bolera. No se incorporan
objetivos, nuevos servicios externos ni cambios en el registro de partidas.

### Consistencia

`ScoreSummary` calcula cantidad, promedio, mejor puntuación y desviación
estándar poblacional del conjunto registrado: raíz de la media de los
cuadrados de las distancias al promedio (divisor n). Utiliza el algoritmo
incremental de Welford para calcularla sin depender del orden de llegada.

Con menos de dos partidas la desviación es desconocida (null) y se muestra
Sin datos suficientes. Dos o más puntuaciones iguales dan una desviación
real de 0. No se asignan etiquetas arbitrarias de bueno/malo ni una confianza
estadística inventada. Un resultado más constante no implica mayor promedio.
Se muestra siempre la cantidad de partidas analizadas.

### Comparación reciente

Selector de bloques de 5, 10 o 25 partidas; predeterminado 10. Se comparan las
últimas N con las N inmediatamente anteriores, sin solapamiento. Son
bloques equivalentes por cantidad de partidas, no por duración temporal.

La comparación recibe el conjunto ya filtrado y ordenado por el mismo motor
de cronología de la fase 1. Aplica tipo, temporada, sesión, fechas, bola,
bolera y límite de últimas partidas. No recupera datos fuera de ese conjunto
para completar un bloque. Con menos de 2N observaciones, la diferencia es
null y se muestran cantidad necesaria/disponible, sin comparar muestras
parciales ni interpretar la ausencia del bloque anterior como un cero.

Cada bloque incluye media, número de partidas y fechas extremas efectivas
(fecha de partida o de sesión si falta). La diferencia se expresa en puntos,
con una cifra decimal. Es descriptiva; no prueba una mejora de habilidad ni
el efecto de una bola/bolera. Para comparar 10 frente a 10 con el filtro
Últimas 10, es necesario cambiar ese límite o elegir bloques de cinco.

### Filtros y desgloses por bola/bolera

- Bola utilizada filtra las partidas individuales, incluso dentro de la
  misma sesión. Utiliza exclusivamente `Partida.ballId`, ID de instancia
  personal. Nunca agrupa dos unidades por su nombre/modelo comercial.
- Solo se ofrecen IDs con partidas en el historial disponible. Una bola
  archivada conserva sus referencias. Un ID sin metadatos se muestra como
  Bola con ID..., sin declarar que esté borrado ni descartar sus partidas.
- Los nombres se leen opcionalmente del arsenal local al abrir controles
  o desglose de bolas. Se incluyen peso e ID para distinguir unidades de
  igual nombre. La ausencia o el fallo de estos metadatos no bloquea las
  estadísticas. Las respuestas tardías se comprueban contra cuenta,
  generación y solicitud antes de actualizar etiquetas.
- Sin bola especificada corresponde a referencias null o en blanco; es
  distinto de Todas las bolas. No se asignan retrospectivamente bolas.
- Bolera usa el lugar de la sesión. Para consultar se recortan extremos,
  colapsan espacios y se ignora capitalización. No se unifican tildes,
  nombres parecidos ni ubicaciones por inferencia. Sin bolera especificada
  es distinto de Todas las boleras. No se modifica el texto almacenado.
- Los filtros por bola se aplican antes del límite N. Los de bolera se
  aplican junto con el resto de filtros de sesión. Se conserva el objeto
  Partida original y se crean listas de lectura para seleccionar el tramo.
- Ambos desgloses usan el conjunto filtrado actual y muestran cantidad,
  promedio, mejor puntuación y desviación. Se ordenan por muestra, no
  como clasificación de rendimiento. No controlan aceite, nivel de pista,
  entrenamiento/competición u otras condiciones no registradas.
- Al cambiar de cuenta/generación se reinician filtros y nombres locales.
  Se conservan las protecciones contra futures antiguos de la fase 1.
- La tarjeta de temporada completa mantiene su alcance previo: solo tipo
  y temporada. Su nota explica también que no aplica bola ni bolera.

## Compatibilidad y privacidad

`StatsFilter` añade selecciones sin modificar modelos persistidos. Sus claves
de caché ahora codifican estructuralmente todos los filtros, evitando
colisiones entre nulos, valores reservados y nombres con separadores. Las
copias/restablecimiento conservan opciones mutuamente excluyentes para
valor conocido frente a no especificado.

El evento de analítica existente recibe configuración de controles, no los
IDs de bolas, nombres de bolera/temporada o identificadores de sesión.
No se añaden eventos, reglas, colecciones ni despliegues Firebase.

Se han comprobado hashes de los modelos, adaptadores, repositorios,
servicios, motor/caché histórico, reglas, pubspec/lock y flag de catálogo:
permanecen intactos respecto al inicio de esta fase. El catálogo continúa
pausado y el respaldo del arsenal conserva su configuración.

## Archivos

Nuevos:
- `lib/utils/statistics_metrics.dart`: métricas y agrupaciones descriptivas.
- `lib/widgets/estadisticas/statistics_analysis_panel.dart`: interfaz normal.
- `test/statistics_metrics_test.dart`: 16 pruebas de motor/filtros.
- `test/statistics_analysis_ui_test.dart`: 11 pruebas de pantalla.

Actualizados:
- `lib/utils/stats_filter.dart` y `lib/utils/stats_selection.dart`.
- `lib/screens/estadisticas.dart`.
- ARB ES/EN y archivos generados de localización.
- Dobles de las pruebas anteriores de estadísticas: devuelven metadatos
  ficticios/vacíos sin acceder a Hive real al abrir filtros.

## Validación

130 pruebas superadas, incluyendo 27 nuevas y las regresiones de fiabilidad,
presentación, caché, cálculos, temporadas, estadísticas por bola y registro.
Se usan datos y cuentas ficticias. Casos nuevos: desviaciones conocidas,
0 frente a null, bloques completos e insuficientes, cronología, combinación
de filtros/N, IDs huérfanos o iguales entre cuentas, metadatos tardíos,
reset de cuenta, ES/EN, 360 x 740 con texto al 150 % en claro y oscuro.

```powershell
flutter test --no-pub test/statistics_metrics_test.dart test/statistics_analysis_ui_test.dart test/statistics_presentation_test.dart test/statistics_reliability_test.dart test/estadisticas_cache_test.dart test/estadisticas_utils_test.dart test/utils/stats_filter_test.dart test/ball_stats_service_test.dart test/season_ui_test.dart test/game_entry_viewport_test.dart
flutter analyze --no-pub --no-fatal-infos lib/utils/stats_filter.dart lib/utils/stats_selection.dart lib/utils/statistics_metrics.dart lib/widgets/estadisticas/statistics_analysis_panel.dart lib/screens/estadisticas.dart test/statistics_metrics_test.dart test/statistics_analysis_ui_test.dart test/statistics_reliability_test.dart test/statistics_presentation_test.dart
```

## Prueba en el móvil

Generar como siempre: `flutter build apk --release`. Instalar como actualización,
sin desinstalar ni borrar datos.

1. Estadísticas > Consistencia y comparación reciente, debajo del gráfico.
   Revisar muestra y explicación; elegir bloques de 5/10/25.
2. Probar un conjunto con menos de 2N partidas: debe advertirlo y no mostrar
   una diferencia numérica. Comparar los dos bloques completos con la lista
   de sesiones cuando haya suficientes datos.
3. Filtros > Bola utilizada / Bolera de la sesión. Probar combinaciones,
   Sin especificar y Restablecer; comparar el resumen con partidas conocidas.
4. Abrir Rendimiento por bola/bolera. Revisar unidades personales distintas,
   bolas archivadas, muestras pequeñas y ausencia de etiquetas concluyentes.
5. Cambiar de cuenta/invitado: los filtros vuelven al conjunto completo y
   ningún nombre de la anterior debe reaparecer tras una respuesta tardía.

## Límites

Se mantienen los límites previos de procedencia/frescura de Firestore: algunos
errores son absorbidos por la capa existente. No se han probado datos reales,
no se certifica servidor actualizado y no se ha generado APK. Las nuevas
métricas describen los totales guardados; no incorporan un criterio nuevo
de completitud/validación de partidas, significación estadística ni causalidad.
Los datos/filtros y etiquetas son estado de pantalla; no se sincronizan ni
persisten como preferencias. El rendimiento con historiales muy grandes
no se ha medido. Permanecen avisos informativos de estilo/APIs antiguas.

Sin dependencias nuevas, cambios en datos reales, commits, push, despliegues,
publicaciones ni modificaciones de Bolómetro Vision.
