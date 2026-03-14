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
  // Thresholds for pin-based stat directional indicators
  static const double _kGoodFirstBallAverage = 6.0;
  static const double _kGoodSpareConversionRate = 50.0;

  late Future<List<Sesion>> _sesionesFuture;
  String _filtroTipo = AppConstants.tipoTodos;
  bool _hasLoggedView = false;
  
  // Cache for filtered sessions to avoid recalculating on every build
  List<Sesion>? _cachedSesiones;
  List<Sesion>? _cachedFilteredSesiones;
  String? _cachedFiltroTipo;

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
  
  List<Sesion> _getFilteredSesiones(List<Sesion> sesiones) {
    // Return cached result if filters haven't changed and data is the same
    final sesionesSame = _cachedSesiones != null && 
                         _cachedSesiones!.length == sesiones.length &&
                         (_cachedSesiones!.isEmpty || 
                          _cachedSesiones!.first == sesiones.first);
    
    if (sesionesSame &&
        _cachedFiltroTipo == _filtroTipo &&
        _cachedFilteredSesiones != null) {
      return _cachedFilteredSesiones!;
    }
    
    // Apply filters
    List<Sesion> filtered = sesiones;
    if (_filtroTipo != AppConstants.tipoTodos) {
      filtered = filtered.where((s) => s.tipo == _filtroTipo).toList();
    }
    
    // Cache the result
    _cachedSesiones = sesiones;
    _cachedFiltroTipo = _filtroTipo;
    _cachedFilteredSesiones = filtered;
    
    return filtered;
  }

  String _translateTipo(String tipo, AppLocalizations l10n) {
    if (tipo == AppConstants.tipoEntrenamiento) return l10n.training;
    if (tipo == AppConstants.tipoCompeticion) return l10n.competition;
    if (tipo == AppConstants.tipoTodos) return l10n.all;
    return tipo;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fullStatistics),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: AppLocalizations.of(context)!.home,
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
          final sesiones = _getFilteredSesiones(snapshot.data!);
          
          final partidas = sesiones.expand((s) => s.partidas).toList();
          
          // Extract theme colors for the filter
          final isDark = Theme.of(context).brightness == Brightness.dark;
          
          if (partidas.isEmpty) {
            return Column(
              children: [
                // Filtro visual optimizado - Fixed at the top
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Theme.of(context).colorScheme.surface : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.38),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.13 : 0.06),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.filter,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.84),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filtroTipo,
                              borderRadius: BorderRadius.circular(12),
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                              dropdownColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              items: AppConstants.tiposSesionConTodos
                                  .map(
                                    (tipo) => DropdownMenuItem(
                                      value: tipo,
                                      child: Text(
                                        _translateTipo(tipo, l10n),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(
                                            tipo == _filtroTipo ? 1.0 : 0.72,
                                          ),
                                          fontWeight: tipo == _filtroTipo
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                setState(() {
                                  _filtroTipo = v ?? AppConstants.tipoTodos;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Centered "no data" message
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppLocalizations.of(context)!.noDataForStatistics,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ),
              ],
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
          final miniPromedios = stats['promedioMovil'] as List<double>;
          final sesionRecord = stats['sesionRecord'] as Sesion?;
          final sesionPeor = stats['sesionPeor'] as Sesion?;

          // Estadísticas de pines (solo disponibles con el teclado visual)
          final promedioPrimerTiro = stats['promedioPrimerTiro'] as double?;
          final tasaConversionSpare = stats['tasaConversionSpare'] as double?;
          final conversionSparePorPin = stats['conversionSparePorPin'] as Map<String, List<int>>? ?? {};
          final hayEstadisticasPines = promedioPrimerTiro != null || tasaConversionSpare != null;
          
          // Extract theme colors once to avoid repeated lookups
          final greyColor = Colors.grey[700];
          final recordCardColor = isDark
              ? AppTheme.recordCardDark.withOpacity(AppTheme.cardOpacity)
              : AppTheme.recordCardLight;
          final worstCardColor = isDark
              ? AppTheme.worstCardDark.withOpacity(AppTheme.worstCardOpacity)
              : AppTheme.worstCardLight;
          final textCardColor = isDark
              ? Colors.white.withOpacity(AppTheme.textCardOpacity)
              : Colors.black87;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
            children: [
              // Filtro visual optimizado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Theme.of(context).colorScheme.surface : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.38),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(isDark ? 0.13 : 0.06),
                        blurRadius: 7,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.filter,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.84),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filtroTipo,
                            borderRadius: BorderRadius.circular(12),
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                            dropdownColor: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            items: AppConstants.tiposSesionConTodos
                                .map(
                                  (tipo) => DropdownMenuItem(
                                    value: tipo,
                                    child: Text(
                                      _translateTipo(tipo, l10n),
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(
                                          tipo == _filtroTipo ? 1.0 : 0.72,
                                        ),
                                        fontWeight: tipo == _filtroTipo
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _filtroTipo = v ?? AppConstants.tipoTodos;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── SECCIÓN 1: ESTADÍSTICAS GENERALES ──────────────────────────
              _buildSectionHeader(
                title: l10n.statsGeneralSection,
                icon: Icons.bar_chart_rounded,
                color: Colors.blue[700]!,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.quickScoreSummary,
                style: TextStyle(fontSize: 12, color: greyColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              RepaintBoundary(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      KpiCardDinamico(
                        label: AppLocalizations.of(context)!.average,
                        value: promedio.toStringAsFixed(1),
                        icon: Icons.bar_chart_rounded,
                        color: Colors.blue[700]!,
                        esSubida: promedio >= promedioUlt10, // comparación básica
                      ),
                      KpiCardDinamico(
                        label: AppLocalizations.of(context)!.averageLast5,
                        value: promedioUlt5.toStringAsFixed(1),
                        icon: Icons.trending_up_rounded,
                        color: Colors.purple[600]!,
                        esSubida: promedioUlt5 > promedioUlt10,
                      ),
                      KpiCardDinamico(
                        label: AppLocalizations.of(context)!.best,
                        value: "$mejor",
                        icon: Icons.emoji_events_rounded,
                        color: Colors.green[600]!,
                        esSubida: true,
                      ),
                      KpiCardDinamico(
                        label: AppLocalizations.of(context)!.worst,
                        value: "$peor",
                        icon: Icons.sentiment_dissatisfied_rounded,
                        color: Colors.red[400]!,
                        esSubida: false,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RachaBadge(
                    label: AppLocalizations.of(context)!.strikes,
                    valor: rachaStrike,
                    icon: Icons.flash_on,
                    color: Colors.blue[700]!,
                  ),
                  RachaBadge(
                    label: AppLocalizations.of(context)!.spares,
                    valor: rachaSpare,
                    icon: Icons.bolt,
                    color: Colors.green[600]!,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.longestStreakDescription,
                style: TextStyle(fontSize: 12, color: greyColor),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context)!.percentageStrikesSparesMisses,
                style: TextStyle(
                  fontSize: 13,
                  color: greyColor,
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

              // ── SECCIÓN 2: EVOLUCIÓN Y DISTRIBUCIÓN ───────────────────────
              const SizedBox(height: 8),
              _buildSectionHeader(
                title: l10n.statsEvolutionSection,
                icon: Icons.show_chart_rounded,
                color: Colors.purple[600]!,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.recentEvolution,
                style: TextStyle(
                  fontSize: 13,
                  color: greyColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              MiniGraficoPromedioMovil(promedios: miniPromedios),

              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.scoreDistribution,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                AppLocalizations.of(context)!.gamesGroupedByRange,
                style: TextStyle(fontSize: 12, color: greyColor),
              ),
              const SizedBox(height: 4),
              HistogramaPuntuaciones(histograma: histograma),

              // ── SECCIÓN 3: MEJORES Y PEORES ────────────────────────────────
              const SizedBox(height: 8),
              _buildSectionHeader(
                title: l10n.statsBestWorstSection,
                icon: Icons.emoji_events_rounded,
                color: Colors.orange[700]!,
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.topBestWorstGames,
                style: TextStyle(
                  fontSize: 13,
                  color: greyColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              TopPartidasWidget(
                partidas: top3,
                titulo: AppLocalizations.of(context)!.top3BestGames,
                color: Colors.indigo,
              ),
              TopPartidasWidget(
                partidas: peores3,
                titulo: AppLocalizations.of(context)!.top3WorstGames,
                color: Colors.red,
              ),

              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.bestWorstSessionDescription,
                style: TextStyle(fontSize: 12, color: greyColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
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
                            "${AppLocalizations.of(context)!.personalRecord}\n${AppLocalizations.of(context)!.gamesWithAverage(sesionRecord.partidas.length, _formatearFechaCorta(sesionRecord.fecha), EstadisticasUtils.promedioSesion(sesionRecord).toStringAsFixed(1))}",
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
                            "${AppLocalizations.of(context)!.worstSession} ${AppLocalizations.of(context)!.gamesWithAverage(sesionPeor.partidas.length, _formatearFechaCorta(sesionPeor.fecha), EstadisticasUtils.promedioSesion(sesionPeor).toStringAsFixed(1))}",
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

              // ── SECCIÓN 4: ESTADÍSTICAS DE PINES ──────────────────────────
              if (hayEstadisticasPines) ...[
                const SizedBox(height: 8),
                _buildSectionHeader(
                  title: l10n.pinStatsSection,
                  icon: Icons.adjust_rounded,
                  color: Colors.teal[600]!,
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.pinStatsNote,
                  style: TextStyle(fontSize: 11, color: greyColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                RepaintBoundary(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (promedioPrimerTiro != null)
                          KpiCardDinamico(
                            label: AppLocalizations.of(context)!.firstBallAvg,
                            value: promedioPrimerTiro.toStringAsFixed(1),
                            icon: Icons.looks_one_rounded,
                            color: Colors.teal[600]!,
                            esSubida: promedioPrimerTiro >= _kGoodFirstBallAverage,
                          ),
                        if (tasaConversionSpare != null)
                          KpiCardDinamico(
                            label: AppLocalizations.of(context)!.spareConversionRate,
                            value: '${tasaConversionSpare.toStringAsFixed(1)}%',
                            icon: Icons.adjust_rounded,
                            color: Colors.deepOrange[600]!,
                            esSubida: tasaConversionSpare >= _kGoodSpareConversionRate,
                          ),
                      ],
                    ),
                  ),
                ),
                if (conversionSparePorPin.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSectionHeader(
                    title: l10n.perPinSpareStats,
                    icon: Icons.pin_drop_rounded,
                    color: Colors.deepOrange[600]!,
                  ),
                  const SizedBox(height: 4),
                  _buildPerPinSpareTable(conversionSparePorPin, l10n),
                ],
              ],
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

  /// Builds a compact table showing per-pin spare conversion stats.
  /// Entries are sorted by number of attempts (descending) so the most
  /// common leaves appear first.
  Widget _buildPerPinSpareTable(
    Map<String, List<int>> conversionPorPin,
    AppLocalizations l10n,
  ) {
    // Sort by attempts descending, then by leave key ascending for ties
    final sortedEntries = conversionPorPin.entries.toList()
      ..sort((a, b) {
        final cmp = b.value[0].compareTo(a.value[0]);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Card(
      color: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          children: sortedEntries.map((entry) {
            final leave = entry.key;
            final attempts = entry.value[0];
            final converted = entry.value[1];
            final pct = attempts > 0 ? (converted / attempts * 100) : 0.0;
            final isGood = pct >= _kGoodSpareConversionRate;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.perPinLeaveLabel(leave),
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.perPinConversionValue(converted, attempts),
                      style: TextStyle(fontSize: 13, color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isGood ? Colors.green[600] : Colors.deepOrange[600],
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: color.withOpacity(0.35),
              thickness: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
