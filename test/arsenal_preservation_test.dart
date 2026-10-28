import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bolometro/exceptions/sync_exceptions.dart';
import 'package:bolometro/models/achievement.dart';
import 'package:bolometro/models/bowling_ball.dart';
import 'package:bolometro/models/nota.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/perfil_usuario.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/user_progress.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/services/firestore_service.dart';
import 'package:bolometro/utils/app_constants.dart';
import 'package:bolometro/services/arsenal_remote_store.dart';
import 'support/memory_arsenal_store.dart';

/// Never initializes Firebase. Every remote operation stays in this test double.
class ArsenalTestRemote extends FirestoreService {
  bool failNetwork = false;
  final reads = <String>[];
  final writes = <Map<String, dynamic>>[];

  @override
  Future<List<Sesion>> obtenerSesiones(String userId) async {
    reads.add(userId);
    if (failNetwork) throw NetworkException('Simulated unavailable network');
    return [];
  }

  @override
  Future<PerfilUsuario?> obtenerPerfil(String userId) async => null;

  @override
  Future<List<Nota>> obtenerNotas(
    String userId, {
    bool includeDeleted = false,
  }) async => [];

  @override
  Future<UserProgress?> obtenerProgreso(String userId) async => null;

  @override
  Future<List<Achievement>> obtenerLogros(String userId) async => [];

  @override
  Future<void> sincronizarDatosLocales(
    String userId,
    List<Sesion> sesionesLocales,
    PerfilUsuario? perfilLocal,
  ) async {
    writes.addAll(sesionesLocales.map((s) => s.toJson()));
    if (perfilLocal != null) writes.add({'nombre': perfilLocal.nombre});
  }
}

