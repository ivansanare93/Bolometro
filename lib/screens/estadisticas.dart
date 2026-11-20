import '../widgets/estadisticas/statistics_analysis_panel.dart';
import '../utils/stats_selection.dart';
import '../utils/statistics_samples.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../repositories/data_repository.dart';
import '../services/analytics_service.dart';
import '../utils/estadisticas_utils.dart';
import '../utils/estadisticas_cache.dart';
import '../utils/app_constants.dart';
import '../utils/stats_filter.dart';
import '../widgets/estadisticas/kpi_card_dinamico.dart';
import '../widgets/estadisticas/racha_card.dart';
import '../widgets/estadisticas/pastel_porcentajes.dart';
import '../widgets/estadisticas/top_partidas_widget.dart';
import '../widgets/estadisticas/statistics_score_chart.dart';
import '../widgets/estadisticas/histograma_puntuaciones.dart';
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
    extends State<EstadisticasPantallaCompleta>
    with WidgetsBindingObserver {
  static const String _allSessionsFilterValue = '__all_sessions__';
  static const String _allSeasonsFilterValue = '__all_seasons__';

  // Display threshold for per-pin conversion percentages (not a trend).
  static const double _kGoodSpareConversionRate = 50.0;

  late Future<List<Sesion>> _sesionesFuture;
  bool _hasLoggedView = false;

  // Active filter state
  StatsFilter _filter = const StatsFilter();
  Map<String, String> _ballNames = {};
  int _ballNameRequest = 0;
  bool _statisticsAccountBound = false;
  String? _statisticsUid;
  int? _statisticsAccountToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final analytics = Provider.of<AnalyticsService>(context, listen: false);
        analytics.logScreenView('statistics_screen');
      } catch (e) {
        debugPrint('Error logging screen view: $e');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depend on repository notifications, including edits, sync and account changes.
    Provider.of<DataRepository>(context);
    _cargarSesiones();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(_cargarSesiones);
    try {
      await _sesionesFuture;
    } catch (_) {
      /* Rendered by FutureBuilder. */
    }
  }

  void _cargarSesiones() {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);
    if (!_statisticsAccountBound ||
        _statisticsUid != dataRepository.arsenalUserId ||
        _statisticsAccountToken != dataRepository.seasonAccountToken) {
      _filter = const StatsFilter();
      _statisticsUid = dataRepository.arsenalUserId;
      _statisticsAccountToken = dataRepository.seasonAccountToken;
      _statisticsAccountBound = true;
    }
    _ballNameRequest++;
    _ballNames = {};
    _sesionesFuture = dataRepository.obtenerSesiones();
  }

  /// Optional local metadata only. A late response cannot expose another
  /// account's arsenal labels or interfere with the sessions load.
  Future<void> _loadBallNames() async {
    final repo = context.read<DataRepository>();
    final uid = repo.arsenalUserId;
    final token = repo.seasonAccountToken;
    final request = ++_ballNameRequest;
    try {
      final balls = await repo.listarTodasLasBolas();
      if (!mounted ||
          request != _ballNameRequest ||
          uid != repo.arsenalUserId ||
          token != repo.seasonAccountToken)
        return;
      setState(
        () => _ballNames = {
          for (final b in balls)
            b.id: '${b.name} \u00b7 ${b.weightLbs} lb \u00b7 ${b.id}',
        },
      );
    } catch (_) {
      // A referenced ID remains selectable even if optional metadata is unavailable.
    }
  }

  String _ballLabel(String? id) {
    final l = AppLocalizations.of(context)!;
    return id == null
        ? l.statisticsWithoutBall
        : (_ballNames[id] ?? l.statisticsBallReference(id));
  }

  // ---------------------------------------------------------------------------
  // Filtering logic
  // ---------------------------------------------------------------------------

  /// A single chronological pipeline shared with cached metric calculations.
  /// Date filters refer to session days; recent games use effective game dates.
  List<Sesion> _getFilteredSesiones(List<Sesion> sesiones) {
    _filter = StatsSelection.availableFilter(sesiones, _filter);
    return StatsSelection.apply(sesiones, _filter);
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
      case DateRangePreset.last7Days:
        return l10n.datePresetLast7Days;
      case DateRangePreset.last30Days:
        return l10n.datePresetLast30Days;
      case DateRangePreset.last90Days:
        return l10n.datePresetLast90Days;
      case DateRangePreset.thisMonth:
        return l10n.datePresetThisMonth;
      case DateRangePreset.thisYear:
        return l10n.datePresetThisYear;
      case DateRangePreset.allTime:
        return l10n.datePresetAllTime;
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

  String _sessionFilterKey(Sesion sesion) {
    return StatsSelection.sessionKey(sesion);
  }

  String _sessionFilterLabel(Sesion sesion, AppLocalizations l10n) {
    final tipo = _translateTipo(sesion.tipo, l10n);
    return '${_formatearFechaCorta(sesion.fecha)} - ${sesion.lugar} ($tipo)';
  }

  String _seasonLabel(Sesion sesion) => sesion.temporadaNormalizada;

  List<Sesion> _seasonScopedSesiones(List<Sesion> sesiones, String temporada) {
    return sesiones.where((s) {
      final tipoOk =
          _filter.tipo == AppConstants.tipoTodos || s.tipo == _filter.tipo;
      return tipoOk && s.temporadaNormalizada == temporada;
    }).toList();
  }

  String _signedValue(num value, {int fractionDigits = 0}) {
    final absValue = value.abs();
    final text = fractionDigits > 0
        ? absValue.toStringAsFixed(fractionDigits)
        : absValue.toStringAsFixed(0);
    if (value > 0) return '+$text';
    if (value < 0) return '-$text';
    return '±0';
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
            key: const Key('statistics-refresh'),
            tooltip: l10n.statisticsRefresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
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

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.statisticsLoadError, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _refresh, child: Text(l10n.retry)),
                  ],
                ),
              ),
            );
          }

          // --- Filtros por tipo y fecha ---
          final sesiones = _getFilteredSesiones(snapshot.data!);

          final entries = StatsSelection.games(sesiones);
          final partidas = entries.map((e) => e.$2).toList();
          final gameDates = {
            for (final e in entries) e.$2: e.$2.fecha ?? e.$1.fecha,
          };

          // Extract theme colors for the filter
          final isDark = Theme.of(context).brightness == Brightness.dark;

          if (partidas.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFilterBar(l10n, isDark, snapshot.data!),
                  const SizedBox(height: 24),
                  Icon(
                    Icons.query_stats,
                    size: 48,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.data!.expand((s) => s.partidas).isEmpty
                        ? l10n.noDataForStatistics
                        : l10n.statisticsFilteredEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_filter != const StatsFilter())
                    TextButton(
                      key: const Key('statistics-empty-reset'),
                      onPressed: _resetFilters,
                      child: Text(l10n.statisticsResetFilters),
                    ),
                ],
              ),
            );
          }

          // Usar cache de estadísticas (provider registrado en main.dart)
          final estadisticasCache = Provider.of<EstadisticasCache>(
            context,
            listen: false,
          );
          final stats = estadisticasCache.getEstadisticas(
            sesiones,
            filterKey: _filter.cacheKey,
            accountId: context.read<DataRepository>().arsenalUserId,
          );

          // Log analytics after successful data load (only once)
          if (!_hasLoggedView) {
            _hasLoggedView = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              try {
                final analytics = Provider.of<AnalyticsService>(
                  context,
                  listen: false,
                );
                analytics.logStatisticsViewed(_filter.analyticsKey);
              } catch (e) {
                debugPrint('Error logging statistics view: $e');
              }
            });
          }

          // --- OBTENER DATOS DEL CACHE ---
          final promedio = stats['promedioGeneral'] as double;
          final promedioUlt5 = stats['promedioUltimas5'] as double;
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
          final conversionSparePorPin =
              stats['conversionSparePorPin'] as Map<String, List<int>>? ?? {};
          // Season-focused summary + previous-season comparison.
          final selectedSeason = _filter.temporada;
          Map<String, dynamic>? selectedSeasonStats;
          Map<String, dynamic>? previousSeasonStats;
          String? previousSeason;
          if (selectedSeason != null) {
            final seasonTimelineSesiones =
                _filter.tipo == AppConstants.tipoTodos
                ? snapshot.data!
                : snapshot.data!.where((s) => s.tipo == _filter.tipo).toList();
            previousSeason = EstadisticasUtils.temporadaAnterior(
              seasonTimelineSesiones,
              selectedSeason,
            );

            final scopedCurrent = _seasonScopedSesiones(
              snapshot.data!,
              selectedSeason,
            );
            if (scopedCurrent.isNotEmpty) {
              selectedSeasonStats = estadisticasCache.getEstadisticas(
                scopedCurrent,
                filterKey: 'season_focus_${_filter.tipo}_$selectedSeason',
                accountId: context.read<DataRepository>().arsenalUserId,
              );
            }

            if (previousSeason != null) {
              final scopedPrevious = _seasonScopedSesiones(
                snapshot.data!,
                previousSeason,
              );
              if (scopedPrevious.isNotEmpty) {
                previousSeasonStats = estadisticasCache.getEstadisticas(
                  scopedPrevious,
                  filterKey: 'season_focus_${_filter.tipo}_$previousSeason',
                  accountId: context.read<DataRepository>().arsenalUserId,
                );
              }
            }
          }

          final sample = StatisticsPinSample.fromGames(partidas);
          // Each leave entry counts an opportunity once, unlike the aggregated pin map.
          final opportunities = conversionSparePorPin.values.fold<int>(
            0,
            (n, v) => n + v[0],
          );
          final converted = conversionSparePorPin.values.fold<int>(
            0,
            (n, v) => n + v[1],
          );
          Widget section(
            String id,
            String title,
            IconData icon,
            List<Widget> children, {
            String? subtitle,
          }) => Card(
            child: ExpansionTile(
              key: Key('statistics-details-$id'),
              leading: Icon(icon),
              title: Text(title, key: Key('statistics-toggle-$id')),
              subtitle: subtitle == null ? null : Text(subtitle),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(14),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildFilterBar(l10n, isDark, snapshot.data!),
                    const SizedBox(height: 12),
                    _buildSummary(
                      l10n,
                      partidas.length,
                      sesiones.length,
                      promedio,
                      mejor,
                      promedioUlt5,
                    ),
                    if (_filter.withoutBall)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.ballUnknownScope,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (_filter.ballId != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.ballScoreScope,
                          key: const Key('ball-score-filter-scope'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 12),
                    StatisticsScoreChart(
                      entries: entries,
                      averages: miniPromedios,
                      window: AppConstants.ventanaPromedioMovil,
                    ),
                    const SizedBox(height: 12),
                    StatisticsAnalysisPanel(
                      entries: entries,
                      ballLabel: _ballLabel,
                      onBallNamesNeeded: _loadBallNames,
                      selectedBallId: _filter.ballId,
                      onlyUnknownBall: _filter.withoutBall,
                    ),
                    if (selectedSeason != null)
                      section(
                        'season',
                        l10n.seasonFocusTitle(selectedSeason),
                        Icons.calendar_month,
                        [
                          _buildSeasonFocusCard(
                            l10n: l10n,
                            isDark: isDark,
                            selectedSeason: selectedSeason,
                            selectedSeasonStats: selectedSeasonStats ?? stats,
                            previousSeason: previousSeason,
                            previousSeasonStats: previousSeasonStats,
                          ),
                        ],
                      ),
                    section(
                      'outcomes',
                      l10n.statsGeneralSection,
                      Icons.pie_chart_outline,
                      [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            RachaBadge(
                              label: l10n.strikes,
                              valor: rachaStrike,
                              icon: Icons.flash_on,
                              color: Colors.blue,
                            ),
                            RachaBadge(
                              label: l10n.spares,
                              valor: rachaSpare,
                              icon: Icons.bolt,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.longestStreakDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.percentageStrikesSparesMisses),
                        PastelPorcentajes(
                          porcentajeStrikes: porcentajes['strikes']!,
                          porcentajeSpares: porcentajes['spares']!,
                          porcentajeFallos: porcentajes['fallos']!,
                        ),
                      ],
                    ),
                    section(
                      'distribution',
                      l10n.scoreDistribution,
                      Icons.bar_chart,
                      [
                        Text(l10n.gamesGroupedByRange),
                        const SizedBox(height: 12),
                        HistogramaPuntuaciones(histograma: histograma),
                      ],
                    ),
                    section(
                      'records',
                      l10n.statsBestWorstSection,
                      Icons.emoji_events_outlined,
                      [
                        TopPartidasWidget(
                          partidas: top3,
                          dateForGame: (p) => gameDates[p],
                          titulo: l10n.top3BestGames,
                          color: Colors.indigo,
                        ),
                        TopPartidasWidget(
                          partidas: peores3,
                          dateForGame: (p) => gameDates[p],
                          titulo: l10n.top3WorstGames,
                          color: Colors.red,
                        ),
                        ListTile(
                          title: Text(l10n.worst),
                          trailing: Text('$peor'),
                        ),
                        Text(
                          l10n.bestWorstSessionDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (sesionRecord != null)
                          ListTile(
                            leading: const Icon(Icons.star_outline),
                            title: Text(l10n.personalRecord),
                            subtitle: Text(
                              l10n.gamesWithAverage(
                                sesionRecord.partidas.length,
                                _formatearFechaCorta(sesionRecord.fecha),
                                EstadisticasUtils.promedioSesion(
                                  sesionRecord,
                                ).toStringAsFixed(1),
                              ),
                            ),
                          ),
                        if (sesionPeor != null)
                          ListTile(
                            title: Text(l10n.worstSession),
                            subtitle: Text(
                              l10n.gamesWithAverage(
                                sesionPeor.partidas.length,
                                _formatearFechaCorta(sesionPeor.fecha),
                                EstadisticasUtils.promedioSesion(
                                  sesionPeor,
                                ).toStringAsFixed(1),
                              ),
                            ),
                          ),
                      ],
                    ),
                    section(
                      'pins',
                      l10n.pinStatsSection,
                      Icons.sports,
                      [
                        Text(
                          l10n.pinStatsNote,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        if (sample.gamesWithPins == 0)
                          Text(l10n.statisticsNoPinData)
                        else ...[
                          KpiCardDinamico(
                            label: l10n.firstBallAvg,
                            value:
                                promedioPrimerTiro?.toStringAsFixed(1) ??
                                '\u2014',
                            icon: Icons.looks_one_outlined,
                            color: Colors.teal,
                            esSubida: null,
                            compact: true,
                          ),
                          Text(
                            l10n.statisticsFirstSample(sample.firstThrows),
                            key: const Key('statistics-first-sample'),
                          ),
                          const SizedBox(height: 12),
                          KpiCardDinamico(
                            label: l10n.spareConversionRate,
                            value: tasaConversionSpare == null
                                ? '\u2014'
                                : '${tasaConversionSpare.toStringAsFixed(1)}%',
                            icon: Icons.adjust,
                            color: Colors.deepOrange,
                            esSubida: null,
                            compact: true,
                          ),
                          Text(
                            opportunities == 0
                                ? l10n.statisticsNoSample
                                : l10n.statisticsSpareSample(
                                    converted,
                                    opportunities,
                                  ),
                            key: const Key('statistics-spare-sample'),
                          ),
                          if (conversionSparePorPin.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              l10n.perPinSpareStats,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.statisticsSpareTableHint,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            PerPinHeatmap(
                              data: buildPerPinHeatmapData(
                                conversionSparePorPin,
                              ),
                            ),
                            _buildPerPinSpareTable(conversionSparePorPin, l10n),
                          ],
                        ],
                      ],
                      subtitle: l10n.statisticsPinCoverage(
                        sample.gamesWithPins,
                        partidas.length,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
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

  Widget _buildSeasonFocusCard({
    required AppLocalizations l10n,
    required bool isDark,
    required String selectedSeason,
    required Map<String, dynamic> selectedSeasonStats,
    required String? previousSeason,
    required Map<String, dynamic>? previousSeasonStats,
  }) {
    final avg = (selectedSeasonStats['promedioGeneral'] as double? ?? 0.0);
    final bestGame =
        (selectedSeasonStats['mejorPartida'] as Partida?)?.total ?? 0;
    final totalGames = selectedSeasonStats['totalPartidas'] as int? ?? 0;
    final totalSessions = selectedSeasonStats['totalSesiones'] as int? ?? 0;
    final seasonRecord = selectedSeasonStats['sesionRecord'] as Sesion?;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final previousAvg =
        (previousSeasonStats?['promedioGeneral'] as double?) ?? 0.0;
    final previousBest =
        (previousSeasonStats?['mejorPartida'] as Partida?)?.total ?? 0;
    final previousGames = previousSeasonStats?['totalPartidas'] as int? ?? 0;
    final previousSessions = previousSeasonStats?['totalSesiones'] as int? ?? 0;
    final deltaAvg = avg - previousAvg;
    final deltaBest = bestGame - previousBest;
    final deltaGames = totalGames - previousGames;
    final deltaSessions = totalSessions - previousSessions;

    return Card(
      elevation: isDark ? 0 : 1.5,
      color: isDark
          ? Theme.of(context).colorScheme.surface.withOpacity(0.9)
          : Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.seasonFocusTitle(selectedSeason),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.statisticsSeasonScope,
              key: const Key('statistics-season-scope'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  KpiCardDinamico(
                    label: l10n.average,
                    value: avg.toStringAsFixed(1),
                    icon: Icons.bar_chart_rounded,
                    color: Colors.blue[700]!,
                    esSubida: null,
                  ),
                  KpiCardDinamico(
                    label: l10n.best,
                    value: '$bestGame',
                    icon: Icons.emoji_events_rounded,
                    color: Colors.green[600]!,
                    esSubida: null,
                  ),
                  KpiCardDinamico(
                    label: l10n.games,
                    value: '$totalGames',
                    icon: Icons.sports_score_rounded,
                    color: Colors.purple[600]!,
                    esSubida: null,
                  ),
                  KpiCardDinamico(
                    label: l10n.sessions,
                    value: '$totalSessions',
                    icon: Icons.calendar_view_week_rounded,
                    color: Colors.teal[600]!,
                    esSubida: null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.seasonComparisonSection,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            if (previousSeasonStats != null && previousSeason != null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _SeasonDeltaChip(
                      label: l10n.average,
                      value: _signedValue(deltaAvg, fractionDigits: 1),
                      positive: deltaAvg >= 0,
                    ),
                    _SeasonDeltaChip(
                      label: l10n.best,
                      value: _signedValue(deltaBest.toDouble()),
                      positive: deltaBest >= 0,
                    ),
                    _SeasonDeltaChip(
                      label: l10n.games,
                      value: _signedValue(deltaGames.toDouble()),
                      positive: deltaGames >= 0,
                    ),
                    _SeasonDeltaChip(
                      label: l10n.sessions,
                      value: _signedValue(deltaSessions.toDouble()),
                      positive: deltaSessions >= 0,
                    ),
                  ],
                ),
              )
            else
              Text(
                l10n.seasonComparisonUnavailable,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withOpacity(0.7),
                ),
              ),
            const SizedBox(height: 10),
            Text(
              l10n.seasonRecordsSection,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: Colors.amber[700],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.seasonBestGameLabel}: $bestGame',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
            if (seasonRecord != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.star_outline_rounded,
                    size: 18,
                    color: Colors.green[600],
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${l10n.seasonBestSessionLabel}: ${l10n.gamesWithAverage(seasonRecord.partidas.length, _formatearFechaCorta(seasonRecord.fecha), EstadisticasUtils.promedioSesion(seasonRecord).toStringAsFixed(1))}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
                        color: isGood
                            ? Colors.green[600]
                            : Colors.deepOrange[600],
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

  void _resetFilters() {
    setState(() => _filter = const StatsFilter());
  }

  Widget _buildFilterBar(
    AppLocalizations l,
    bool isDark,
    List<Sesion> sessions,
  ) {
    final labels = [
      _translateTipo(_filter.tipo, l),
      if (_filter.temporada != null) _filter.temporada!,
      if (_filter.ballId != null || _filter.withoutBall)
        _ballLabel(_filter.ballId),
      if (_filter.venue != null) '${l.statisticsVenueFilter}: ${_filter.venue}',
      if (_filter.withoutVenue) l.statisticsWithoutVenue,
      if (_filter.sessionKey != null)
        _sessionFilterLabel(
          sessions.firstWhere(
            (s) => _sessionFilterKey(s) == _filter.sessionKey,
          ),
          l,
        ),
      if (_filter.datePreset == DateRangePreset.custom &&
          _filter.customRange != null)
        '${_formatearFechaCorta(_filter.customRange!.start)} - ${_formatearFechaCorta(_filter.customRange!.end)}'
      else
        _labelForPreset(_filter.datePreset, l),
      if (_filter.lastN != LastNGames.all) _labelForLastN(_filter.lastN, l),
    ];
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpansionTile(
            key: const Key('statistics-filters'),
            onExpansionChanged: (open) {
              if (open) _loadBallNames();
            },
            leading: const Icon(Icons.tune),
            title: Text(
              l.statisticsFilters,
              key: const Key('statistics-filter-toggle'),
            ),
            subtitle: Text(
              labels.join(' \u00b7 '),
              key: const Key('statistics-filter-summary'),
            ),
            children: [_buildFilterControls(l, isDark, sessions)],
          ),
          if (_filter != const StatsFilter())
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('statistics-reset-filters'),
                onPressed: _resetFilters,
                child: Text(l.statisticsResetFilters),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    AppLocalizations l,
    int games,
    int sessions,
    double average,
    int best,
    double recent,
  ) {
    final colors = Theme.of(context).colorScheme;
    final cards = [
      KpiCardDinamico(
        key: const Key('statistics-average'),
        label: l.average,
        value: average.toStringAsFixed(1),
        icon: Icons.bar_chart,
        color: colors.primary,
        esSubida: null,
        compact: true,
      ),
      KpiCardDinamico(
        label: l.games,
        value: '$games',
        icon: Icons.sports_score,
        color: colors.secondary,
        esSubida: null,
        compact: true,
      ),
      KpiCardDinamico(
        label: l.best,
        value: '$best',
        icon: Icons.emoji_events_outlined,
        color: Colors.teal,
        esSubida: null,
        compact: true,
      ),
      KpiCardDinamico(
        label: l.averageLast5,
        value: recent.toStringAsFixed(1),
        icon: Icons.history,
        color: colors.primary,
        esSubida: null,
        compact: true,
      ),
    ];
    return Column(
      key: const Key('statistics-summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.statisticsSummary,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          l.statisticsSample(games, sessions),
          key: const Key('statistics-sample'),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final single =
                box.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.35;
            final width = single ? box.maxWidth : (box.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: cards
                  .map((c) => SizedBox(width: width, child: c))
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          l.statisticsRecentSample(
            games < AppConstants.ultimasPartidasPromedio5
                ? games
                : AppConstants.ultimasPartidasPromedio5,
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildEquipmentFilters(AppLocalizations l, List<Sesion> sessions) {
    final ballIds =
        sessions
            .expand((s) => s.partidas)
            .expand(StatsSelection.ballKeys)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final venues = <String, String>{};
    for (final session in sessions) {
      final key = StatsSelection.venueKey(session);
      if (key != null) venues.putIfAbsent(key, () => session.lugar.trim());
    }
    final venueKeys = venues.keys.toList()..sort();
    DropdownMenuItem<String> item(String value, String label) =>
        DropdownMenuItem(
          value: value,
          child: Tooltip(
            message: label,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        );
    return Column(
      children: [
        DropdownButtonFormField<String>(
          key: const Key('statistics-ball-filter'),
          isExpanded: true,
          value: _filter.withoutBall
              ? 'none'
              : _filter.ballId == null
              ? 'all'
              : 'ball:${_filter.ballId}',
          decoration: InputDecoration(labelText: l.statisticsBallFilter),
          items: [
            item('all', l.statisticsAllBalls),
            item('none', l.statisticsWithoutBall),
            for (final id in ballIds) item('ball:$id', _ballLabel(id)),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _filter = value == 'all'
                  ? _filter.copyWith(clearBall: true)
                  : value == 'none'
                  ? _filter.copyWith(withoutBall: true)
                  : _filter.copyWith(ballId: value.substring(5));
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('statistics-venue-filter'),
          isExpanded: true,
          value: _filter.withoutVenue
              ? 'none'
              : _filter.venue == null
              ? 'all'
              : 'venue:${_filter.venue}',
          decoration: InputDecoration(labelText: l.statisticsVenueFilter),
          items: [
            item('all', l.statisticsAllVenues),
            item('none', l.statisticsWithoutVenue),
            for (final key in venueKeys) item('venue:$key', venues[key]!),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _filter = value == 'all'
                  ? _filter.copyWith(clearVenue: true)
                  : value == 'none'
                  ? _filter.copyWith(withoutVenue: true)
                  : _filter.copyWith(venue: value.substring(6));
            });
          },
        ),
      ],
    );
  }

  /// Full filter bar: session type + date range presets + last-N-games chips.
  Widget _buildFilterControls(
    AppLocalizations l10n,
    bool isDark,
    List<Sesion> sesiones,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final sessionOptions =
        sesiones
            .asMap()
            .entries
            .map(
              (entry) =>
                  (key: _sessionFilterKey(entry.value), sesion: entry.value),
            )
            .toList()
          ..sort((a, b) => b.sesion.fecha.compareTo(a.sesion.fecha));
    final selectedSessionValue =
        sessionOptions.any((option) => option.key == _filter.sessionKey)
        ? _filter.sessionKey
        // If a previously selected session no longer exists, the selector
        // gracefully falls back to the "all sessions" option.
        : null;
    final seasonOptions = sesiones.map(_seasonLabel).toSet().toList()
      ..sort((a, b) {
        final aSinTemporada = a == AppConstants.temporadaSinTemporada;
        final bSinTemporada = b == AppConstants.temporadaSinTemporada;
        if (aSinTemporada && !bSinTemporada) return 1;
        if (!aSinTemporada && bSinTemporada) return -1;
        return b.compareTo(a);
      });
    final selectedSeasonValue = seasonOptions.contains(_filter.temporada)
        ? _filter.temporada
        : null;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Theme.of(context).colorScheme.surface
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withOpacity(0.38), width: 1.3),
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

          // ── Row 2: season filter ───────────────────────────────────────
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                l10n.selectSeason + ':',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSeasonValue ?? _allSeasonsFilterValue,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.arrow_drop_down, color: primary),
                    dropdownColor: isDark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: _allSeasonsFilterValue,
                        child: Text(
                          l10n.all,
                          style: TextStyle(color: onSurface.withOpacity(0.8)),
                        ),
                      ),
                      ...seasonOptions.map(
                        (season) => DropdownMenuItem<String>(
                          value: season,
                          child: Text(
                            season,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _filter = v == _allSeasonsFilterValue
                            ? _filter.copyWith(clearTemporada: true)
                            : _filter.copyWith(temporada: v);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          // ── Row 3: specific session ────────────────────────────────────
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${l10n.sessions}:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurface.withOpacity(0.65),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSessionValue ?? _allSessionsFilterValue,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    icon: Icon(Icons.arrow_drop_down, color: primary),
                    dropdownColor: isDark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    items: [
                      DropdownMenuItem<String>(
                        value: _allSessionsFilterValue,
                        child: Text(
                          l10n.all,
                          style: TextStyle(color: onSurface.withOpacity(0.8)),
                        ),
                      ),
                      ...sessionOptions.map(
                        (option) => DropdownMenuItem<String>(
                          value: option.key,
                          child: Text(
                            _sessionFilterLabel(option.sesion, l10n),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _filter = v == _allSessionsFilterValue
                            ? _filter.copyWith(clearSessionKey: true)
                            : _filter.copyWith(sessionKey: v);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          // ── Row 4: date range presets ──────────────────────────────────
          const SizedBox(height: 6),
          _buildEquipmentFilters(l10n, sesiones),
          const SizedBox(height: 12),
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
                                builder: (ctx, child) =>
                                    Theme(data: Theme.of(ctx), child: child!),
                              );
                              if (picked != null && mounted) {
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

          // ── Row 5: last-N-games ────────────────────────────────────────
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
}

class _SeasonDeltaChip extends StatelessWidget {
  const _SeasonDeltaChip({
    required this.label,
    required this.value,
    required this.positive,
  });

  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? Colors.green[700]! : Colors.red[600]!;
    final bg = positive ? Colors.green[50]! : Colors.red[50]!;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
