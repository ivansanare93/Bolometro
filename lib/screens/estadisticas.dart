import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../repositories/data_repository.dart';
import '../services/analytics_service.dart';
import '../utils/estadisticas_utils.dart';
import '../utils/estadisticas_cache.dart';
import '../utils/app_constants.dart';
import '../theme/app_theme.dart';
import '../widgets/estadisticas/kpi_card_dinamico.dart';
import '../widgets/estadisticas/racha_card.dart';
import '../widgets/estadisticas/pastel_porcentajes.dart';
import '../widgets/estadisticas/top_partidas_widget.dart';
import '../widgets/estadisticas/mini_grafico_promedio_movil.dart';
import '../widgets/estadisticas/histograma_puntuaciones.dart';
import 'home.dart';
import '../l10n/app_localizations.dart';
import '../widgets/skeleton_loaders.dart';

class EstadisticasPantallaCompleta extends StatefulWidget {
  const EstadisticasPantallaCompleta({super.key});

  @override
  State<EstadisticasPantallaCompleta> createState() =>
      _EstadisticasPantallaCompletaState();
}

class _EstadisticasPantallaCompletaState
    extends State<EstadisticasPantallaCompleta> {
  late Future<List<Sesion>> _sesionesFuture;
  String _filtroTipo = AppConstants.tipoTodos;
  DateTimeRange? _rangoFechas;
  bool _hasLoggedView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('statistics_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
    _cargarSesiones();
  }

  void _cargarSesiones() {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    _sesionesFuture = dataRepository.obtenerSesiones();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores personalizados para las tarjetas en función del modo
    final recordCardColor = isDark
        ? AppTheme.recordCardDark.withOpacity(AppTheme.cardOpacity)
        : AppTheme.recordCardLight;
    final worstCardColor = isDark
        ? AppTheme.worstCardDark.withOpacity(AppTheme.worstCardOpacity)
        : AppTheme.worstCardLight;
    final textCardColor = isDark
        ? Colors.white.withOpacity(AppTheme.textCardOpacity)
        : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.fullStatistics),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: "Inicio",
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Sesion>>(
        future: _sesionesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: StatisticsCardSkeleton()),
                      Expanded(child: StatisticsCardSkeleton()),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: StatisticsCardSkeleton()),
                      Expanded(child: StatisticsCardSkeleton()),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(child: StatisticsCardSkeleton()),
                      Expanded(child: StatisticsCardSkeleton()),
                    ],
                  ),
                  ChartSkeleton(height: 250),
                  ChartSkeleton(height: 200),
                ],
              ),
            );
          }

          // --- Filtros por tipo y fecha ---
          List<Sesion> sesiones = snapshot.data!;
          if (_filtroTipo != AppConstants.tipoTodos) {
            sesiones = sesiones.where((s) => s.tipo == _filtroTipo).toList();
          }
          if (_rangoFechas != null) {
            sesiones = EstadisticasUtils.filtrarSesionesPorFecha(
              sesiones,
              _rangoFechas!.start,
              _rangoFechas!.end,
            );
          }

          final partidas = sesiones.expand((s) => s.partidas).toList();
          if (partidas.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FiltrosEstadisticas(
                      filtroTipo: _filtroTipo,
                      onTipoChanged: (valor) =>
                          setState(() => _filtroTipo = valor ?? AppConstants.tipoTodos),
                      rangoFechas: _rangoFechas,
                      onFechaChanged: (nuevoRango) =>
                          setState(() => _rangoFechas = nuevoRango),
                    ),
                    const SizedBox(height: 38),
                    Text(
                      AppLocalizations.of(context)!.noDataForStatistics,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ],
                ),
              ),
            );
          }

          // Usar cache de estadísticas (provider registrado en main.dart)
          final estadisticasCache = Provider.of<EstadisticasCache>(context, listen: false);
          final stats = estadisticasCache.getEstadisticas(sesiones);

          // Log analytics after successful data load (only once)
          if (!_hasLoggedView) {
            _hasLoggedView = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logStatisticsViewed('all');
              } catch (e) {
                debugPrint('Error logging statistics view: $e');
              }
            });
          }

          // --- OBTENER DATOS DEL CACHE ---
          final promedio = stats['promedioGeneral'] as double;
          final promedioUlt5 = stats['promedioUltimas5'] as double;
          final promedioUlt10 = stats['promedioUltimas10'] as double;
          final mejor = (stats['mejorPartida'] as Partida?)?.total ?? 0;
          final peor = (stats['peorPartida'] as Partida?)?.total ?? 0;
          final mejorEntrenamiento = stats['mejorEntrenamiento'] as int;
          final mejorCompeticion = stats['mejorCompeticion'] as int;
          final rachaStrike = stats['rachaStrikes'] as int;
          final rachaSpare = stats['rachaSpares'] as int;
          final porcentajes = stats['porcentajes'] as Map<String, double>;
          
          // Las listas ya vienen limitadas del cache
          final topMejores = stats['topMejores'] as List<Partida>;
          final topPeores = stats['topPeores'] as List<Partida>;
          
          // Tomar solo los primeros N para mostrar
          final top3 = topMejores.take(AppConstants.topNPartidas).toList();
          final peores3 = topPeores.take(AppConstants.topNPartidas).toList();
          
          final histograma = stats['histograma'] as Map<String, int>;
          final miniPromedios = EstadisticasUtils.promedioMovil(partidas, AppConstants.ventanaPromedioMovil);
          final sesionRecord = stats['sesionRecord'] as Sesion?;
          final sesionPeor = stats['sesionPeor'] as Sesion?;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
            children: [
              // Filtros arriba
              _FiltrosEstadisticas(
                filtroTipo: _filtroTipo,
                onTipoChanged: (valor) =>
                    setState(() => _filtroTipo = valor ?? AppConstants.tipoTodos),
                rangoFechas: _rangoFechas,
                onFechaChanged: (nuevoRango) =>
                    setState(() => _rangoFechas = nuevoRango),
              ),
              const SizedBox(height: 18),

              // --- KPIs y tarjetas principales ---
              Text(
                "Resumen rápido de tus puntuaciones",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    KpiCardDinamico(
                      label: "Promedio",
                      value: promedio.toStringAsFixed(1),
                      icon: Icons.bar_chart_rounded,
                      color: Colors.blue[700]!,
                      esSubida: promedio >= promedioUlt10, // comparación básica
                    ),
                    KpiCardDinamico(
                      label: "Prom. Últ. 5",
                      value: promedioUlt5.toStringAsFixed(1),
                      icon: Icons.trending_up_rounded,
                      color: Colors.purple[600]!,
                      esSubida: promedioUlt5 > promedioUlt10,
                    ),
                    KpiCardDinamico(
                      label: "Mejor",
                      value: "$mejor",
                      icon: Icons.emoji_events_rounded,
                      color: Colors.green[600]!,
                      esSubida: true,
                    ),
                    KpiCardDinamico(
                      label: "Peor",
                      value: "$peor",
                      icon: Icons.sentiment_dissatisfied_rounded,
                      color: Colors.red[400]!,
                      esSubida: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RachaBadge(
                    label: "Strikes",
                    valor: rachaStrike,
                    icon: Icons.flash_on,
                    color: Colors.blue[700]!,
                  ),
                  RachaBadge(
                    label: "Spares",
                    valor: rachaSpare,
                    icon: Icons.bolt,
                    color: Colors.green[600]!,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Mayor número de strikes y spares consecutivos en todas tus partidas.",
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),
              Text(
                "Porcentaje de Strikes, Spares y Fallos",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              PastelPorcentajes(
                porcentajeStrikes: porcentajes["strikes"]!,
                porcentajeSpares: porcentajes["spares"]!,
                porcentajeFallos: porcentajes["fallos"]!,
              ),

              const SizedBox(height: 16),
              Text(
                "Evolución reciente (media móvil de tus últimas 5 partidas)",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              MiniGraficoPromedioMovil(promedios: miniPromedios),

              const SizedBox(height: 18),
              Text(
                "Distribución de puntuaciones",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                "Número de partidas agrupadas por rango de puntuación",
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              HistogramaPuntuaciones(histograma: histograma),

              const SizedBox(height: 24),
              Text(
                "Tus 3 mejores y peores partidas individuales registradas",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              TopPartidasWidget(
                partidas: top3,
                titulo: "Top 3 Mejores Partidas",
                color: Colors.indigo,
              ),
              TopPartidasWidget(
                partidas: peores3,
                titulo: "Top 3 Peores Partidas",
                color: Colors.red,
              ),

              const SizedBox(height: 24),
              Text(
                "Sesión con mejor promedio (récord) y peor sesión",
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              if (sesionRecord != null)
                Card(
                  color: recordCardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.green[400], size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "¡Récord personal!\n${sesionRecord.partidas.length} partidas el ${_formatearFechaCorta(sesionRecord.fecha)}. Prom: ${EstadisticasUtils.promedioSesion(sesionRecord).toStringAsFixed(1)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textCardColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (sesionPeor != null)
                Card(
                  color: worstCardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[300],
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Peor sesión: ${sesionPeor.partidas.length} partidas el ${_formatearFechaCorta(sesionPeor.fecha)}. Prom: ${EstadisticasUtils.promedioSesion(sesionPeor).toStringAsFixed(1)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textCardColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  String _formatearFechaCorta(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}";
  }
}

// --------------- FILTROS -------------------
class _FiltrosEstadisticas extends StatelessWidget {
  final String filtroTipo;
  final ValueChanged<String?> onTipoChanged;
  final DateTimeRange? rangoFechas;
  final ValueChanged<DateTimeRange?> onFechaChanged;

  const _FiltrosEstadisticas({
    required this.filtroTipo,
    required this.onTipoChanged,
    required this.rangoFechas,
    required this.onFechaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Filtro tipo
        DropdownButton<String>(
          value: filtroTipo,
          borderRadius: BorderRadius.circular(12),
          items: AppConstants.tiposSesionConTodos
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onTipoChanged,
        ),
        const SizedBox(width: 18),
        // Filtro fecha
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range, size: 18),
          label: Text(
            rangoFechas == null
                ? 'Filtrar por fecha'
                : "${rangoFechas!.start.day.toString().padLeft(2, '0')}/${rangoFechas!.start.month.toString().padLeft(2, '0')} - ${rangoFechas!.end.day.toString().padLeft(2, '0')}/${rangoFechas!.end.month.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 14),
          ),
          onPressed: () async {
            final hoy = DateTime.now();
            final picked = await showDateRangePicker(
              context: context,
              initialDateRange:
                  rangoFechas ??
                  DateTimeRange(
                    start: DateTime(hoy.year, hoy.month, 1),
                    end: hoy,
                  ),
              firstDate: DateTime(2000, 1, 1),
              lastDate: hoy,
              builder: (context, child) {
                return Theme(data: Theme.of(context), child: child!);
              },
            );
            onFechaChanged(picked);
          },
        ),
        if (rangoFechas != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 17),
            onPressed: () => onFechaChanged(null),
            tooltip: 'Quitar filtro fecha',
          ),
      ],
    );
  }
}