void main() {
  late Directory sandbox;
  late DataRepository repository;
  late ArsenalTestRemote remote;
  late MemoryArsenalStore backup;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('bolometro_arsenal_test_');
    Hive.init(sandbox.path);
    void register<T>(TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(adapter.typeId)) {
        Hive.registerAdapter<T>(adapter);
      }
    }

    register(PartidaAdapter());
    register(SesionAdapter());
    register(NotaAdapter());
    register(NotaAdjuntoAdapter());
    register(PerfilUsuarioAdapter());
    register(BowlingBallAdapter());
    register(BallMaintenanceAdapter());
    register(UserProgressAdapter());
    await Hive.openBox<Sesion>(AppConstants.boxSesiones);
    await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
    await Hive.openBox<Nota>(AppConstants.boxNotas);
    await Hive.openBox<BowlingBall>(AppConstants.boxBolas);
    await Hive.openBox<BallMaintenance>(AppConstants.boxMantenimientosBolas);
    remote = ArsenalTestRemote();
    backup = MemoryArsenalStore();
    repository = DataRepository(
      firestoreService: remote,
      arsenalRemote: backup,
      autoSyncArsenal: false,
      arsenalBackupEnabled: true,
    );
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    // Only this test's unique temporary directory; never application storage.
    await sandbox.delete(recursive: true);
  });

  Future<void> seedUser() async {
    await repository.setUser('account-a');
    await repository.crearBola(
      BowlingBall(id: 'ball-legacy', name: 'Personal ball', weightLbs: 15),
    );
    await repository.crearMantenimiento(
      BallMaintenance(id: 'maintenance-legacy', ballId: 'ball-legacy'),
    );
  }

  test(
    'logout preserves IDs and reopening restores balls and maintenance',
    () async {
      await seedUser();
      await repository.clearUserData();
      await repository.setUser(null);
      await repository.setUser('account-a');
      expect((await repository.listarTodasLasBolas()).single.id, 'ball-legacy');
      expect(
        (await repository.listarMantenimientosPorBola('ball-legacy')).single.id,
        'maintenance-legacy',
      );
      expect(remote.reads, isEmpty);
    },
  );

  test(
    'guest migration requires confirmation and preserves source and IDs',
    () async {
      await repository.crearBola(
        BowlingBall(id: 'guest-ball', name: 'Guest', weightLbs: 14),
      );
      await repository.crearMantenimiento(
        BallMaintenance(id: 'guest-maintenance', ballId: 'guest-ball'),
      );
      await repository.setUser('account-a');
      expect(await repository.listarTodasLasBolas(), isEmpty);
      expect(
        await repository.listarMantenimientosPorBola('guest-ball'),
        isEmpty,
      );
      await repository.importarArsenalInvitado();
      await repository.importarArsenalInvitado();
      expect((await repository.listarTodasLasBolas()).single.id, 'guest-ball');
      expect(
        (await repository.listarMantenimientosPorBola('guest-ball')).single.id,
        'guest-maintenance',
      );
      expect(Hive.box<BowlingBall>(AppConstants.boxBolas).length, 1);
      expect(
        Hive.box<BallMaintenance>(AppConstants.boxMantenimientosBolas).length,
        1,
      );
    },
  );

  test('account switching uses different local boxes', () async {
    await seedUser();
    await repository.setUser('account-b');
    expect(await repository.listarTodasLasBolas(), isEmpty);
    expect(
      await repository.listarMantenimientosPorBola('ball-legacy'),
      isEmpty,
    );
    await repository.setUser('account-a');
    expect((await repository.listarTodasLasBolas()).single.id, 'ball-legacy');
    expect(
      (await repository.listarMantenimientosPorBola('ball-legacy')).single.id,
      'maintenance-legacy',
    );
  });

  for (final operation in ['sync', 'upload', 'download']) {
    test('$operation backs up arsenal without replacing IDs', () async {
      await seedUser();
      switch (operation) {
        case 'sync':
          await repository.sincronizarANube();
        case 'upload':
          await repository.subirANube();
        case 'download':
          await repository.descargarDesdeNube();
      }
      expect(remote.reads, isNotEmpty);
      expect(remote.writes, isEmpty);
      expect(
        backup.records.keys,
        containsAll([
          'account-a/balls/ball-legacy',
          'account-a/ball_maintenance/maintenance-legacy',
        ]),
      );
      expect((await repository.listarTodasLasBolas()).single.id, 'ball-legacy');
      expect(
        (await repository.listarMantenimientosPorBola('ball-legacy')).single.id,
        'maintenance-legacy',
      );
    });
  }

  test('network failure leaves local arsenal intact', () async {
    await seedUser();
    remote.failNetwork = true;
    await expectLater(
      repository.sincronizarANube(),
      throwsA(isA<NetworkException>()),
    );
    expect(repository.isSyncing, isFalse);
    expect((await repository.listarTodasLasBolas()).single.id, 'ball-legacy');
    expect(
      (await repository.listarMantenimientosPorBola('ball-legacy')).single.id,
      'maintenance-legacy',
    );
  });

  test(
    'reinstall restores confirmed balls, archive state and maintenance',
    () async {
      await seedUser();
      await repository.archivarBola(
        (await repository.obtenerBola('ball-legacy'))!,
      );
      await repository.sincronizarArsenal();
      await Hive.close();
      Hive.init('${sandbox.path}/fresh-install');
      repository.dispose();
      repository = DataRepository(
        firestoreService: remote,
        arsenalRemote: backup,
        autoSyncArsenal: false,
        arsenalBackupEnabled: true,
      );
      await repository.setUser('account-a');
      expect(await repository.listarTodasLasBolas(), isEmpty);
      await repository.sincronizarArsenal();
      final ball = (await repository.obtenerBola('ball-legacy'))!;
      expect(ball.isActive, isFalse);
      expect(ball.id, 'ball-legacy');
      expect(
        (await repository.listarMantenimientosPorBola(ball.id)).single.id,
        'maintenance-legacy',
      );
    },
  );

  test(
    'offline edits survive logout, repository recreation and retry',
    () async {
      await seedUser();
      backup.writeError = StateError('unavailable');
      await expectLater(repository.sincronizarArsenal(), throwsStateError);
      expect(repository.arsenalSync!.pendingCount, 2);
      await repository.clearUserData();
      await repository.setUser('account-b');
      expect(await repository.listarTodasLasBolas(), isEmpty);
      await repository.setUser('account-a');
      backup.writeError = null;
      await repository.sincronizarArsenal();
      expect(repository.arsenalSync!.pendingCount, 0);
      expect(backup.records.length, 2);
    },
  );

  test(
    'lost acknowledgement retries one operation without duplicate revisions',
    () async {
      await seedUser();
      backup.loseNextAcknowledgement = true;
      await expectLater(repository.sincronizarArsenal(), throwsStateError);
      await repository.sincronizarArsenal();
      await repository.sincronizarArsenal();
      expect(backup.records.length, 2);
      expect(backup.operations.length, 2);
      expect(backup.records.values.every((r) => r.revision == 1), isTrue);
    },
  );

  test(
    'read and permission errors never erase local or pending data',
    () async {
      await seedUser();
      backup.writeError = PermissionException();
      await expectLater(
        repository.sincronizarArsenal(),
        throwsA(isA<PermissionException>()),
      );
      expect(repository.arsenalSync!.pendingCount, 2);
      backup.writeError = null;
      backup.readError = NetworkException();
      await expectLater(
        repository.sincronizarArsenal(),
        throwsA(isA<NetworkException>()),
      );
      expect(await repository.obtenerBola('ball-legacy'), isNotNull);
      expect(
        await repository.listarMantenimientosPorBola('ball-legacy'),
        hasLength(1),
      );
      expect(repository.arsenalSync!.hasConfirmedBackup, isFalse);
    },
  );

  test('claimed guest arsenal cannot be imported by another account', () async {
    await repository.crearBola(
      BowlingBall(id: 'guest', name: 'Guest', weightLbs: 14),
    );
    await repository.crearMantenimiento(
      BallMaintenance(id: 'gm', ballId: 'guest'),
    );
    await repository.setUser('account-a');
    await repository.importarArsenalInvitado();
    await repository.setUser('account-b');
    expect(await repository.bolasInvitadasDisponibles(), 0);
    await repository.importarArsenalInvitado();
    expect(await repository.listarTodasLasBolas(), isEmpty);
    expect(await repository.listarMantenimientosPorBola('guest'), isEmpty);
  });

  test('guest ID collision aborts without overwriting either copy', () async {
    await repository.crearBola(
      BowlingBall(id: 'same', name: 'Guest', weightLbs: 14),
    );
    await repository.setUser('account-a');
    await repository.crearBola(
      BowlingBall(id: 'same', name: 'Account', weightLbs: 15),
    );
    await expectLater(repository.importarArsenalInvitado(), throwsStateError);
    expect((await repository.obtenerBola('same'))!.name, 'Account');
    expect(
      Hive.box<BowlingBall>(AppConstants.boxBolas).get('same')!.name,
      'Guest',
    );
  });

  test(
    'guest migration preserves linked game identifiers and merges nonempty target',
    () async {
      await repository.crearBola(
        BowlingBall(id: 'guest', name: 'Guest', weightLbs: 14),
      );
      final date = DateTime(2026, 1, 2);
      await Hive.box<Sesion>(AppConstants.boxSesiones).add(
        Sesion(
          fecha: date,
          lugar: 'Test',
          tipo: AppConstants.tipoEntrenamiento,
          partidas: [Partida(total: 150, frames: [], ballId: 'guest')],
        ),
      );
      await seedUser();
      await repository.importarArsenalInvitado();
      expect(await repository.listarTodasLasBolas(), hasLength(2));
      final sessions = Hive.box<Sesion>(repository.sesionesBoxName);
      expect(sessions.values.single.fecha, date);
      expect(sessions.values.single.partidas.single.ballId, 'guest');
      await repository.importarArsenalInvitado();
      expect(sessions.length, 1);
    },
  );

  test('same model with different physical IDs is not deduplicated', () async {
    await seedUser();
    await repository.crearBola(
      BowlingBall(id: 'second', name: 'Personal ball', weightLbs: 15),
    );
    await repository.sincronizarArsenal();
    expect(await repository.listarTodasLasBolas(), hasLength(2));
  });

  test('duplicate create ID is rejected rather than overwriting', () async {
    await seedUser();
    await expectLater(
      repository.crearBola(
        BowlingBall(id: 'ball-legacy', name: 'Different', weightLbs: 12),
      ),
      throwsStateError,
    );
    expect(
      (await repository.obtenerBola('ball-legacy'))!.name,
      'Personal ball',
    );
  });

  test(
    'concurrent device edit keeps both variants and requires resolution',
    () async {
      await seedUser();
      await repository.sincronizarArsenal();
      final original = (await repository.obtenerBola('ball-legacy'))!;
      final other = original.copyWith(name: 'Remote device').toJson();
      await backup.write(
        'account-a',
        'balls',
        original.id,
        1,
        'other-device-op',
        other,
      );
      await repository.actualizarBola(
        original.copyWith(name: 'Offline device'),
      );
      await repository.sincronizarArsenal();
      expect(repository.arsenalSync!.conflicts, ['balls/ball-legacy']);
      expect(
        (await repository.obtenerBola(original.id))!.name,
        'Offline device',
      );
      expect(
        backup.records['account-a/balls/${original.id}']!.payload['name'],
        'Remote device',
      );
      expect(
        backup.variants.values.any((p) => p['name'] == 'Offline device'),
        isTrue,
      );
      await repository.arsenalSync!.resolve(
        'balls/ball-legacy',
        keepLocal: true,
      );
      await repository.sincronizarArsenal();
      expect(repository.arsenalSync!.conflicts, isEmpty);
      expect(
        backup.records['account-a/balls/${original.id}']!.payload['name'],
        'Offline device',
      );
    },
  );

  test(
    'account change during upload cannot apply results to new account',
    () async {
      await seedUser();
      backup.writeGate = Completer<void>();
      backup.writeEntered = Completer<void>();
      final uploading = repository.sincronizarArsenal();
      await backup.writeEntered!.future;
      await repository.clearUserData();
      await repository.setUser('account-b');
      backup.writeGate!.complete();
      await uploading;
      expect(await repository.listarTodasLasBolas(), isEmpty);
      expect(
        backup.records.keys.every((key) => key.startsWith('account-a/')),
        isTrue,
      );
      await repository.setUser('account-a');
      await repository.sincronizarArsenal();
      expect(await repository.listarTodasLasBolas(), hasLength(1));
    },
  );

  test(
    'edit during upload remains pending and is subsequently backed up',
    () async {
      await seedUser();
      backup.writeGate = Completer<void>();
      backup.writeEntered = Completer<void>();
      final uploading = repository.sincronizarArsenal();
      await backup.writeEntered!.future;
      final ball = (await repository.obtenerBola('ball-legacy'))!;
      await repository.actualizarBola(
        ball.copyWith(notes: 'Edited during network request'),
      );
      backup.writeGate!.complete();
      await uploading;
      expect(repository.arsenalSync!.pendingCount, 1);
      await repository.sincronizarArsenal();
      expect(
        backup.records['account-a/balls/ball-legacy']!.payload['notes'],
        'Edited during network request',
      );
    },
  );

  test(
    'journal replays interrupted save without changing identifiers',
    () async {
      await seedUser();
      final service = repository.arsenalSync!;
      final ball = (await repository.obtenerBola('ball-legacy'))!;
      final next = ball.copyWith(notes: 'Durable before local write').toJson();
      await service.journal.put('balls/ball-legacy', {
        'pending': true,
        'payload': next,
        'previousPayload': ball.toJson(),
        'operationId': 'crash-operation',
      });
      await repository.setUser(null);
      await repository.setUser('account-a');
      expect(
        (await repository.obtenerBola('ball-legacy'))!.notes,
        'Durable before local write',
      );
      await repository.sincronizarArsenal();
      expect(
        backup.records['account-a/balls/ball-legacy']!.payload['notes'],
        'Durable before local write',
      );
    },
  );

  test(
    'legacy edit with no queue is discovered without adapter migration',
    () async {
      await seedUser();
      await repository.sincronizarArsenal();
      final old = (await repository.obtenerBola('ball-legacy'))!;
      await repository.arsenalSync!.balls.put(
        old.id,
        old.copyWith(notes: 'Legacy client'),
      );
      await repository.setUser(null);
      await repository.setUser('account-a');
      expect(repository.arsenalSync!.pendingCount, 1);
      await repository.sincronizarArsenal();
      expect(
        backup.records['account-a/balls/ball-legacy']!.payload['notes'],
        'Legacy client',
      );
    },
  );

  test('test build restricts backup to fictional accounts in the allowlist', () async {
    repository.dispose();
    repository = DataRepository(firestoreService: remote, arsenalRemote: backup,
      autoSyncArsenal: true, arsenalBackupEnabled: true,
      arsenalBackupTestUids: {'allowed-fictional-account'});
    await seedUser();
    expect(repository.arsenalBackupEnabled, isFalse);
    await expectLater(repository.sincronizarArsenal(), throwsStateError);
    expect(backup.owners, isEmpty);
    expect(repository.arsenalSync!.pendingCount, 2);
    await repository.setUser('allowed-fictional-account');
    expect(repository.arsenalBackupEnabled, isTrue);
    await repository.sincronizarArsenal();
    expect(backup.owners, isNotEmpty);
    expect(backup.owners.every((uid) => uid == 'allowed-fictional-account'), isTrue);
    await repository.setUser('account-a');
    expect(repository.arsenalBackupEnabled, isFalse);
    expect((await repository.obtenerBola('ball-legacy'))!.id, 'ball-legacy');
  });

  test('empty allowlist never enables backup for an unintended account', () async {
    repository.dispose();
    repository = DataRepository(firestoreService: remote, arsenalRemote: backup,
      autoSyncArsenal: true, arsenalBackupEnabled: true,
      arsenalBackupTestUids: {' ', ''});
    await seedUser();
    expect(repository.arsenalBackupEnabled, isFalse);
    await expectLater(repository.sincronizarArsenal(), throwsStateError);
    expect(backup.owners, isEmpty);
  });

  test('allowlisted account remains disabled when main feature flag is false', () async {
    repository.dispose();
    repository = DataRepository(firestoreService: remote, arsenalRemote: backup,
      arsenalBackupEnabled: false, arsenalBackupTestUids: {'account-a'});
    await seedUser();
    expect(repository.arsenalBackupEnabled, isFalse);
    expect(backup.owners, isEmpty);
  });

  test('compile-time backup flag controls real sync with enabled default', () async {
    repository.dispose();
    repository = DataRepository(
      firestoreService: remote,
      arsenalRemote: backup,
      autoSyncArsenal: false,
    );
    await seedUser();
    const enabled = bool.fromEnvironment('ARSENAL_BACKUP_ENABLED', defaultValue: true);
    expect(repository.arsenalBackupEnabled, enabled);
    if (enabled) {
      await repository.sincronizarArsenal();
      expect(backup.records.keys, containsAll([
        'account-a/balls/ball-legacy', 'account-a/ball_maintenance/maintenance-legacy']));
      expect(repository.arsenalSync!.pendingCount, 0);
    } else {
      await expectLater(repository.sincronizarArsenal(), throwsStateError);
      expect(backup.owners, isEmpty);
      expect(repository.arsenalSync!.pendingCount, 2);
    }
  });

  test('default account login backs up existing inventory automatically', () async {
    await seedUser();
    repository.dispose();
    repository = DataRepository(firestoreService: remote, arsenalRemote: backup);
    await repository.setUser('account-a');
    await repository.arsenalSync!.sync();
    expect(backup.records.keys, containsAll([
      'account-a/balls/ball-legacy', 'account-a/ball_maintenance/maintenance-legacy']));
    expect(repository.arsenalSync!.pendingCount, 0);
    expect(backup.owners.every((uid) => uid == 'account-a'), isTrue);
  });

  test('explicit opt out keeps inventory local and does not contact backup', () async {
    repository.dispose();
    repository = DataRepository(firestoreService: remote, arsenalRemote: backup,
      arsenalBackupEnabled: false);
    await seedUser();
    expect(repository.arsenalBackupEnabled, isFalse);
    await expectLater(repository.sincronizarArsenal(), throwsStateError);
    await repository.sincronizarANube();
    expect(backup.owners, isEmpty);
    expect(repository.arsenalSync!.pendingCount, 2);
  });

  test(
    'history restores an earlier payload as a new revision of the same ID',
    () async {
      await seedUser();
      await repository.sincronizarArsenal();
      final original = (await repository.obtenerBola('ball-legacy'))!;
      await repository.actualizarBola(original.copyWith(notes: 'Later notes'));
      await repository.sincronizarArsenal();
      final versions = await repository.arsenalSync!.history(
        'balls',
        original.id,
      );
      final first = versions.firstWhere((v) => v.record.revision == 1);
      await repository.arsenalSync!.restoreVersion('balls', first);
      await repository.sincronizarArsenal();
      expect(backup.records['account-a/balls/${original.id}']!.revision, 3);
      expect((await repository.obtenerBola(original.id))!.notes, isNull);
      expect(
        (await repository.arsenalSync!.history('balls', original.id)),
        hasLength(3),
      );
    },
  );

  test(
    'restoring history cannot discard the only pending local edit',
    () async {
      await seedUser();
      await repository.sincronizarArsenal();
      final ball = (await repository.obtenerBola('ball-legacy'))!;
      final old = (await repository.arsenalSync!.history(
        'balls',
        ball.id,
      )).single;
      await repository.actualizarBola(ball.copyWith(notes: 'Only local copy'));
      await expectLater(
        repository.arsenalSync!.restoreVersion('balls', old),
        throwsStateError,
      );
      expect((await repository.obtenerBola(ball.id))!.notes, 'Only local copy');
    },
  );

  test(
    'malformed download does not invent defaults or replace local payload',
    () async {
      await seedUser();
      await repository.sincronizarArsenal();
      backup.records['account-a/balls/ball-legacy'] = const ArsenalRecord(
        'ball-legacy',
        2,
        {'id': 'ball-legacy', 'name': 'Malformed'},
      );
      await expectLater(repository.sincronizarArsenal(), throwsFormatException);
      expect(
        (await repository.obtenerBola('ball-legacy'))!.name,
        'Personal ball',
      );
      expect((await repository.obtenerBola('ball-legacy'))!.weightLbs, 15);
    },
  );

  test('empty remote never means deleting local records', () async {
    await seedUser();
    await repository.sincronizarArsenal();
    backup.records.clear();
    await expectLater(repository.sincronizarArsenal(), throwsStateError);
    expect(await repository.listarTodasLasBolas(), hasLength(1));
    expect(
      await repository.listarMantenimientosPorBola('ball-legacy'),
      hasLength(1),
    );
  });

  test(
    'concurrent imports from two accounts cannot claim the same guest record',
    () async {
      await repository.crearBola(
        BowlingBall(id: 'guest', name: 'Guest', weightLbs: 14),
      );
      await repository.setUser('account-a');
      final other = DataRepository(
        firestoreService: remote,
        arsenalRemote: backup,
        autoSyncArsenal: false,
        arsenalBackupEnabled: true,
      );
      await other.setUser('account-b');
      await Future.wait([
        repository.importarArsenalInvitado(),
        other.importarArsenalInvitado(),
      ]);
      expect(await repository.listarTodasLasBolas(), hasLength(1));
      expect(await other.listarTodasLasBolas(), isEmpty);
      other.dispose();
    },
  );

  test('legacy variant during interrupted save is backed up before choosing another', () async {
    await seedUser();
    final service = repository.arsenalSync!;
    final old = (await repository.obtenerBola('ball-legacy'))!;
    await service.journal.put('balls/ball-legacy', {'pending': true,
      'payload': old.copyWith(notes: 'Interrupted save').toJson(),
      'previousPayload': old.toJson(), 'operationId': 'interrupted'});
    await service.balls.put(old.id, old.copyWith(notes: 'Legacy edit after crash'));
    await repository.setUser(null);
    await repository.setUser('account-a');
    await repository.sincronizarArsenal();
    await repository.setUser(null);
    await repository.setUser('account-a');
    await repository.sincronizarArsenal();
    expect(backup.records['account-a/balls/${old.id}']!.payload['notes'], 'Interrupted save');
    await repository.arsenalSync!.resolve('balls/ball-legacy', keepLocal: false);
    await repository.sincronizarArsenal();
    final history = await repository.arsenalSync!.history('balls', old.id);
    expect(history.any((v) => v.record.payload['notes'] == 'Legacy edit after crash'), isTrue);
    expect(history.any((v) => v.record.payload['notes'] == 'Interrupted save'), isTrue);
  });
}
