import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/services/ball_stats_service.dart';
import 'package:bolometro/services/draft_service.dart';
import 'package:bolometro/utils/ball_throw_usage.dart';
import 'package:bolometro/utils/stats_selection.dart';
import 'package:bolometro/utils/stats_filter.dart';
import 'package:bolometro/utils/statistics_metrics.dart';

Partida perfect({
  Map<String, String?> overrides = const {},
  String? ball = 'a',
}) => Partida(
  total: 300,
  ballId: ball,
  frames: List.generate(10, (i) => i < 9 ? ['X'] : ['X', 'X', 'X']),
  ballIdsByThrow: overrides,
);
Partida tenth(List<String> tokens, Map<String, String?> ids) => Partida(
  total: 150,
  ballId: 'a',
  frames: [...List.generate(9, (_) => <String>[]), tokens],
  ballIdsByThrow: ids,
);
Sesion session(Partida p) => Sesion(
  fecha: DateTime(2026, 11, 19),
  lugar: 'Test lanes',
  tipo: 'Entrenamiento',
  partidas: [p],
);

/// Reproduces the released seven-field writer. Test data only.
class OldPartidaAdapter extends TypeAdapter<Partida> {
  @override
  final int typeId = 0;
  @override
  Partida read(BinaryReader reader) {
    final count = reader.readByte();
    final f = <int, dynamic>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Partida(
      fecha: f[0] as DateTime?,
      lugar: f[1] as String?,
      frames: (f[2] as List).map((e) => (e as List).cast<String>()).toList(),
      notas: f[3] as String?,
      total: f[4] as int,
      pinesPorTiro: (f[5] as List?)
          ?.map(
            (e) => (e as List).map((p) => (p as List?)?.cast<int>()).toList(),
          )
          .toList(),
      ballId: f[6] as String?,
    );
  }

  @override
  void write(BinaryWriter w, Partida p) {
    final values = [
      p.fecha,
      p.lugar,
      p.frames,
      p.notas,
      p.total,
      p.pinesPorTiro,
      p.ballId,
    ];
    w.writeByte(7);
    for (var i = 0; i < values.length; i++) {
      w.writeByte(i);
      w.write(values[i]);
    }
  }
}

