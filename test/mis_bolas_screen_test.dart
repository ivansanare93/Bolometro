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

Widget _wrap(Widget child, DataRepository repo) {
  return ChangeNotifierProvider<DataRepository>.value(
    value: repo,
    child: MaterialApp(home: child),
  );
}

void main() {
  group('MisBolasScreen', () {
    late DataRepository repository;

    setUp(() async {
      Hive.init('test_hive_mis_bolas');

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
      await Hive.deleteFromDisk();
      await Hive.close();
    });

    testWidgets('shows empty state when there are no balls', (tester) async {
      await tester.pumpWidget(_wrap(const MisBolasScreen(), repository));
      await tester.pumpAndSettle();

      expect(find.text('Mis Bolas'), findsOneWidget);
      expect(find.text('Todavía no tienes bolas registradas'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets);
    });

    testWidgets('shows a card for each active ball', (tester) async {
      await repository.crearBola(
        BowlingBall(name: 'Storm Phaze II', brand: 'Storm', weightLbs: 15),
      );
      await repository.crearBola(
        BowlingBall(name: 'Hammer Black Widow', weightLbs: 14),
      );

      await tester.pumpWidget(_wrap(const MisBolasScreen(), repository));
      await tester.pumpAndSettle();

      expect(find.text('Storm Phaze II'), findsOneWidget);
      expect(find.text('Hammer Black Widow'), findsOneWidget);
    });
  });
}
