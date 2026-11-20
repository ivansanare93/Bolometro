import 'dart:io';

import 'package:bolometro/models/bowling_ball.dart';
import 'package:bolometro/models/nota.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/perfil_usuario.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/services/firestore_service.dart';
import 'package:bolometro/services/season_assignment_store.dart';
import 'package:bolometro/services/season_management_service.dart';
import 'package:bolometro/services/temporada_service.dart';
import 'package:bolometro/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/memory_arsenal_store.dart';

class _Remote extends FirestoreService {
  final accounts = <String, Map<int, Sesion>>{};
  bool fail = false;
  bool failReads = false;
  int calls = 0;
  @override
  Future<List<Sesion>> obtenerSesiones(String userId) async {
    if (failReads) throw StateError('simulated unavailable server list');
    return accounts[userId]?.values.toList() ?? [];
  }

  @override
  Future<List<Sesion>> obtenerSesionesDesdeServidor(String uid) =>
      obtenerSesiones(uid);
  @override
  Future<void> actualizarSoloTemporada(
    String uid,
    DateTime date,
    String? expected,
    String? target,
  ) async {
    calls++;
    if (fail) throw StateError('simulated network failure');
    final session = accounts[uid]?[date.millisecondsSinceEpoch];
    if (session == null) throw StateError('remote_session_missing');
    if (!shouldPatchSeason(session.temporada, expected, target)) return;
    accounts[uid]![date.millisecondsSinceEpoch] = session.copyWith(
      temporada: target,
      clearTemporada: target == null,
    );
  }

  @override
  Future<String?> obtenerTemporadaRemota(String uid, DateTime date) async =>
      accounts[uid]![date.millisecondsSinceEpoch]!.temporada;
  @override
  Future<void> respaldarSesionSiAusente(String uid, Sesion session) async {
    (accounts[uid] ??= {}).putIfAbsent(
      session.fecha.millisecondsSinceEpoch,
      () => session,
    );
  }
}

Sesion session({String? season = 'Liga', int day = 1}) => Sesion(
  fecha: DateTime(2026, 1, day),
  lugar: 'Test lane',
  tipo: 'Entrenamiento',
  temporada: season,
  notas: 'Keep notes',
  partidas: [
    Partida(
      frames: List.generate(10, (_) => ['1', '2', '']),
      total: 30,
      ballId: 'existing-personal-ball',
      pinesPorTiro: List.generate(
        10,
        (_) => [
          [1],
          [2, 3],
          null,
        ],
      ),
    ),
  ],
);

