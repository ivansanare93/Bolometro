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
import 'package:bolometro/screens/editar_bola_screen.dart';
import 'package:bolometro/screens/detalle_bola_screen.dart';
import 'package:bolometro/utils/app_constants.dart';
import 'support/test_firestore_service.dart';

Widget _wrap(Widget child, DataRepository repo) {
  return ChangeNotifierProvider<DataRepository>.value(
    value: repo,
    child: MaterialApp(home: child),
  );
}

void main() {
  group('MisBolasScreen', () {
    late DataRepository repository;
    late Directory sandbox;

    setUp(() async {
      sandbox = await Directory.systemTemp.createTemp('bolometro_mis_bolas_test_');
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

      repository = DataRepository(firestoreService: TestFirestoreService());
    });

    tearDown(() async {
      await Hive.close();
      await sandbox.delete(recursive: true);
    });

    testWidgets('shows empty state when there are no balls', (tester) async {
      await tester.pumpWidget(_wrap(const MisBolasScreen(), repository));
      await tester.pumpAndSettle();

      expect(find.text('Mis Bolas'), findsOneWidget);
      expect(find.text('Todavía no tienes bolas registradas'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('shows a card for each active ball', (tester) async {
      await tester.runAsync(() => repository.crearBola(
        BowlingBall(name: 'Storm Phaze II', brand: 'Storm', weightLbs: 15),
      ));
      await tester.runAsync(() => repository.crearBola(
        BowlingBall(name: 'Hammer Black Widow', weightLbs: 14),
      ));

      await tester.pumpWidget(_wrap(const MisBolasScreen(), repository));
      await tester.pumpAndSettle();

      expect(find.text('Storm Phaze II'), findsOneWidget);
      expect(find.text('Hammer Black Widow'), findsOneWidget);
    });

    for (final screen in ['list', 'edit', 'detail']) {
      testWidgets('$screen hides previous account data after account change', (tester) async {
        await tester.runAsync(() => repository.setUser('account-a'));
        final ball = BowlingBall(id: 'private', name: 'Private account A ball', weightLbs: 15);
        await tester.runAsync(() => repository.crearBola(ball));
        final Widget page = screen == 'list' ? const MisBolasScreen()
          : screen == 'edit' ? EditarBolaScreen(ball: ball) : DetalleBolaScreen(ball: ball);
        await tester.pumpWidget(_wrap(page, repository));
        await tester.pumpAndSettle();
        expect(find.text('Private account A ball'), findsWidgets);
        await tester.runAsync(() => repository.setUser('account-b'));
        await tester.pumpAndSettle();
        expect(find.text('Private account A ball'), findsNothing);
      });
    }
  });
}