void main() {
  test(
    'legacy games inherit the game ball and keep the original JSON shape',
    () {
      final p = perfect();
      expect(p.usedBallIds, {'a'});
      expect(p.ballForThrow(9, 2), 'a');
      expect(p.toJson().containsKey('ballIdsByThrow'), isFalse);
      expect(Partida.fromJson(p.toJson()).ballIdsByThrow, isEmpty);
      expect(p.exclusivelyUsesBall('a'), isTrue);
    },
  );
  test(
    'sparse overrides preserve explicit unknown and original maps on copy',
    () {
      final input = <String, String?>{'0:1': null, '4:0': 'b'};
      final p = perfect(overrides: input);
      input.clear();
      expect(p.ballForThrow(0, 1), isNull);
      expect(p.ballForThrow(4, 0), 'b');
      expect(p.ballForThrow(5, 0), 'a');
      expect(p.copyWith(notas: 'changed').ballIdsByThrow, p.ballIdsByThrow);
      expect(() => p.ballIdsByThrow.clear(), throwsUnsupportedError);
      expect(p.copyWith(ballIdsByThrow: {}).ballForThrow(4, 0), 'a');
    },
  );
  test(
    'invalid positions and types are rejected rather than silently losing assignments',
    () {
      for (final raw in [
        {'10:0': 'a'},
        {'0:2': 'a'},
        {'0:0': 42},
        {'bad': 'a'},
      ]) {
        expect(() => Partida.parseBallAssignments(raw), throwsFormatException);
      }
      expect(() => Partida.throwKey(0, 2), throwsRangeError);
    },
  );
  test(
    'same frame can use separate first-throw and spare balls without score bonuses',
    () {
      final p = Partida(
        total: 20,
        ballId: 'a',
        frames: [
          ['8', '/'],
        ],
        ballIdsByThrow: {'0:1': 'b'},
      );
      final a = BallUsageStats([p], 'a'), b = BallUsageStats([p], 'b');
      expect(a.pins, 8);
      expect(a.fullRackThrows, 1);
      expect(a.spareAttempts, 0);
      expect(b.pins, 2);
      expect(b.spareAttempts, 1);
      expect(b.spares, 1);
      expect(b.fullRackThrows, 0);
      expect(p.usedBallIds, {'a', 'b'});
      expect(p.exclusivelyUsesBall('a'), isFalse);
    },
  );
  test(
    'gutter then spare is a spare opportunity even with ten pins remaining',
    () {
      final p = Partida(
        total: 10,
        ballId: 'a',
        frames: [
          ['-', '/'],
        ],
        ballIdsByThrow: {'0:1': 'b'},
      );
      final b = BallUsageStats([p], 'b');
      expect(b.pins, 10);
      expect(b.spareAttempts, 1);
      expect(b.spares, 1);
      expect(b.fullRackThrows, 0);
    },
  );
  test(
    'four frames with A and remaining frames with B count real strikes without duplicating 300',
    () {
      final p = perfect(
        overrides: {
          for (var f = 4; f < 10; f++)
            for (var t = 0; t < (f == 9 ? 3 : 2); t++)
              Partida.throwKey(f, t): 'b',
        },
      );
      final a = BallStatsService.calcular([p], ballId: 'a'),
          b = BallStatsService.calcular([p], ballId: 'b');
      expect(a.usage!.throwsCount, 4);
      expect(b.usage!.throwsCount, 8);
      expect(a.usage!.pins, 40);
      expect(b.usage!.pins, 80);
      expect(a.promedio, isNull);
      expect(b.promedio, isNull);
      expect(a.mejorPartida, isNull);
      expect(a.partidasCompartidas, 1);
      expect(b.partidasCompartidas, 1);
      expect(a.strikeRate, 100);
    },
  );
  test(
    'tenth X 7 spare attributes a fresh rack to second throw and spare to third',
    () {
      final p = tenth(['X', '7', '/'], {'9:1': 'b', '9:2': 'c'});
      expect(BallUsageStats([p], 'a').strikes, 1);
      final b = BallUsageStats([p], 'b'), c = BallUsageStats([p], 'c');
      expect(b.fullRackThrows, 1);
      expect(b.pins, 7);
      expect(c.spareAttempts, 1);
      expect(c.spares, 1);
      expect(c.pins, 3);
    },
  );
  test('tenth spare and bonus strike use the actual third ball', () {
    final p = tenth(['7', '/', 'X'], {'9:1': 'b', '9:2': 'c'});
    expect(BallUsageStats([p], 'b').spares, 1);
    expect(BallUsageStats([p], 'c').strikes, 1);
    expect(BallUsageStats([p], 'c').fullRackThrows, 1);
  });
  test('three tenth-frame strikes are separate rack opportunities', () {
    final p = tenth(['X', 'X', 'X'], {'9:1': 'b', '9:2': 'c'});
    for (final id in ['a', 'b', 'c']) {
      expect(BallUsageStats([p], id).strikes, 1);
      expect(BallUsageStats([p], id).pins, 10);
    }
  });
  test(
    'unused bonus and unused second throw do not create ball participation',
    () {
      final p = tenth(['7', '2', ''], {'9:2': 'c'});
      expect(p.usesBall('c'), isFalse);
      expect(p.referencedBallIds, contains('c'));
      final strike = Partida(
        total: 10,
        ballId: 'a',
        frames: [
          ['X', '', ''],
        ],
        ballIdsByThrow: {'0:1': 'b'},
      );
      expect(strike.usedBallIds, {'a'});
      expect(BallUsageStats([strike], 'b').throwsCount, 0);
    },
  );
  test(
    'missing and inconsistent symbols never invent physical pin observations',
    () {
      for (final tokens in [
        <String>[],
        ['', '9'],
        ['X', '/'],
        ['8', '9'],
      ]) {
        final records = recordedBallThrows(
          Partida(total: 0, ballId: 'a', frames: [tokens]),
        );
        expect(records.every((r) => r.pins <= 10), isTrue);
        expect(records.length, lessThanOrEqualTo(1));
      }
    },
  );
  test(
    'partial unknown assignment is not treated as an exclusive whole game',
    () {
      final p = Partida(
        total: 150,
        ballId: 'a',
        frames: [
          ['8', '/'],
        ],
        ballIdsByThrow: {'0:1': null},
      );
      expect(p.hasUnassignedThrows, isTrue);
      expect(p.exclusivelyUsesBall('a'), isFalse);
      expect(BallStatsService.calcular([p], ballId: 'a').promedio, isNull);
      expect(
        StatsSelection.apply([
          session(p),
        ], const StatsFilter(withoutBall: true)).length,
        1,
      );
    },
  );
  test(
    'ball filters include shared games but unknown filter excludes fully assigned shared games',
    () {
      final p = Partida(
        total: 150,
        ballId: 'a',
        frames: [
          ['8', '/'],
        ],
        ballIdsByThrow: {'0:1': 'b'},
      );
      expect(
        StatsSelection.apply([
          session(p),
        ], const StatsFilter(ballId: 'b')).length,
        1,
      );
      expect(
        StatsSelection.apply([
          session(p),
        ], const StatsFilter(withoutBall: true)),
        isEmpty,
      );
    },
  );
  test(
    'group score average and deviation use exclusive games, usage includes shared games',
    () {
      final mixed = perfect(overrides: {'4:0': 'b'}),
          pure = perfect().copyWith(total: 200);
      final groups = StatisticsGroups.byBall(
        StatsSelection.games([session(mixed), session(pure)]),
      );
      final a = groups.singleWhere((g) => g.id == 'a'),
          b = groups.singleWhere((g) => g.id == 'b');
      expect(a.participations, 2);
      expect(a.summary.count, 1);
      expect(a.summary.mean, 200);
      expect(b.participations, 1);
      expect(b.summary.mean, isNull);
      expect(b.usage!.throwsCount, 1);
    },
  );
  test(
    'session JSON transport and copies preserve overrides including null',
    () {
      final p = perfect(overrides: {'0:0': null, '9:2': 'b'});
      final transported = Sesion.fromJson(
        jsonDecode(jsonEncode(session(p).toJson())) as Map<String, dynamic>,
      );
      expect(transported.partidas.single.ballIdsByThrow, p.ballIdsByThrow);
      expect(
        transported
            .copyWith(temporada: 'Updated')
            .partidas
            .single
            .ballForThrow(9, 2),
        'b',
      );
      expect(transported.partidas.single.total, 300);
    },
  );
  group('temporary Hive compatibility', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp(
        'bolometro_ball_throw_codec_',
      );
      Hive.init(dir.path);
    });
    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });
    test(
      'new adapter reads a seven-field legacy file and roundtrips new overrides',
      () async {
        Hive.registerAdapter<Partida>(OldPartidaAdapter(), override: true);
        var box = await Hive.openBox<Partida>('games');
        await box.put('stable-key', perfect());
        await box.close();
        Hive.registerAdapter<Partida>(PartidaAdapter(), override: true);
        box = await Hive.openBox<Partida>('games');
        expect(box.get('stable-key')!.ballIdsByThrow, isEmpty);
        await box.put(
          'stable-key',
          box
              .get('stable-key')!
              .copyWith(ballIdsByThrow: {'9:2': 'b', '0:0': null}),
        );
        await box.close();
        box = await Hive.openBox<Partida>('games');
        expect(box.get('stable-key')!.ballForThrow(9, 2), 'b');
        expect(box.get('stable-key')!.ballForThrow(0, 0), isNull);
        expect(box.keys.toList(), ['stable-key']);
        expect(box.get('stable-key')!.total, 300);
      },
    );
    test(
      'old readers ignore the new field; old writers cannot preserve it (documented upgrade requirement)',
      () async {
        Hive.registerAdapter<Partida>(PartidaAdapter(), override: true);
        var box = await Hive.openBox<Partida>('games');
        await box.put('one', perfect(overrides: {'4:0': 'b'}));
        await box.close();
        Hive.registerAdapter<Partida>(OldPartidaAdapter(), override: true);
        box = await Hive.openBox<Partida>('games');
        expect(box.get('one')!.total, 300);
        expect(box.get('one')!.ballId, 'a');
        expect(
          box.get('one')!.ballIdsByThrow,
          isEmpty,
        ); // Read-compatible, not write-compatible for the new feature.
      },
    );
  });
  group('draft isolation', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));
    test(
      'game drafts preserve assignments separately for A B and guest',
      () async {
        final frames = [
          ['8', '/'],
        ];
        final pins = List.generate(10, (_) => List<List<int>?>.filled(3, null));
        for (final uid in [null, 'a', 'b'])
          await DraftService.savePartidaDraft(
            ownerUid: uid,
            framesText: frames,
            pinesPorTiro: pins,
            ballId: uid ?? 'guest',
            ballIdsByThrow: {'0:1': 'spare-${uid ?? 'guest'}'},
          );
        expect(
          (await DraftService.loadPartidaDraft(
            ownerUid: 'a',
          ))!['ballIdsByThrow'],
          {'0:1': 'spare-a'},
        );
        expect(
          (await DraftService.loadPartidaDraft(ownerUid: 'b'))!['ballId'],
          'b',
        );
        await DraftService.clearPartidaDraft(ownerUid: 'a');
        expect(await DraftService.loadPartidaDraft(ownerUid: 'a'), isNull);
        expect((await DraftService.loadPartidaDraft())!['ballId'], 'guest');
        expect(
          (await DraftService.loadPartidaDraft(ownerUid: 'b'))!['ballId'],
          'b',
        );
      },
    );
    test(
      'session drafts preserve mixed assignments without cross-account restore',
      () async {
        final p = perfect(overrides: {'9:2': 'b'});
        await DraftService.saveSesionDraft(
          ownerUid: 'a',
          lugar: 'Test',
          tipo: 'Entrenamiento',
          temporada: 'Current',
          partidas: [p],
        );
        expect(await DraftService.loadSesionDraft(ownerUid: 'b'), isNull);
        final data = (await DraftService.loadSesionDraft(ownerUid: 'a'))!;
        expect(
          Partida.fromJson(
            Map<String, dynamic>.from((data['partidas'] as List).single as Map),
          ).ballForThrow(9, 2),
          'b',
        );
      },
    );
    test(
      'old unowned score draft is retained without assigning it to a new account',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'draft_partida_actual',
          jsonEncode({
            'framesText': ['X,,'],
          }),
        );
        expect(
          await DraftService.loadPartidaDraft(ownerUid: 'account-a'),
          isNull,
        );
        expect(await DraftService.loadPartidaDraft(), isNotNull);
        expect(prefs.getString('draft_partida_actual'), isNotNull);
      },
    );
    test(
      'legacy unowned drafts with ball references are kept for explicit guest ownership',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'draft_sesion_completa',
          jsonEncode({
            'partidas': [
              perfect(overrides: {'9:2': 'b'}).toJson(),
            ],
          }),
        );
        expect(
          await DraftService.loadSesionDraft(ownerUid: 'new-account'),
          isNull,
        );
        expect(prefs.getString('draft_sesion_completa'), isNotNull);
      },
    );
  });
}
