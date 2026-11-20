import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:bolometro/models/bowling_ball.dart';
import 'package:bolometro/models/nota.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/perfil_usuario.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/screens/mis_bolas_screen.dart';
import 'package:bolometro/utils/app_constants.dart';

import 'support/memory_arsenal_store.dart';
import 'support/test_firestore_service.dart';

void main() {
  late Directory sandbox;
  late DataRepository repository;
  late MemoryArsenalStore remote;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('bolometro_conflict_ui_');
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
    await Hive.openBox<Sesion>(AppConstants.boxSesiones);
    await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
    await Hive.openBox<Nota>(AppConstants.boxNotas);
    await Hive.openBox<BowlingBall>(AppConstants.boxBolas);
    await Hive.openBox<BallMaintenance>(AppConstants.boxMantenimientosBolas);
    remote = MemoryArsenalStore();
  });

  tearDown(() async {
    repository.dispose();
    await Hive.close();
    await sandbox.delete(recursive: true);
  });

  Future<void> recoveredConflict({required bool enabled}) async {
    repository = DataRepository(
      firestoreService: TestFirestoreService(),
      arsenalRemote: remote,
      autoSyncArsenal: false,
      arsenalBackupEnabled: enabled,
    );
    await repository.setUser('fictional-conflict-account');
    final saved = BowlingBall(
      id: 'ball-conflict',
      name: 'Preserved ball',
      weightLbs: 14,
    );
    await repository.crearBola(saved);
    final service = repository.arsenalSync!;
    final state = service.conflict('balls/${saved.id}');
    await service.balls.put(
      saved.id,
      saved.copyWith(notes: 'Legacy device edit'),
    );
    await service.recover();
    expect(service.conflicts, ['balls/${saved.id}']);
    expect(service.conflict('balls/${saved.id}')['remotePayload'], isNull);
    expect(state['payload'], isNotNull);
  }

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<DataRepository>.value(
        value: repository,
        child: const MaterialApp(home: MisBolasScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> review(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.text('Revisar balls/ball-conflict'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('disabled backup does not offer account/device resolution', (
    tester,
  ) async {
    await tester.runAsync(() => recoveredConflict(enabled: false));
    await open(tester);
    await review(tester);
    expect(find.text('El respaldo está desactivado'), findsOneWidget);
    expect(find.text('Usar cuenta'), findsNothing);
    expect(find.text('Usar dispositivo'), findsNothing);
    expect(remote.owners, isEmpty);
    expect(repository.arsenalSync!.conflicts, hasLength(1));
  });

  for (final keepLocal in [true, false]) {
    testWidgets(
      'missing remote snapshot is synchronized before choosing keepLocal=$keepLocal',
      (tester) async {
        await tester.runAsync(() => recoveredConflict(enabled: true));
        await open(tester);
        await review(tester);
        expect(find.text('Dos versiones conservadas'), findsOneWidget);
        expect(remote.owners, isNotEmpty);
        expect(
          repository.arsenalSync!.conflict(
            'balls/ball-conflict',
          )['remotePayload'],
          isNotNull,
        );
        await tester.runAsync(() async {
          await tester.tap(
            find.text(keepLocal ? 'Usar dispositivo' : 'Usar cuenta'),
          );
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          expect(
            (await repository.obtenerBola('ball-conflict'))!.notes,
            keepLocal ? 'Legacy device edit' : null,
          );
          expect(repository.arsenalSync!.conflicts, isEmpty);
          final history = await repository.arsenalSync!.history(
            'balls',
            'ball-conflict',
          );
          expect(
            history.any(
              (v) => v.record.payload['notes'] == 'Legacy device edit',
            ),
            isTrue,
          );
          expect(history.any((v) => v.record.payload['notes'] == null), isTrue);
        });
        expect(find.textContaining('Synchronize to retrieve'), findsNothing);
      },
    );
  }

  testWidgets(
    'network failure preserves variants and offers retry without choosing',
    (tester) async {
      await tester.runAsync(() => recoveredConflict(enabled: true));
      remote.writeError = StateError('Simulated network error');
      await open(tester);
      await review(tester);
      expect(find.text('Usar cuenta'), findsNothing);
      expect(find.text('Usar dispositivo'), findsNothing);
      expect(
        find.textContaining('No se pudieron recuperar las versiones'),
        findsOneWidget,
      );
      expect(
        repository.arsenalSync!.conflict(
          'balls/ball-conflict',
        )['legacyVariant'],
        isNotNull,
      );
      remote.writeError = null;
      await review(tester);
      expect(find.text('Dos versiones conservadas'), findsOneWidget);
    },
  );

  testWidgets(
    'account change during preparation cannot show previous account choices',
    (tester) async {
      await tester.runAsync(() => recoveredConflict(enabled: true));
      final oldService = repository.arsenalSync!;
      await open(tester);
      await tester.runAsync(() async {
        remote.writeGate = Completer<void>();
        remote.writeEntered = Completer<void>();
        await tester.tap(find.text('Revisar balls/ball-conflict'));
        try {
          await remote.writeEntered!.future.timeout(const Duration(seconds: 3));
          await repository
              .setUser('fictional-second-account')
              .timeout(const Duration(seconds: 3));
        } finally {
          remote.writeGate!.complete();
        }
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(find.text('Usar cuenta'), findsNothing);
      expect(find.text('Usar dispositivo'), findsNothing);
      expect(oldService.paused, isTrue);
      await tester.runAsync(() async {
        expect(await repository.listarTodasLasBolas(), isEmpty);
      });
      expect(
        remote.records.keys.every(
          (key) => key.startsWith('fictional-conflict-account/'),
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'changing versions while dialog is open requires a fresh review',
    (tester) async {
      await tester.runAsync(() => recoveredConflict(enabled: true));
      await open(tester);
      await review(tester);
      final service = repository.arsenalSync!;
      final before = service.conflict('balls/ball-conflict');
      await tester.runAsync(() async {
        final latest = BowlingBall.fromJson(
          Map<String, dynamic>.from(before['remotePayload'] as Map),
        );
        await remote.write(
          'fictional-conflict-account',
          'balls',
          latest.id,
          before['remoteRevision'] as int,
          'external-edit',
          latest.copyWith(notes: 'Another device changed it').toJson(),
        );
        await service.sync();
      });
      await tester.pumpAndSettle();
      expect(
        service.conflict('balls/ball-conflict')['remoteRevision'],
        greaterThan(before['remoteRevision'] as int),
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Usar cuenta'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Las versiones han cambiado. Vuelve a revisarlas antes de elegir.',
        ),
        findsOneWidget,
      );
      expect(service.conflicts, hasLength(1));
      await tester.runAsync(() async {
        expect(
          (await repository.obtenerBola('ball-conflict'))!.notes,
          'Legacy device edit',
        );
      });
    },
  );
}
