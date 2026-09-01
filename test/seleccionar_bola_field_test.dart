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

    setUp(() async {
      Hive.init('test_hive_seleccionar_bola');

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

    testWidgets('tapping opens a bottom sheet listing active balls', (tester) async {
      await repository.crearBola(
        BowlingBall(name: 'Storm Phaze II', weightLbs: 15),
      );

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
