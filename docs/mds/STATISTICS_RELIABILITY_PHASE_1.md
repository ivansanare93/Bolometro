# Estadísticas: fase 1 de fiabilidad

Fecha: 2026-11-04. Repositorio: `C:\Users\ivans\bolometro\Bolometro_PRO\Bolometro`.

## Cambios

- `lib/utils/stats_selection.dart`: selección compartida y no destructiva.
  Las sesiones se ordenan por fecha; las partidas por su fecha, si existe,
  o por la fecha de sesión. Los empates dentro de una sesión conservan el
  orden registrado. No se alteran listas originales ni identificadores.
- `lib/utils/estadisticas_cache.dart`: comparación de contenido JSON completo,
  incluida información de pines, en vez de número de elementos/identidad.
  Cada llamada desde la pantalla lleva UID (null para invitado). Al cambiar
  la cuenta se descartan las entradas anteriores; hasta 32 claves por cuenta
  y caducidad de cinco minutos. Se conservan las APIs existentes y no se
  notifica desde lecturas que ocurren durante build. Serializar para validar
  tiene coste lineal respecto a los datos: no se promete rendimiento medido
  con historiales grandes.
- Se cuentan las sesiones sin partidas, pero no compiten como mejor/peor
  sesión jugada. Corregido el fallo existente de `totalSesiones`.
- `lib/screens/estadisticas.dart`: recarga ante notificaciones del repositorio,
  al volver a primer plano y desde el botón Actualizar. FutureBuilder oculta
  resultados previos durante la nueva carga e ignora respuestas de futures
  sustituidos, incluidos cambios de cuenta. Errores propagados muestran
  mensaje y Reintentar. Se eliminó la caché superficial de filtrado.
- Filtros obsoletos de sesión/temporada se eliminan realmente cuando ya no
  existen, coincidiendo con lo que muestra el selector. Los filtros por
  fecha se aplican al día de la sesión, ambos extremos incluidos. Últimos
  7/30/90 días incluyen hoy y 6/29/89 anteriores; no incluyen mañana.
- La tarjeta de temporada mantiene su comportamiento previo: temporada
  completa y tipo de sesión, sin fecha/sesión individual/límite N. Ahora
  lo explica expresamente. Temporada anterior significa anterior por
  última actividad, no necesariamente por año natural. No se modifica
  la gestión de temporadas ni su journal/respaldo.
- `lib/widgets/estadisticas/kpi_card_dinamico.dart`: permite indicador nulo.
  La pantalla no muestra flechas para valores absolutos ni umbrales fijos.
  Las diferencias reales entre temporadas conservan su comparación rotulada.
  Los restantes consumidores mantienen el comportamiento predeterminado.
- Títulos ajustables corrigen desbordamientos descubiertos en las pruebas
  de la pantalla. Mensajes nuevos traducidos a español e inglés en ARB
  y archivos generados de localización.

## Validación

`test/statistics_reliability_test.dart`: 14 pruebas nuevas (8 de motor y
6 de pantalla): ediciones con igual número de partidas, pines mutados,
cuentas/invitado, cronología invertida, fechas de partida y empates,
selección de últimas N, límites de fechas, filtros eliminados, sesiones
vacías, carga fallida/reintento, respuesta tardía de otra cuenta, cambio de
cuenta durante carga, edición notificada, alcance de temporada frente a
últimas 10, pantalla de 393 x 873 y cierre durante recarga.

```powershell
flutter test --no-pub test/statistics_reliability_test.dart test/estadisticas_cache_test.dart test/estadisticas_utils_test.dart test/utils/stats_filter_test.dart test/ball_stats_service_test.dart test/season_ui_test.dart test/game_entry_viewport_test.dart
flutter analyze --no-pub --no-fatal-infos lib/utils/estadisticas_cache.dart lib/utils/stats_selection.dart lib/screens/estadisticas.dart lib/widgets/estadisticas/kpi_card_dinamico.dart test/statistics_reliability_test.dart
```

La selección conjunta suma 89 pruebas; no se usan cuentas ni datos reales.
No se instala ninguna dependencia ni se genera una APK.

## Límites pendientes

- La capa existente de Firestore puede capturar errores de lectura y devolver
  una lista vacía; el repositorio también dispone de fallback local.
  Esta fase no modifica esos servicios ni certifica frescura del servidor.
  La nueva vista de error solo puede mostrar fallos que reciba. Distinguir
  de forma fiable datos de servidor, caché, fallback y fallo requiere un
  contrato explícito de procedencia en la capa de lectura en otra mejora.
- Sin suscripción Firestore en vivo: cambios desde otro dispositivo se ven
  al actualizar/volver al primer plano o notificar el repositorio.
- Las pruebas de red/cuentas de esta fase usan dobles. Falta validación
  manual en dispositivo; no se prueba producción.
- Permanecen avisos informativos preexistentes de `withOpacity` obsoleto.
- No se alteran fórmulas históricas de rachas, tratamiento de bonus del
  décimo frame ni criterio de completitud de las partidas. No se añaden
  nuevas métricas ni comparativas de periodos en esta fase.

## Prueba manual recomendada

1. Entrar con una cuenta de prueba, comprobar promedio y últimas partidas.
2. Editar una puntuación sin añadir/borrar partidas; regresar y actualizar.
3. Comparar últimas 10 con las diez más recientes de la lista de sesiones.
4. Aplicar temporada y últimas 10: el resumen completo y el conjunto filtrado
   pueden diferir; la nota debe explicar esa diferencia.
5. Cambiar a otra cuenta/invitado: no deben aparecer valores de la anterior.
6. Comprobar fechas personalizadas e inclusión del último día.
7. Salir al fondo y volver; comprobar recarga y desplazamiento en móvil.
   Sin red, revisar el comportamiento heredado de caché/local: ausencia de
   un error visible no confirma que el servidor esté actualizado.

No se modifican modelos, adaptadores Hive, respaldo del arsenal, reglas,
flags del catálogo, configuración Firebase ni Bolómetro Vision. Sin commits,
push, despliegues ni publicaciones.
