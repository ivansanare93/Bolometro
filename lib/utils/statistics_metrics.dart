import 'ball_throw_usage.dart';
import 'dart:math' as math;
import '../models/partida.dart';
import '../models/sesion.dart';
import 'stats_selection.dart';

/// Descriptive statistics of the actual selected games, not a skill estimate.
class ScoreSummary {
  const ScoreSummary({
    required this.count,
    required this.mean,
    required this.best,
    required this.standardDeviation,
  });
  final int count;
  final double? mean;
  final int? best;

  /// Population standard deviation of this finite recorded set. Unknown for n<2.
  final double? standardDeviation;
  factory ScoreSummary.fromGames(Iterable<Partida> games) {
    var n = 0;
    var mean = 0.0;
    var m2 = 0.0;
    int? best;
    for (final game in games) {
      n++;
      final delta = game.total - mean;
      mean += delta / n;
      m2 += delta * (game.total - mean);
      best = best == null ? game.total : math.max(best, game.total);
    }
    return ScoreSummary(
      count: n,
      mean: n == 0 ? null : mean,
      best: best,
      standardDeviation: n < 2 ? null : math.sqrt(math.max(0.0, m2 / n)),
    );
  }
}

/// Equal numbers of consecutive games from the already-filtered chronological
/// set, including last-N. No partial blocks, overlap or calendar-duration claim.
class RecentGamesComparison {
  RecentGamesComparison(List<(Sesion, Partida)> entries, {this.window = 10}) {
    if (window <= 0) throw ArgumentError.value(window, 'window');
    available = entries.length;
    if (available >= 2 * window) {
      previousEntries = List.unmodifiable(
        entries.sublist(available - 2 * window, available - window),
      );
      recentEntries = List.unmodifiable(entries.sublist(available - window));
    } else {
      previousEntries = const [];
      recentEntries = const [];
    }
  }
  final int window;
  late final int available;
  late final List<(Sesion, Partida)> previousEntries;
  late final List<(Sesion, Partida)> recentEntries;
  bool get isAvailable =>
      recentEntries.length == window && previousEntries.length == window;
  ScoreSummary? get recent => isAvailable
      ? ScoreSummary.fromGames(recentEntries.map((e) => e.$2))
      : null;
  ScoreSummary? get previous => isAvailable
      ? ScoreSummary.fromGames(previousEntries.map((e) => e.$2))
      : null;
  double? get meanDifference =>
      isAvailable ? recent!.mean! - previous!.mean! : null;
}

class ScoreGroup {
  ScoreGroup({
    required this.id,
    required this.label,
    required this.summary,
    this.participations,
    this.usage,
  });
  final String? id;
  final String? label;
  final ScoreSummary summary;
  final int? participations;
  final BallUsageStats? usage;
}

abstract final class StatisticsGroups {
  static List<ScoreGroup> byBall(List<(Sesion, Partida)> entries) {
    final groups = <String?, List<Partida>>{};
    for (final (_, p) in entries) {
      final ids = <String?>{...p.usedBallIds, if (p.hasUnassignedThrows) null};
      for (final id in ids) groups.putIfAbsent(id, () => []).add(p);
    }
    return groups.entries
        .map(
          (e) => ScoreGroup(
            id: e.key,
            label: null,
            summary: ScoreSummary.fromGames(
              e.value.where((p) => p.exclusivelyUsesBall(e.key)),
            ),
            participations: e.value.length,
            usage: BallUsageStats(e.value, e.key),
          ),
        )
        .toList()
      ..sort(
        (a, b) => b.participations!.compareTo(a.participations!) != 0
            ? b.participations!.compareTo(a.participations!)
            : (a.id ?? '').compareTo(b.id ?? ''),
      );
  }

  static List<ScoreGroup> byVenue(List<(Sesion, Partida)> entries) =>
      _group(entries, true);
  static List<ScoreGroup> _group(List<(Sesion, Partida)> entries, bool venue) {
    final groups = <String?, List<Partida>>{};
    final labels = <String?, String?>{};
    for (final (s, p) in entries) {
      final key = venue
          ? StatsSelection.venueKey(s)
          : StatsSelection.ballKey(p);
      groups.putIfAbsent(key, () => []).add(p);
      labels.putIfAbsent(
        key,
        () => venue && key != null
            ? s.lugar.trim().replaceAll(RegExp(r'\s+'), ' ')
            : null,
      );
    }
    return groups.entries
        .map(
          (e) => ScoreGroup(
            id: e.key,
            label: labels[e.key],
            summary: ScoreSummary.fromGames(e.value),
          ),
        )
        .toList()
      ..sort((a, b) {
        final count = b.summary.count.compareTo(a.summary.count);
        return count != 0 ? count : (a.id ?? '').compareTo(b.id ?? '');
      });
  }
}
