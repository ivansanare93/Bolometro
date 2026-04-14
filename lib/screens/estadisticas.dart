import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../repositories/data_repository.dart';
import '../services/analytics_service.dart';
import '../services/goal_service.dart';
import '../utils/estadisticas_utils.dart';
import '../utils/estadisticas_cache.dart';
import '../utils/app_constants.dart';
import '../utils/stats_filter.dart';
import '../theme/app_theme.dart';
import '../widgets/estadisticas/kpi_card_dinamico.dart';
import '../widgets/estadisticas/racha_card.dart';
import '../widgets/estadisticas/pastel_porcentajes.dart';
import '../widgets/estadisticas/top_partidas_widget.dart';
import '../widgets/estadisticas/mini_grafico_promedio_movil.dart';
import '../widgets/estadisticas/histograma_puntuaciones.dart';
import '../widgets/info_tooltip_icon.dart';
import 'home.dart';
import '../l10n/app_localizations.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/per_pin_heatmap.dart';

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
  bool _hasLoggedView = false;

  // Active filter state
  StatsFilter _filter = const StatsFilter();

  // Cache for filtered sessions to avoid recalculating on every build
  List<Sesion>? _cachedSesiones;
  List<Sesion>? _cachedFilteredSesiones;
  StatsFilter? _cachedFilter;

  // Goal / objective state
  double? _averageGoal;

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
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final goal = await GoalService.loadAverageGoal();
    if (mounted) {
      setState(() => _averageGoal = goal);
    }
  }

  void _cargarSesiones() {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    _sesionesFuture = dataRepository.obtenerSesiones();
  }

  // ---------------------------------------------------------------------------
  // Filtering logic
  // ---------------------------------------------------------------------------

  /// Returns the subset of [sesiones] that matches the active [_filter].
  ///
  /// Steps:
  /// 1. Filter by session type.
  /// 2. Filter by date range preset (or custom range).
  /// 3. Expand to individual games, sort by session date asc, then apply the
  ///    "last N games" limit to produce the final list of [Sesion]s (wrapped
  ///    so that stats calculations see only the limited games).
  List<Sesion> _getFilteredSesiones(List<Sesion> sesiones) {
    final sesionesSame = _cachedSesiones != null &&
        _cachedSesiones!.length == sesiones.length &&
        (_cachedSesiones!.isEmpty ||
            identical(_cachedSesiones!.first, sesiones.first));

    if (sesionesSame &&
        _cachedFilter == _filter &&
        _cachedFilteredSesiones != null) {
      return _cachedFilteredSesiones!;
    }

    List<Sesion> filtered = sesiones;

    // 1. Filter by tipo
    if (_filter.tipo != AppConstants.tipoTodos) {
      filtered = filtered.where((s) => s.tipo == _filter.tipo).toList();
    }

    // 2. Filter by date range
    final dateRange = _effectiveDateRange();
    if (dateRange != null) {
      final start = DateTime(
          dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final end = DateTime(
              dateRange.end.year, dateRange.end.month, dateRange.end.day)
          .add(const Duration(days: 1));
      filtered = filtered
          .where((s) =>
              !s.fecha.isBefore(start) && s.fecha.isBefore(end))
          .toList();
    }

    // 3. Apply "last N games" limit.
    //    Collect all games in chronological order, keep the last N, then
    //    reconstruct the session list so that only those games are included.
    final limit = _filter.lastN.limit;
    if (limit != null) {
      // Build flat list: (sesion, partida) sorted by sesion.fecha ascending.
      final sortedSesiones = List<Sesion>.from(filtered)
        ..sort((a, b) => a.fecha.compareTo(b.fecha));

      final allPairs = <(Sesion, Partida)>[];
      for (final s in sortedSesiones) {
        for (final p in s.partidas) {
          allPairs.add((s, p));
        }
      }

      final limited = allPairs.length > limit
          ? allPairs.sublist(allPairs.length - limit)
          : allPairs;

      // Rebuild minimal Sesion list preserving the original objects but with
      // only the selected games.
      final sesionToPartidas = <Sesion, List<Partida>>{};
      for (final (s, p) in limited) {
        sesionToPartidas.putIfAbsent(s, () => []).add(p);
      }
      filtered = sesionToPartidas.entries
          .map((e) => e.key.copyWith(partidas: e.value))
          .toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));
    }

    _cachedSesiones = sesiones;
    _cachedFilter = _filter;
    _cachedFilteredSesiones = filtered;

    return filtered;
  }

  /// Returns the effective [DateTimeRange] for the active preset, or null for
  /// [DateRangePreset.allTime].
  DateTimeRange? _effectiveDateRange() {
    final now = DateTime.now();
    switch (_filter.datePreset) {
      case DateRangePreset.allTime:
        return null;
      case DateRangePreset.last7Days:
        return DateTimeRange(
            start: now.subtract(const Duration(days: 7)), end: now);
      case DateRangePreset.last30Days:
        return DateTimeRange(
            start: now.subtract(const Duration(days: 30)), end: now);
      case DateRangePreset.last90Days:
        return DateTimeRange(
            start: now.subtract(const Duration(days: 90)), end: now);
      case DateRangePreset.thisMonth:
        return DateTimeRange(
            start: DateTime(now.year, now.month, 1), end: now);
      case DateRangePreset.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case DateRangePreset.custom:
        return _filter.customRange;
    }
  }

  // ---------------------------------------------------------------------------
  // L10n helpers
  // ---------------------------------------------------------------------------

  String _translateTipo(String tipo, AppLocalizations l10n) {
    if (tipo == AppConstants.tipoEntrenamiento) return l10n.training;
    if (tipo == AppConstants.tipoCompeticion) return l10n.competition;
    if (tipo == AppConstants.tipoTodos) return l10n.all;
    return tipo;
  }

  String _labelForPreset(DateRangePreset p, AppLocalizations l10n) {
    switch (p) {
      case DateRangePreset.allTime:
        return l10n.datePresetAllTime;
      case DateRangePreset.last7Days:
        return l10n.datePresetLast7Days;
      case DateRangePreset.last30Days:q
        return l10n.datePresetLast30Days;
      case DateRangePreset.last90Days:
        return l10n.datePresetLast90Days;
      case DateRangePreset.thisMonth:
        return l10n.datePresetThisMonth;
      case DateRangePreset.thisYear:
        return l10n.datePresetThisYear;
      case DateRangePreset.custom:
        return l10n.datePresetCustom;
    }
  }

  String _labelForLastN(LastNGames n, AppLocalizations l10n) {
    switch (n) {
      case LastNGames.all:
        return l10n.lastNAll;
      case LastNGames.last10:
        return l10n.lastN10;
      case LastNGames.last25:
        return l10n.lastN25;
      case LastNGames.last50:
        return l10n.lastN50;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
                _buildFilterBar(l10n, isDark),
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
          final stats = estadisticasCache.getEstadisticas(
            sesiones,
            filterKey: _filter.cacheKey,
          );

          // Log analytics after successful data load (only once)
          if (!_hasLoggedView) {
            _hasLoggedView = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              try {
                final analytics = Provider.of<AnalyticsService>(context, listen: false);
                analytics.logStatisticsViewed(_filter.cacheKey);
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

          // Insights: tendencia y consistencia
          final tendenciaDelta = stats['tendenciaDelta'] as double?;
          final consistencia = stats['consistencia'] as double;
          
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

          return CustomScrollView(
            slivers: [
              // ── FILTER BAR ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: _buildFilterBar(l10n, isDark),
                ),
              ),

              // ── STICKY KPI SUMMARY HEADER ────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _KpiStickyDelegate(
                  minHeight: 96,
                  maxHeight: 96,
                  child: _buildKpiStickyBar(
                    promedio: promedio,
                    mejor: mejor,
                    peor: peor,
                    totalPartidas: partidas.length,
                    tendenciaDelta: tendenciaDelta,
                    consistencia: consistencia,
                    isDark: isDark,
                    l10n: l10n,
                  ),
                ),
              ),

              // ── MAIN CONTENT ─────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 14),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── SECCIÓN 1: ESTADÍSTICAS GENERALES ──────────────────
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
                                esSubida: promedio >= promedioUlt10,
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
                                value: '$mejor',
                                icon: Icons.emoji_events_rounded,
                                color: Colors.green[600]!,
                                esSubida: true,
                              ),
                              KpiCardDinamico(
                                label: AppLocalizations.of(context)!.worst,
                                value: '$peor',
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
                        porcentajeStrikes: porcentajes['strikes']!,
                        porcentajeSpares: porcentajes['spares']!,
                        porcentajeFallos: porcentajes['fallos']!,
                      ),

                      // ── SECCIÓN 2: EVOLUCIÓN Y DISTRIBUCIÓN ────────────────
                      const SizedBox(height: 8),
                      _buildSectionHeader(
                        title: l10n.statsEvolutionSection,
                        icon: Icons.show_chart_rounded,
                        color: Colors.purple[600]!,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.recentEvolution,
                            style: TextStyle(
                              fontSize: 13,
                              color: greyColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InfoTooltipIcon(
                              message: l10n.tooltipMovingAverage),
                        ],
                      ),
                      const SizedBox(height: 3),
                      MiniGraficoPromedioMovil(promedios: miniPromedios),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.scoreDistribution,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          InfoTooltipIcon(
                              message: l10n.tooltipHistogram),
                        ],
                      ),
                      Text(
                        AppLocalizations.of(context)!.gamesGroupedByRange,
                        style: TextStyle(fontSize: 12, color: greyColor),
                      ),
                      const SizedBox(height: 4),
                      HistogramaPuntuaciones(histograma: histograma),

                      // ── SECCIÓN 3: MEJORES Y PEORES ────────────────────────
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
                                Icon(Icons.star,
                                    color: Colors.green[400], size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${AppLocalizations.of(context)!.personalRecord}\n${AppLocalizations.of(context)!.gamesWithAverage(sesionRecord.partidas.length, _formatearFechaCorta(sesionRecord.fecha), EstadisticasUtils.promedioSesion(sesionRecord).toStringAsFixed(1))}',
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
                                    '${AppLocalizations.of(context)!.worstSession} ${AppLocalizations.of(context)!.gamesWithAverage(sesionPeor.partidas.length, _formatearFechaCorta(sesionPeor.fecha), EstadisticasUtils.promedioSesion(sesionPeor).toStringAsFixed(1))}',
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

                      // ── SECCIÓN 4: ESTADÍSTICAS DE PINES ──────────────────
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
                                    label: AppLocalizations.of(context)!
                                        .firstBallAvg,
                                    value: promedioPrimerTiro
                                        .toStringAsFixed(1),
                                    icon: Icons.looks_one_rounded,
                                    color: Colors.teal[600]!,
                                    esSubida: promedioPrimerTiro >=
                                        _kGoodFirstBallAverage,
                                  ),
                                if (tasaConversionSpare != null)
                                  KpiCardDinamico(
                                    label: AppLocalizations.of(context)!
                                        .spareConversionRate,
                                    value:
                                        '${tasaConversionSpare.toStringAsFixed(1)}%',
                                    icon: Icons.adjust_rounded,
                                    color: Colors.deepOrange[600]!,
                                    esSubida: tasaConversionSpare >=
                                        _kGoodSpareConversionRate,
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
                            tooltipText: l10n.tooltipSpareConversion,
                          ),
                          const SizedBox(height: 4),
                          PerPinHeatmap(
                            data: buildPerPinHeatmapData(
                                conversionSparePorPin),
                          ),
                          const SizedBox(height: 8),
                          _buildPerPinSpareTable(
                              conversionSparePorPin, l10n),
                        ],
                      ],
                      const SizedBox(height: 20),

                      // ── SECCIÓN 5: METAS ──────────────────────────────────
                      _buildSectionHeader(
                        title: l10n.goalSection,
                        icon: Icons.flag_rounded,
                        color: Colors.indigo[600]!,
                        tooltipText: l10n.goalTooltip,
                      ),
                      _buildGoalSection(promedio, l10n, isDark),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatearFechaCorta(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
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

  // ---------------------------------------------------------------------------
  // Helper methods
  // ---------------------------------------------------------------------------

  /// Goal / meta section: progress bar toward the configured average goal.
  Widget _buildGoalSection(
      double promedio, AppLocalizations l10n, bool isDark) {
    final cardBg = isDark ? Colors.grey[850]! : Colors.grey[50]!;
    final goal = _averageGoal;

    return Card(
      color: cardBg,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: Colors.indigo[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.goalSection,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  tooltip: l10n.goalEditTitle,
                  onPressed: () => _showGoalDialog(l10n),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (goal == null)
              Text(
                l10n.goalSetPrompt,
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54),
              )
            else ...[
              // Progress bar
              Builder(builder: (context) {
                final progress = (promedio / goal).clamp(0.0, 1.0);
                final achieved = promedio >= goal;
                final remaining = goal - promedio;
                final color = achieved ? Colors.green[600]! : Colors.indigo[400]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l10n.stickyKpiAverage}: ${promedio.toStringAsFixed(1)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${l10n.goalSection}: ${goal.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: color.withOpacity(0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achieved
                          ? l10n.goalAchieved
                          : l10n.goalProgress(
                              remaining.toStringAsFixed(1)),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Shows a dialog to edit the average goal.
  Future<void> _showGoalDialog(AppLocalizations l10n) async {
    final controller = TextEditingController(
      text: _averageGoal?.toStringAsFixed(0) ??
          GoalService.defaultAverageGoal.toStringAsFixed(0),
    );
    String? errorText;

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(l10n.goalEditTitle),
              content: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: l10n.goalEditHint,
                  errorText: errorText,
                ),
                autofocus: true,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () async {
                    final value = double.tryParse(controller.text.trim());
                    if (value == null ||
                        value < GoalService.minAverageGoal ||
                        value > GoalService.maxAverageGoal) {
                      setDialogState(() => errorText = l10n.goalEditInvalid);
                      return;
                    }
                    await GoalService.saveAverageGoal(value);
                    if (mounted) {
                      setState(() => _averageGoal = value);
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          });
        },
      );
    } finally {
      controller.dispose();
    }
  }

  /// Full filter bar: session type + date range presets + last-N-games chips.
  Widget _buildFilterBar(AppLocalizations l10n, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withOpacity(0.38),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(isDark ? 0.13 : 0.06),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: session type ────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.filter_list_rounded, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.filter,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: onSurface.withOpacity(0.84),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filter.tipo,
                    borderRadius: BorderRadius.circular(12),
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: primary),
                    dropdownColor: isDark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    items: AppConstants.tiposSesionConTodos
                        .map(
                          (tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(
                              _translateTipo(tipo, l10n),
                              style: TextStyle(
                                color: onSurface.withOpacity(
                                  tipo == _filter.tipo ? 1.0 : 0.72,
                                ),
                                fontWeight: tipo == _filter.tipo
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(
                      () => _filter = _filter.copyWith(
                        tipo: v ?? AppConstants.tipoTodos,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Row 2: date range presets ──────────────────────────────────
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${l10n.filterDateRange}:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final preset in DateRangePreset.values)
                        _DateChip(
                          label: _labelForPreset(preset, l10n),
                          selected: _filter.datePreset == preset,
                          onTap: () async {
                            if (preset == DateRangePreset.custom) {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                initialDateRange: _filter.customRange,
                                helpText: l10n.selectDateRange,
                                builder: (ctx, child) => Theme(
                                  data: Theme.of(ctx),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setState(
                                  () => _filter = _filter.copyWith(
                                    datePreset: DateRangePreset.custom,
                                    customRange: picked,
                                  ),
                                );
                              }
                            } else {
                              setState(
                                () => _filter = _filter.copyWith(
                                  datePreset: preset,
                                  clearCustomRange: true,
                                ),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Row 3: last-N-games ────────────────────────────────────────
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${l10n.filterLastNGames}:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final n in LastNGames.values)
                        _DateChip(
                          label: _labelForLastN(n, l10n),
                          selected: _filter.lastN == n,
                          onTap: () => setState(
                            () => _filter = _filter.copyWith(lastN: n),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sticky KPI summary bar – 6 metrics in 2 rows of 3.
  ///
  /// Row 1: Average, Best, Worst
  /// Row 2: Games, Trend, Consistency
  Widget _buildKpiStickyBar({
    required double promedio,
    required int mejor,
    required int peor,
    required int totalPartidas,
    required double? tendenciaDelta,
    required double consistencia,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    final bg = Theme.of(context).colorScheme.surface.withOpacity(0.97);

    // Format trend value and pick color
    final String trendValue;
    final Color trendColor;
    if (tendenciaDelta == null) {
      trendValue = l10n.trendNotAvailable;
      trendColor = Colors.grey[500]!;
    } else {
      final sign = tendenciaDelta >= 0 ? '+' : '';
      trendValue = '$sign${tendenciaDelta.toStringAsFixed(1)}';
      trendColor = tendenciaDelta >= 0 ? Colors.green[600]! : Colors.red[400]!;
    }

    return Material(
      elevation: 2,
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Row 1: Average, Best, Worst
            Row(
              children: [
                _StickyKpi(
                  label: l10n.stickyKpiAverage,
                  value: promedio.toStringAsFixed(1),
                  icon: Icons.bar_chart_rounded,
                  color: Colors.blue[700]!,
                ),
                _StickyKpi(
                  label: l10n.stickyKpiBest,
                  value: '$mejor',
                  icon: Icons.emoji_events_rounded,
                  color: Colors.green[600]!,
                ),
                _StickyKpi(
                  label: l10n.stickyKpiWorst,
                  value: '$peor',
                  icon: Icons.sentiment_dissatisfied_rounded,
                  color: Colors.red[400]!,
                ),
              ],
            ),
            // Row 2: Games, Trend, Consistency
            Row(
              children: [
                _StickyKpi(
                  label: l10n.stickyKpiGames,
                  value: '$totalPartidas',
                  icon: Icons.sports_score_rounded,
                  color: Colors.purple[600]!,
                ),
                _StickyKpiWithTooltip(
                  label: l10n.stickyKpiTrend,
                  value: trendValue,
                  icon: tendenciaDelta == null
                      ? Icons.trending_neutral_rounded
                      : (tendenciaDelta >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded),
                  color: trendColor,
                  tooltip: l10n.tooltipTrend,
                ),
                _StickyKpiWithTooltip(
                  label: l10n.stickyKpiConsistency,
                  value: consistencia.toStringAsFixed(1),
                  icon: Icons.show_chart_rounded,
                  color: Colors.teal[600]!,
                  tooltip: l10n.tooltipConsistency,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    String? tooltipText,
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
          if (tooltipText != null) ...[
            const SizedBox(width: 4),
            InfoTooltipIcon(message: tooltipText, color: color.withOpacity(0.6)),
          ],
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

// ── Helper delegate for the pinned KPI sliver ────────────────────────────────

class _KpiStickyDelegate extends SliverPersistentHeaderDelegate {
  const _KpiStickyDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_KpiStickyDelegate oldDelegate) {
    return oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight ||
        oldDelegate.child != child;
  }
}

// ── Compact KPI tile used in the sticky header ───────────────────────────────

class _StickyKpi extends StatelessWidget {
  const _StickyKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Compact KPI tile with tooltip ─────────────────────────────────────────────

class _StickyKpiWithTooltip extends StatelessWidget {
  const _StickyKpiWithTooltip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.tooltip,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small chip used in the filter rows ──────────────────────────────────────

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.primary.withOpacity(0.30),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
        ),
      ),
    );
  }
}
