import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/nota.dart';
import 'package:bolometro/models/perfil_usuario.dart';
import 'package:bolometro/models/bowling_ball.dart';
import 'package:bolometro/utils/app_constants.dart';

/// Tests para las funcionalidades de "Mis Bolas" en DataRepository:
/// CRUD de bolas, mantenimientos y asignación de bola a una partida.
void main() {
  group('DataRepository - Bolas', () {
    late DataRepository repository;

    setUp(() async {
      Hive.init('test_hive_bolas');

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

    test('crearBola guarda la bola y listarBolasActivas la devuelve', () async {
      final bola = BowlingBall(name: 'Storm Phaze II', weightLbs: 15);

      await repository.crearBola(bola);
      final activas = await repository.listarBolasActivas();

      expect(activas.length, equals(1));
      expect(activas.first.name, equals('Storm Phaze II'));
    });

    test('archivarBola hace soft delete: no aparece en activas pero sí en todas', () async {
      final bola = BowlingBall(name: 'Bola vieja', weightLbs: 14);
      await repository.crearBola(bola);

      await repository.archivarBola(bola);

      final activas = await repository.listarBolasActivas();
      final todas = await repository.listarTodasLasBolas();

      expect(activas, isEmpty);
      expect(todas.length, equals(1));
      expect(todas.first.isActive, isFalse);
    });

    test('actualizarBola persiste los cambios', () async {
      final bola = BowlingBall(name: 'Original', weightLbs: 14);
      await repository.crearBola(bola);

      final actualizada = bola.copyWith(name: 'Renombrada');
      await repository.actualizarBola(actualizada);

      final obtenida = await repository.obtenerBola(bola.id);
      expect(obtenida?.name, equals('Renombrada'));
    });

    test('asignarBolaAPartida actualiza el ballId de la partida en la sesión', () async {
      final partida = Partida(
        total: 150,
        frames: List.generate(10, (_) => ['5']),
      );
      final sesion = Sesion(
        fecha: DateTime(2024, 1, 1),
        lugar: 'Bolera Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [partida],
      );
      await repository.guardarSesion(sesion);

      final bola = BowlingBall(name: 'Mi bola', weightLbs: 15);
      await repository.crearBola(bola);

      await repository.asignarBolaAPartida(
        sesion: sesion,
        indicePartida: 0,
        ballId: bola.id,
      );

      final sesiones = await repository.obtenerSesiones();
      expect(sesiones.single.partidas.single.ballId, equals(bola.id));
    });

    test('obtenerPartidasPorBola devuelve solo las partidas de esa bola', () async {
      final bola = BowlingBall(name: 'Bola filtrada', weightLbs: 15);
      await repository.crearBola(bola);

      final partidaConBola = Partida(
        total: 200,
        frames: List.generate(10, (_) => ['X']),
        ballId: bola.id,
      );
      final partidaSinBola = Partida(
        total: 120,
        frames: List.generate(10, (_) => ['5']),
      );
      final sesion = Sesion(
        fecha: DateTime(2024, 2, 1),
        lugar: 'Bolera Test',
        tipo: AppConstants.tipoEntrenamiento,
        partidas: [partidaConBola, partidaSinBola],
      );
      await repository.guardarSesion(sesion);

      final partidas = await repository.obtenerPartidasPorBola(bola.id);

      expect(partidas.length, equals(1));
      expect(partidas.first.total, equals(200));
    });

    test('crearMantenimiento y listarMantenimientosPorBola', () async {
      final bola = BowlingBall(name: 'Bola mantenimiento', weightLbs: 15);
      await repository.crearBola(bola);

      final mantenimiento = BallMaintenance(
        ballId: bola.id,
        type: BallMaintenanceType.cleaning,
        date: DateTime(2024, 1, 15),
      );
      await repository.crearMantenimiento(mantenimiento);

      final registros = await repository.listarMantenimientosPorBola(bola.id);

      expect(registros.length, equals(1));
      expect(registros.first.type, equals(BallMaintenanceType.cleaning));
    });
  });
}