void main() {
  late Directory sandbox;
  late Box<Sesion> sessions;
  late Box<dynamic> journal;
  late _Remote remote;
  late DataRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sandbox = await Directory.systemTemp.createTemp('bolometro_season_safety_');
    Hive.init(sandbox.path);
    void register<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId))
        Hive.registerAdapter(adapter);
    }

    register(PartidaAdapter());
    register(SesionAdapter());
    register(NotaAdapter());
    register(NotaAdjuntoAdapter());
    register(PerfilUsuarioAdapter());
    register(BowlingBallAdapter());
    register(BallMaintenanceAdapter());
    sessions = await Hive.openBox<Sesion>(AppConstants.boxSesiones);
    journal = await Hive.openBox<dynamic>('test_season_journal');
    remote = _Remote();
    repo = DataRepository(
      firestoreService: remote,
      arsenalRemote: MemoryArsenalStore(),
      autoSyncArsenal: false,
    );
  });
  tearDown(() async {
    repo.dispose();
    await Hive.close();
    await sandbox.delete(recursive: true);
  });

  SeasonAssignmentStore store({
    bool online = false,
    bool Function()? current,
  }) => SeasonAssignmentStore(
    sessions: sessions,
    journal: journal,
    isCurrent: current ?? () => true,
    patchRemote: online
        ? (date, from, to) =>
              remote.actualizarSoloTemporada('qa', date, from, to)
        : null,
  );

  test(
    'default distinguishes no prior choice from explicit no-season',
    () async {
      expect(
        await TemporadaService.getTemporadaPredeterminada(now: DateTime(2030)),
        '2030',
      );
      await TemporadaService.setTemporadaActiva(null);
      expect(
        await TemporadaService.getTemporadaPredeterminada(now: DateTime(2030)),
        isNull,
      );
    },
  );

  test(
    'archived rename retains archive and updates all matching sessions',
    () async {
      final original = session();
      await sessions.put('original-key', original);
      await TemporadaService.addTemporada('Liga');
      await TemporadaService.archiveTemporada('Liga');
      await SeasonManagementService(repo).rename('Liga', 'Liga 2026');
      expect(await TemporadaService.getArchivedTemporadas(), ['Liga 2026']);
      expect(await TemporadaService.getTemporadas(), ['Liga 2026']);
      expect(sessions.keys.toList(), ['original-key']);
      final updated = sessions.get('original-key')!;
      final expected = original.toJson()..['temporada'] = 'Liga 2026';
      expect(updated.toJson(), expected);
      expect(await TemporadaService.getTemporadaActiva(), isNull);
    },
  );

  test(
    'names present only in sessions are discoverable and renameable',
    () async {
      await sessions.add(session());
      expect(await TemporadaService.getTemporadasConSesiones(sessions.values), [
        'Liga',
      ]);
      await SeasonManagementService(repo).rename('Liga', 'Recovered');
      expect(sessions.values.single.temporada, 'Recovered');
    },
  );

  test(
    'duplicate names differing only by case are rejected without changing sessions',
    () async {
      await sessions.add(session());
      await TemporadaService.addTemporada('Other');
      expect(await TemporadaService.addTemporada('other'), isFalse);
      await expectLater(
        SeasonManagementService(repo).rename('Liga', 'other'),
        throwsStateError,
      );
      expect(sessions.values.single.temporada, 'Liga');
    },
  );

  test(
    'archive clears default and cannot be reassigned or made default',
    () async {
      await sessions.add(session(season: 'Other'));
      await TemporadaService.addTemporada('Liga');
      await TemporadaService.setTemporadaActiva('Liga');
      await TemporadaService.archiveTemporada('Liga');
      expect(await TemporadaService.getTemporadaPredeterminada(), isNull);
      expect(await TemporadaService.getTemporadasDisponibles(sessions.values), [
        'Other',
      ]);
      await expectLater(
        repo.asignarTemporadaEnLote(sessions.values.toList(), 'Liga'),
        throwsStateError,
      );
      await expectLater(
        TemporadaService.setTemporadaActiva('Liga'),
        throwsStateError,
      );
    },
  );

  for (final target in <String?>[null, 'Other']) {
    test(
      'removal reassigns sessions to $target without deleting games or keys',
      () async {
        final first = session();
        final unaffected = session(season: 'Unaffected', day: 2);
        await sessions.putAll({'first': first, 'second': unaffected});
        await TemporadaService.addTemporada('Liga');
        await TemporadaService.addTemporada('Other');
        await SeasonManagementService(repo).remove('Liga', target);
        expect(sessions.length, 2);
        expect(
          sessions.get('first')!.toJson(),
          first.toJson()..['temporada'] = target,
        );
        expect(sessions.get('second')!.toJson(), unaffected.toJson());
        expect(await TemporadaService.getTemporadas(), isNot(contains('Liga')));
      },
    );
  }

  test(
    'stale selection and duplicate identifiers abort before changes',
    () async {
      final first = session();
      await sessions.put('one', first.copyWith(temporada: 'Newer'));
      await expectLater(
        store().assign([first], 'Target'),
        throwsA(isA<SeasonAssignmentConflict>()),
      );
      expect(journal.isEmpty, isTrue);
      expect(sessions.get('one')!.temporada, 'Newer');
      await sessions.put('two', first);
      await expectLater(store().assign([first], 'Target'), throwsStateError);
      expect(journal.isEmpty, isTrue);
    },
  );

  test(
    'interrupted local assignment recovers after closing and reopening Hive',
    () async {
      final first = session();
      await sessions.put('stable-key', first);
      await journal.put(first.fecha.millisecondsSinceEpoch.toString(), {
        'session': first.toJson(),
        'expected': 'Liga',
        'localExpected': 'Liga',
        'target': 'Recovered',
        'localApplied': false,
        'status': 'pending',
      });
      await journal.close();
      await sessions.close();
      sessions = await Hive.openBox<Sesion>(AppConstants.boxSesiones);
      journal = await Hive.openBox<dynamic>('test_season_journal');
      await store().retry();
      expect(sessions.keys.single, 'stable-key');
      expect(sessions.values.single.temporada, 'Recovered');
      expect(journal.isEmpty, isTrue);
    },
  );

  test(
    'network failure persists pending work and retry changes only season',
    () async {
      final first = session();
      remote.accounts['qa'] = {
        first.fecha.millisecondsSinceEpoch: first.copyWith(
          notas: 'Remote newer notes',
        ),
      };
      await sessions.put('stable-key', first);
      remote.fail = true;
      final result = await store(online: true).assign([first], 'Next');
      expect(result.updated, 1);
      expect(result.pending, 1);
      expect(result.conflicts, 0);
      expect(sessions.values.single.temporada, 'Next');
      await journal.close();
      journal = await Hive.openBox<dynamic>('test_season_journal');
      remote.fail = false;
      expect((await store(online: true).retry()).pending, 0);
      final cloud = remote.accounts['qa']!.values.single;
      expect(cloud.temporada, 'Next');
      expect(cloud.notas, 'Remote newer notes');
      expect(cloud.partidas.single.ballId, 'existing-personal-ball');
      expect(sessions.length, 1);
    },
  );

  test(
    'lost acknowledgement is idempotent and never creates a second session',
    () async {
      final first = session();
      remote.accounts['qa'] = {
        first.fecha.millisecondsSinceEpoch: first.copyWith(temporada: 'Next'),
      };
      await sessions.add(first);
      expect((await store(online: true).assign([first], 'Next')).pending, 0);
      expect(remote.accounts['qa']!.length, 1);
    },
  );

  test(
    'remote conflict never overwrites another device and retries do not hide it',
    () async {
      final first = session();
      remote.accounts['qa'] = {
        first.fecha.millisecondsSinceEpoch: first.copyWith(
          temporada: 'Other device',
        ),
      };
      await sessions.add(first);
      final result = await store(online: true).assign([first], 'Mine');
      expect(result.conflicts, 1);
      expect(remote.accounts['qa']!.values.single.temporada, 'Other device');
      final calls = remote.calls;
      await store(online: true).retry();
      expect(remote.calls, calls);
      expect(
        store()
            .overlay(remote.accounts['qa']!.values.toList())
            .single
            .temporada,
        'Mine',
      );
      await store(online: true).resolve(
        first.fecha.millisecondsSinceEpoch.toString(),
        'Other device',
        useLocal: false,
      );
      expect(sessions.values.single.temporada, 'Other device');
      expect(journal.isEmpty, isTrue);
    },
  );

  test(
    'explicit local conflict resolution still uses compare-and-set',
    () async {
      final first = session();
      remote.accounts['qa'] = {
        first.fecha.millisecondsSinceEpoch: first.copyWith(
          temporada: 'Other device',
        ),
      };
      await sessions.add(first);
      await store(online: true).assign([first], 'Mine');
      await expectLater(
        store(online: true).resolve(
          first.fecha.millisecondsSinceEpoch.toString(),
          'Outdated review',
          useLocal: true,
        ),
        throwsA(isA<SeasonAssignmentConflict>()),
      );
      expect(journal.isNotEmpty, isTrue);
      await store(online: true).resolve(
        first.fecha.millisecondsSinceEpoch.toString(),
        'Other device',
        useLocal: true,
      );
      expect(remote.accounts['qa']!.values.single.temporada, 'Mine');
      expect(journal.isEmpty, isTrue);
    },
  );

  test(
    'missing remote document remains pending and is not recreated',
    () async {
      await sessions.add(session());
      final result = await store(online: true).assign([session()], null);
      expect(result.pending, 1);
      expect(remote.accounts, isEmpty);
      expect(sessions.values.single.temporada, isNull);
    },
  );

  test(
    'account generation change stops writes before the local copy is altered',
    () async {
      await sessions.add(session());
      await expectLater(
        store(current: () => false).assign([session()], 'Other'),
        throwsStateError,
      );
      expect(sessions.values.single.temporada, 'Liga');
      expect(journal.isEmpty, isTrue);
    },
  );

  test(
    'repository pending changes survive logout and stay isolated by account',
    () async {
      final first = session();
      remote.accounts['qa-a'] = {first.fecha.millisecondsSinceEpoch: first};
      await repo.setUser('qa-a');
      remote.fail = true;
      expect((await repo.asignarTemporadaEnLote([first], 'Next')).pending, 1);
      expect((await repo.obtenerSesiones()).single.temporada, 'Next');
      await expectLater(repo.descargarDesdeNube(), throwsStateError);
      await expectLater(repo.subirANube(), throwsStateError);
      await expectLater(repo.sincronizarANube(), throwsStateError);
      await repo.clearUserData();
      await repo.setUser('qa-b');
      expect((await repo.estadoCambiosTemporada()).pending, 0);
      expect(await repo.obtenerSesiones(), isEmpty);
      await repo.setUser('qa-a');
      expect((await repo.estadoCambiosTemporada()).pending, 1);
      remote.fail = false;
      expect((await repo.reintentarCambiosTemporada()).pending, 0);
      expect((await repo.obtenerSesiones()).single.temporada, 'Next');
    },
  );

  test(
    'unreadable season metadata cannot be silently replaced by add or rename',
    () async {
      SharedPreferences.setMockInitialValues({
        AppConstants.prefKeyTemporadas: '{broken',
      });
      expect(await TemporadaService.addTemporada('New'), isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString(
          AppConstants.prefKeyTemporadas,
        ),
        '{broken',
      );
    },
  );

  test(
    'approved selection must still match before rename is applied',
    () async {
      await sessions.add(session());
      await expectLater(
        SeasonManagementService(
          repo,
        ).rename('Liga', 'Next', expectedSessionIds: {}),
        throwsStateError,
      );
      expect(sessions.values.single.temporada, 'Liga');
      expect(journal.isEmpty, isTrue);
    },
  );

  test('pending assignments prevent full-session edits and deletion', () async {
    final first = session();
    remote.accounts['qa'] = {first.fecha.millisecondsSinceEpoch: first};
    await repo.setUser('qa');
    remote.fail = true;
    await repo.asignarTemporadaEnLote([first], 'Next');
    await expectLater(
      repo.actualizarSesion(first.copyWith(notas: 'Changed')),
      throwsStateError,
    );
    await expectLater(repo.eliminarSesion(first), throwsStateError);
    expect((await repo.obtenerSesiones()).single.temporada, 'Next');
  });

  test(
    'missing remote session requires explicit approval and cannot overwrite a new remote document',
    () async {
      final first = session();
      await repo.setUser('qa');
      final token = repo.seasonAccountToken;
      await repo.asignarTemporadaEnLote([first], 'Next');
      expect(remote.accounts['qa'], isNull);
      final result = await repo.respaldarSesionPendienteAusente(
        first.fecha.millisecondsSinceEpoch.toString(),
        accountToken: token,
      );
      expect(result.pending, 0);
      expect(remote.accounts['qa']!.values.single.temporada, 'Next');
      expect(
        remote.accounts['qa']!.values.single.partidas.single.ballId,
        'existing-personal-ball',
      );
    },
  );

  test(
    'missing document appears concurrently: explicit backup preserves it and reports conflict',
    () async {
      final first = session();
      await repo.setUser('qa');
      await repo.asignarTemporadaEnLote([first], 'Next');
      remote.accounts['qa'] = {
        first.fecha.millisecondsSinceEpoch: first.copyWith(
          temporada: 'Another device',
          notas: 'New remote notes',
        ),
      };
      final result = await repo.respaldarSesionPendienteAusente(
        first.fecha.millisecondsSinceEpoch.toString(),
        accountToken: repo.seasonAccountToken,
      );
      expect(result.conflicts, 1);
      expect(remote.accounts['qa']!.values.single.notas, 'New remote notes');
      expect(remote.accounts['qa']!.values.single.temporada, 'Another device');
    },
  );

  test(
    'remote changes after review require reviewing conflict again',
    () async {
      final first = session();
      remote.accounts['qa'] = {
        first.fecha.millisecondsSinceEpoch: first.copyWith(temporada: 'Remote'),
      };
      await repo.setUser('qa');
      await repo.asignarTemporadaEnLote([first], 'Mine');
      await expectLater(
        repo.resolverConflictoTemporada(
          first.fecha.millisecondsSinceEpoch.toString(),
          'Outdated',
          useLocal: true,
          accountToken: repo.seasonAccountToken,
        ),
        throwsA(isA<SeasonAssignmentConflict>()),
      );
      expect(remote.accounts['qa']!.values.single.temporada, 'Remote');
      await repo.resolverConflictoTemporada(
        first.fecha.millisecondsSinceEpoch.toString(),
        'Remote',
        useLocal: false,
        accountToken: repo.seasonAccountToken,
      );
      expect((await repo.estadoCambiosTemporada()).pending, 0);
      expect((await repo.obtenerSesiones()).single.temporada, 'Remote');
    },
  );
  test('a legacy year suggestion cannot select an archived year', () async {
    await TemporadaService.addTemporada('2030');
    await TemporadaService.archiveTemporada('2030');
    expect(
      await TemporadaService.getTemporadaPredeterminada(now: DateTime(2030)),
      isNull,
    );
  });

  test('concurrent stores cannot replace a pending assignment', () async {
    final first = session();
    await sessions.put('stable-key', first);
    remote.fail = true;
    await expectLater(
      Future.wait([
        store(online: true).assign([first], 'First'),
        store(online: true).assign([first], 'Second'),
      ]),
      throwsStateError,
    );
    expect(sessions.values.single.temporada, 'First');
    expect(journal.length, 1);
    expect((journal.values.single as Map)['target'], 'First');
  });
  test('whole-season rename refuses an incomplete offline cache', () async {
    final first = session();
    remote.accounts['qa'] = {first.fecha.millisecondsSinceEpoch: first};
    await repo.setUser('qa');
    await TemporadaService.addTemporada('Liga');
    remote.failReads = true;
    await expectLater(
      SeasonManagementService(repo).rename('Liga', 'Next'),
      throwsStateError,
    );
    expect(await TemporadaService.getTemporadas(), ['Liga']);
    expect((await repo.estadoCambiosTemporada()).pending, 0);
    expect(remote.accounts['qa']!.values.single.temporada, 'Liga');
  });
}
