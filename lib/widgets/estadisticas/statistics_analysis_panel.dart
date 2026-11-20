import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/sesion.dart';
import '../../models/partida.dart';
import '../../utils/statistics_metrics.dart';

class StatisticsAnalysisPanel extends StatefulWidget {
  const StatisticsAnalysisPanel({
    super.key,
    required this.entries,
    required this.ballLabel,
    required this.onBallNamesNeeded,
    this.selectedBallId,
    this.onlyUnknownBall = false,
  });
  final List<(Sesion, Partida)> entries;
  final String Function(String?) ballLabel;
  final VoidCallback onBallNamesNeeded;
  final String? selectedBallId;
  final bool onlyUnknownBall;
  @override
  State<StatisticsAnalysisPanel> createState() =>
      _StatisticsAnalysisPanelState();
}

class _StatisticsAnalysisPanelState extends State<StatisticsAnalysisPanel> {
  int _window = 10;
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _range(List<(Sesion, Partida)> entries) =>
      '${_date(entries.first.$2.fecha ?? entries.first.$1.fecha)} - ${_date(entries.last.$2.fecha ?? entries.last.$1.fecha)}';
  String _signed(double number) {
    if (number.abs() < 0.05) return '0.0';
    return '${number > 0 ? '+' : ''}${number.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final summary = ScoreSummary.fromGames(widget.entries.map((e) => e.$2));
    final comparison = RecentGamesComparison(widget.entries, window: _window);
    final text = Theme.of(context).textTheme;
    Widget section(
      String id,
      String title,
      IconData icon,
      List<Widget> children, {
      VoidCallback? onOpen,
    }) => Card(
      child: ExpansionTile(
        key: Key('statistics-details-$id'),
        title: Text(title, key: Key('statistics-toggle-$id')),
        leading: Icon(icon),
        onExpansionChanged: (open) {
          if (open) onOpen?.call();
        },
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
    Widget block(String title, ScoreSummary scores, String dates) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleSmall),
          Text(dates, style: text.bodySmall),
          Text(
            l.statisticsMetricPoints(scores.mean!.toStringAsFixed(1)),
            style: text.titleLarge,
          ),
          Text(l.statisticsAnalysisSample(scores.count), style: text.bodySmall),
        ],
      ),
    );
    Widget groups(List<ScoreGroup> groups, bool venue) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.statisticsGroupsNote, style: text.bodySmall),
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  venue
                      ? (g.label ?? l.statisticsWithoutVenue)
                      : widget.ballLabel(g.id),
                  style: text.titleSmall,
                ),
                Text(
                  venue
                      ? l.statisticsAnalysisSample(g.summary.count)
                      : l.ballParticipation(g.participations!, g.summary.count),
                ),
                if (!venue) Text(l.ballExclusiveNote, style: text.bodySmall),
                if (g.summary.count == 0)
                  Text(l.ballNoExclusive)
                else
                  Text(
                    l.statisticsGroupSummary(
                      g.summary.mean!.toStringAsFixed(1),
                      '${g.summary.best}',
                    ),
                  ),
                if (!venue && g.usage != null) ...[
                  Text(
                    l.ballUsageNumbers(
                      g.usage!.throwsCount,
                      g.usage!.framesCount,
                      g.usage!.pins,
                    ),
                  ),
                  Text(
                    l.ballStrikeSample(
                      g.usage!.strikes,
                      g.usage!.fullRackThrows,
                    ),
                  ),
                  Text(
                    l.ballSpareSample(g.usage!.spares, g.usage!.spareAttempts),
                  ),
                ],
                Text(
                  '${l.statisticsDeviation}: ${g.summary.standardDeviation == null ? l.statisticsNoSample : l.statisticsMetricPoints(g.summary.standardDeviation!.toStringAsFixed(1))}',
                ),
              ],
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        section('progress', l.statisticsProgress, Icons.insights_outlined, [
          Text(l.statisticsDeviation, style: text.titleSmall),
          Text(
            summary.standardDeviation == null
                ? l.statisticsNoSample
                : l.statisticsMetricPoints(
                    summary.standardDeviation!.toStringAsFixed(1),
                  ),
            key: const Key('statistics-deviation'),
            style: text.titleLarge,
          ),
          Text(l.statisticsAnalysisSample(summary.count)),
          Text(l.statisticsDeviationNote, style: text.bodySmall),
          const Divider(height: 32),
          DropdownButtonFormField<int>(
            key: const Key('statistics-comparison-window'),
            value: _window,
            decoration: InputDecoration(
              labelText: l.statisticsComparisonWindow,
            ),
            items: [
              for (final n in [5, 10, 25])
                DropdownMenuItem(value: n, child: Text('$n')),
            ],
            onChanged: (n) {
              if (n != null) setState(() => _window = n);
            },
          ),
          const SizedBox(height: 12),
          Text(l.statisticsComparisonScope, style: text.bodySmall),
          if (!comparison.isAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l.statisticsComparisonNeeds(2 * _window, comparison.available),
                key: const Key('statistics-comparison-unavailable'),
              ),
            )
          else ...[
            block(
              l.statisticsRecentBlock(_window),
              comparison.recent!,
              _range(comparison.recentEntries),
            ),
            block(
              l.statisticsPreviousBlock(_window),
              comparison.previous!,
              _range(comparison.previousEntries),
            ),
            Text(
              l.statisticsMeanChange(_signed(comparison.meanDifference!)),
              key: const Key('statistics-mean-change'),
              style: text.titleMedium,
            ),
          ],
          const SizedBox(height: 12),
          Text(l.statisticsChangeNote, style: text.bodySmall),
        ]),
        section(
          'balls',
          l.statisticsByBall,
          Icons.sports_baseball_outlined,
          [
            groups(
              StatisticsGroups.byBall(widget.entries)
                  .where(
                    (g) =>
                        (widget.selectedBallId == null ||
                            g.id == widget.selectedBallId) &&
                        (!widget.onlyUnknownBall || g.id == null),
                  )
                  .toList(),
              false,
            ),
          ],
          onOpen: widget.onBallNamesNeeded,
        ),
        section('venues', l.statisticsByVenue, Icons.place_outlined, [
          groups(StatisticsGroups.byVenue(widget.entries), true),
        ]),
      ],
    );
  }
}
