import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/utils/statistics_metrics.dart';
import 'package:bolometro/utils/stats_filter.dart';
import 'package:bolometro/utils/stats_selection.dart';
import 'package:bolometro/utils/estadisticas_cache.dart';

Partida game(int total, {String? ball, DateTime? date}) => Partida(
  total: total,
  ballId: ball,
  fecha: date,
  frames: List.generate(10, (_) => ['9', '/']),
);
Sesion session(
  int day,
  List<Partida> games, {
  String venue = 'North',
  String type = 'Entrenamiento',
  String? season = 'Current',
}) => Sesion(
  fecha: DateTime(2026, 11, day),
  lugar: venue,
  tipo: type,
  temporada: season,
  partidas: games,
);

void main() {
  test(
    'unknown dispersion for zero or one game is distinct from equal-score zero',
    () {
      final empty = ScoreSummary.fromGames([]);
      expect(empty.count, 0);
      expect(empty.mean, isNull);
      expect(empty.best, isNull);
      expect(empty.standardDeviation, isNull);
      expect(ScoreSummary.fromGames([game(0)]).standardDeviation, isNull);
      final equal = ScoreSummary.fromGames([game(150), game(150)]);
      expect(equal.standardDeviation, 0);
      expect(equal.mean, 150);
    },
  );
  test(
    'population deviation agrees with known arithmetic and is order independent',
    () {
      final games = [game(100), game(110), game(120), game(130), game(140)];
      final s = ScoreSummary.fromGames(games);
      expect(s.mean, 120);
      expect(s.best, 140);
      expect(s.standardDeviation, closeTo(math.sqrt(200), 1e-10));
      expect(
        ScoreSummary.fromGames(games.reversed).standardDeviation,
        closeTo(s.standardDeviation!, 1e-10),
      );
      expect(
        ScoreSummary.fromGames([game(0), game(300)]).standardDeviation,
        150,
      );
    },
  );
  test('comparison uses two complete nonoverlapping chronological blocks', () {
    final sessions = List.generate(
      25,
      (i) => session(i + 1, [game(i < 15 ? 100 : 200)]),
    );
    final entries = StatsSelection.games(sessions.reversed.toList());
    final c = RecentGamesComparison(entries, window: 10);
    expect(c.isAvailable, isTrue);
    expect(c.recent!.count, 10);
    expect(c.previous!.count, 10);
    expect(c.recent!.mean, 200);
    expect(c.previous!.mean, 100);
    expect(c.meanDifference, 100);
    expect(c.previousEntries.first.$1.fecha.day, 6);
    expect(c.recentEntries.first.$1.fecha.day, 16);
    expect(
      c.previousEntries
          .map((e) => e.$2)
          .toSet()
          .intersection(c.recentEntries.map((e) => e.$2).toSet()),
      isEmpty,
    );
    expect(entries.length, 25);
  });
  test(
    'comparison never fabricates partial blocks or treats a missing block as zero',
    () {
      for (final length in [0, 1, 10, 19]) {
        final c = RecentGamesComparison(
          StatsSelection.games(
            List.generate(length, (i) => session(i + 1, [game(150)])),
          ),
        );
        expect(c.isAvailable, isFalse);
        expect(c.meanDifference, isNull);
        expect(c.recent, isNull);
        expect(c.previous, isNull);
      }
      expect(() => RecentGamesComparison([], window: 0), throwsArgumentError);
    },
  );
  test('same-size game blocks do not presume equal elapsed time', () {
    final entries = StatsSelection.games([
      session(1, [game(100), game(100)]),
      session(28, [game(200), game(200)]),
    ]);
    final c = RecentGamesComparison(entries, window: 2);
    expect(c.meanDifference, 100);
    expect(c.recentEntries.first.$1.fecha.day, 28);
  });
  test(
    'ball selection is by personal ID, within sessions, without modifying source games',
    () {
      final s = session(1, [
        game(100, ball: 'a'),
        game(200, ball: 'b'),
        game(150),
      ]);
      final before = jsonEncode(s.toJson());
      final selected = StatsSelection.apply([
        s,
      ], const StatsFilter(ballId: 'a'));
      expect(selected.single.partidas.single, same(s.partidas.first));
      expect(jsonEncode(s.toJson()), before);
      expect(
        StatsSelection.apply([
          s,
        ], const StatsFilter(ballId: 'b')).single.partidas.single.total,
        200,
      );
    },
  );
  test(
    'missing and blank ball references are unknown but missing metadata does not discard IDs',
    () {
      final s = session(1, [
        game(100),
        game(110, ball: '  '),
        game(200, ball: 'orphan-id'),
      ]);
      expect(
        StatsSelection.apply([
          s,
        ], const StatsFilter(withoutBall: true)).single.partidas.length,
        2,
      );
      expect(
        StatsSelection.availableFilter([
          s,
        ], const StatsFilter(ballId: 'orphan-id')).ballId,
        'orphan-id',
      );
      expect(
        StatsSelection.apply([
          s,
        ], const StatsFilter(ballId: 'orphan-id')).single.partidas.single.total,
        200,
      );
    },
  );
  test(
    'venue spelling normalization is read-only and does not merge distinct accented names',
    () {
      final sessions = [
        session(1, [game(100)], venue: '  North   Lanes '),
        session(2, [game(200)], venue: 'north lanes'),
        session(3, [game(120)], venue: 'Nórth Lanes'),
        session(4, [game(80)], venue: ''),
      ];
      final before = jsonEncode(sessions.map((s) => s.toJson()).toList());
      expect(
        StatsSelection.apply(
          sessions,
          const StatsFilter(venue: 'north lanes'),
        ).length,
        2,
      );
      expect(
        StatsSelection.apply(
          sessions,
          const StatsFilter(withoutVenue: true),
        ).single.partidas.single.total,
        80,
      );
      expect(jsonEncode(sessions.map((s) => s.toJson()).toList()), before);
    },
  );
  test(
    'venue uses session location rather than an optional inconsistent game location',
    () {
      final p = game(100).copyWith(lugar: 'South');
      expect(
        StatsSelection.apply([
          session(1, [p]),
        ], const StatsFilter(venue: 'north')).length,
        1,
      );
      expect(
        StatsSelection.apply([
          session(1, [p]),
        ], const StatsFilter(venue: 'south')),
        isEmpty,
      );
    },
  );
  test(
    'all controls combine before applying last N; no previous block outside filters',
    () {
      final sessions = List.generate(
        24,
        (i) => session(i + 1, [
          game(100 + i, ball: 'a'),
          game(250, ball: 'b'),
        ], venue: i < 12 ? 'South' : 'North'),
      );
      final filter = StatsFilter(
        ballId: 'a',
        venue: 'north',
        temporada: 'Current',
        tipo: 'Entrenamiento',
        datePreset: DateRangePreset.custom,
        customRange: DateTimeRange(
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 30),
        ),
        lastN: LastNGames.last10,
      );
      final entries = StatsSelection.games(
        StatsSelection.apply(sessions, filter),
      );
      expect(entries.length, 10);
      expect(entries.first.$2.total, 114);
      expect(entries.last.$2.total, 123);
      expect(RecentGamesComparison(entries).isAvailable, isFalse);
      expect(RecentGamesComparison(entries, window: 5).isAvailable, isTrue);
    },
  );
  test('copy and clear switches keep unknown selectors mutually exclusive', () {
    final unknown = const StatsFilter(
      ballId: 'a',
      venue: 'north',
    ).copyWith(withoutBall: true, withoutVenue: true);
    expect(unknown.ballId, isNull);
    expect(unknown.venue, isNull);
    expect(unknown.withoutBall, isTrue);
    expect(unknown.withoutVenue, isTrue);
    final known = unknown.copyWith(ballId: 'b', venue: 'south');
    expect(known.withoutBall, isFalse);
    expect(known.withoutVenue, isFalse);
    expect(
      known.copyWith(clearBall: true, clearVenue: true),
      const StatsFilter(),
    );
  });
  test(
    'filter keys distinguish IDs venues null and string delimiters; analytics carries no names',
    () {
      final keys = [
        const StatsFilter(),
        const StatsFilter(withoutBall: true),
        const StatsFilter(ballId: 'none'),
        const StatsFilter(venue: 'none'),
        const StatsFilter(withoutVenue: true),
        const StatsFilter(temporada: 'a_b', sessionKey: 'c'),
        const StatsFilter(temporada: 'a', sessionKey: 'b_c'),
      ].map((f) => f.cacheKey).toSet();
      expect(keys.length, 7);
      final filter = const StatsFilter(
        ballId: 'secret-ball',
        venue: 'private-club',
        temporada: 'private-season',
        sessionKey: 'private-session',
      );
      for (final secret in [
        'secret-ball',
        'private-club',
        'private-season',
        'private-session',
      ]) {
        expect(filter.analyticsKey, isNot(contains(secret)));
      }
      expect(
        filter,
        isNot(
          const StatsFilter(
            ballId: 'other-ball',
            venue: 'private-club',
            temporada: 'private-season',
            sessionKey: 'private-session',
          ),
        ),
      );
    },
  );
  test('stale concrete filters clear after account/data changes', () {
    final clean = StatsSelection.availableFilter([
      session(1, [game(150, ball: 'b')], venue: 'South'),
    ], const StatsFilter(ballId: 'a', venue: 'north'));
    expect(clean.ballId, isNull);
    expect(clean.venue, isNull);
  });
  test(
    'group summaries preserve distinct IDs and count unknowns exactly once',
    () {
      final entries = StatsSelection.games([
        session(1, [
          game(100, ball: 'a'),
          game(200, ball: 'b'),
          game(150, ball: 'a'),
          game(0),
          game(50, ball: ''),
        ]),
      ]);
      final groups = StatisticsGroups.byBall(entries);
      expect(groups.length, 3);
      expect(groups.fold<int>(0, (n, g) => n + g.summary.count), 5);
      expect(groups.singleWhere((g) => g.id == 'a').summary.mean, 125);
      expect(
        groups.singleWhere((g) => g.id == 'b').summary.standardDeviation,
        isNull,
      );
      expect(groups.singleWhere((g) => g.id == null).summary.count, 2);
    },
  );
  test(
    'venue groups use normalized session names and sort by sample not average',
    () {
      final groups = StatisticsGroups.byVenue(
        StatsSelection.games([
          session(1, [game(100)], venue: ' NORTH  '),
          session(2, [game(120)], venue: 'north'),
          session(3, [game(300)], venue: 'South'),
          session(4, [game(50)], venue: ''),
        ]),
      );
      expect(groups.first.id, 'north');
      expect(groups.first.summary.count, 2);
      expect(groups.first.summary.mean, 110);
      expect(groups.singleWhere((g) => g.id == null).summary.count, 1);
    },
  );
  test(
    'existing content cache respects changed personal ball associations',
    () {
      final cache = EstadisticasCache();
      final s = session(1, [game(100, ball: 'a'), game(200, ball: 'b')]);
      final a = const StatsFilter(ballId: 'a');
      expect(
        cache.getEstadisticas(
          StatsSelection.apply([s], a),
          filterKey: a.cacheKey,
        )['promedioGeneral'],
        100,
      );
      s.partidas[0] = game(180, ball: 'a');
      expect(
        cache.getEstadisticas(
          StatsSelection.apply([s], a),
          filterKey: a.cacheKey,
        )['promedioGeneral'],
        180,
      );
      cache.dispose();
    },
  );
}
