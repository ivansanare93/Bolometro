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
import 'package:bolometro/utils/app_constants.dart';
import 'package:bolometro/widgets/seleccionar_bola_field.dart';

Widget _wrap(Widget child, DataRepository repo) {
  return ChangeNotifierProvider<DataRepository>.value(
    value: repo,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('SeleccionarBolaField', () {
    late DataRepository repository;
    late Directory sandbox;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp('bolometro_selector_test_');
      Hive.init(sandbox.path);

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PartidaAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SesionAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(PerfilUsuarioAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(NotaAdapter());
      }
      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(NotaAdjuntoAdapter());
      }
      if (!Hive.isAdapterRegistered(19)) {
        Hive.registerAdapter(BowlingBallAdapter());
      }
      if (!Hive.isAdapterRegistered(20)) {
        Hive.registerAdapter(BallMaintenanceAdapter());
      }

      await Hive.openBox<Sesion>(AppConstants.boxSesiones);
      await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
      await Hive.openBox<Nota>(AppConstants.boxNotas);
      await Hive.openBox<BowlingBall>(AppConstants.boxBolas);
      await Hive.openBox<BallMaintenance>(AppConstants.boxMantenimientosBolas);

      repository = DataRepository();
    });

    tearDown(() async {
      await Hive.close();
      await sandbox.delete(recursive: true);
    });

    testWidgets('shows "Sin especificar" when no ball is selected', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SeleccionarBolaField(ballId: null, onChanged: (_) {}),
          repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sin especificar'), findsOneWidget);
    });

    for (final dismissal in ['back', 'barrier', 'drag']) {
      testWidgets('cancel via $dismissal preserves selection without callback', (tester) async {
        await tester.runAsync(() => repository.crearBola(BowlingBall(id: 'selected', name: 'Selected', weightLbs: 15)));
        var calls = 0;
        await tester.pumpWidget(_wrap(SeleccionarBolaField(ballId: 'selected',
          onChanged: (_) => calls++), repository));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bola utilizada'));
        await tester.pumpAndSettle();
        if (dismissal == 'back') {
          await tester.binding.handlePopRoute();
        } else if (dismissal == 'barrier') {
          await tester.tapAt(const Offset(10, 10));
        } else {
          await tester.drag(find.byType(BottomSheet), const Offset(0, 600));
        }
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
        expect(calls, 0);
        expect(find.text('Selected'), findsOneWidget);
      });
    }

    testWidgets('explicit Sin especificar still clears an existing selection', (tester) async {
      await tester.runAsync(() => repository.crearBola(BowlingBall(id: 'selected', name: 'Selected', weightLbs: 15)));
      String? result = 'not-called';
      await tester.pumpWidget(_wrap(SeleccionarBolaField(ballId: 'selected',
        onChanged: (value) => result = value), repository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bola utilizada'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sin especificar'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('tapping opens a bottom sheet listing active balls', (tester) async {
      await tester.runAsync(() => repository.crearBola(
        BowlingBall(name: 'Storm Phaze II', weightLbs: 15),
      ));

      String? seleccionado = 'not-called';
      await tester.pumpWidget(
        _wrap(
          SeleccionarBolaField(
            ballId: null,
            onChanged: (value) => seleccionado = value,
          ),
          repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bola utilizada'));
      await tester.pumpAndSettle();

      expect(find.text('¿Con qué bola jugaste?'), findsOneWidget);
      expect(find.text('Storm Phaze II'), findsOneWidget);

      await tester.tap(find.text('Storm Phaze II'));
      await tester.pumpAndSettle();

      expect(seleccionado, isNot(equals('not-called')));
    });
  });
}
