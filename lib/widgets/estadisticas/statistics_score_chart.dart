import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sesion.dart';
import '../../models/partida.dart';

/// Chronological game index on X, never elapsed time. The cached rolling
/// average is aligned to the final game in each window. Legacy duplicated
/// single values are omitted from the presentation, without changing metrics.
class StatisticsScoreChart extends StatefulWidget {
  const StatisticsScoreChart({
    super.key,
    required this.entries,
    required this.averages,
    required this.window,
  });
  final List<(Sesion, Partida)> entries;
  final List<double> averages;
  final int window;

  List<FlSpot> get scoreSpots => [
    for (var i = 0; i < entries.length; i++)
      FlSpot(i.toDouble(), entries[i].$2.total.toDouble()),
  ];
  List<FlSpot> get averageSpots {
    final count = math.min(
      averages.length,
      math.max(0, entries.length - window + 1),
    );
    return [
      for (var i = 0; i < count; i++)
        FlSpot((i + window - 1).toDouble(), averages[i]),
    ];
  }

  @override
  State<StatisticsScoreChart> createState() => _StatisticsScoreChartState();
}

class _StatisticsScoreChartState extends State<StatisticsScoreChart> {
  int? _selected;
  @override
  void didUpdateWidget(covariant StatisticsScoreChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selected = null;
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (widget.entries.isEmpty) return Text(l.noDataForStatistics);
    final theme = Theme.of(context);
    final scoreColor = theme.colorScheme.primary;
    final averageColor = theme.brightness == Brightness.dark
        ? Colors.amberAccent
        : Colors.deepOrange;
    final index = (_selected ?? widget.entries.length - 1).clamp(
      0,
      widget.entries.length - 1,
    );
    final (session, game) = widget.entries[index];
    final averages = widget.averageSpots;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.statisticsChartTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text(
                  l.statisticsScoreLegend,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (averages.isNotEmpty)
                  Text(
                    l.statisticsMovingLegend(widget.window),
                    style: TextStyle(
                      color: averageColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: LineChart(
                key: const Key('statistics-score-plot'),
                LineChartData(
                  minX: 0,
                  maxX: math.max(1, widget.entries.length - 1).toDouble(),
                  minY: 0,
                  maxY: 300,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 100,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: 100,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchCallback: (event, response) {
                      if (event is FlTapUpEvent &&
                          response?.lineBarSpots?.isNotEmpty == true) {
                        setState(
                          () => _selected = response!.lineBarSpots!.first.x
                              .round(),
                        );
                      }
                    },
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.inverseSurface,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      maxContentWidth: 200,
                      getTooltipItems: (spots) => spots.map((spot) {
                        final i = spot.x.round().clamp(
                          0,
                          widget.entries.length - 1,
                        );
                        final e = widget.entries[i];
                        final label = spot.barIndex == 0
                            ? l.statisticsGameNumber(i + 1)
                            : l.statisticsMovingLegend(widget.window);
                        return LineTooltipItem(
                          '$label\n${_date(e.$2.fecha ?? e.$1.fecha)}\n${spot.y.toStringAsFixed(1)}',
                          TextStyle(color: theme.colorScheme.onInverseSurface),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.scoreSpots,
                      color: scoreColor,
                      isCurved: false,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                    if (averages.isNotEmpty)
                      LineChartBarData(
                        spots: averages,
                        color: averageColor,
                        isCurved: false,
                        barWidth: 3,
                        dashArray: [6, 4],
                        dotData: FlDotData(show: averages.length == 1),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(l.statisticsChartHint, style: theme.textTheme.bodySmall),
            if (averages.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l.statisticsMovingNeeds(widget.window),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                '${l.statisticsGameNumber(index + 1)} \u00b7 ${_date(game.fecha ?? session.fecha)}\n'
                '${l.points(game.total)} \u00b7 ${session.lugar}',
                key: const Key('statistics-selected-game'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  key: const Key('statistics-previous-game'),
                  tooltip: l.statisticsPreviousGame,
                  onPressed: index == 0
                      ? null
                      : () => setState(() => _selected = index - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  key: const Key('statistics-next-game'),
                  tooltip: l.statisticsNextGame,
                  onPressed: index == widget.entries.length - 1
                      ? null
                      : () => setState(() => _selected = index + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
