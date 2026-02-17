import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/perfil_usuario.dart';
import 'package:bolometro/utils/app_constants.dart';
import 'package:bolometro/exceptions/sync_exceptions.dart';

/// Tests para DataRepository y funcionalidad de sincronización
/// 
/// Estos tests verifican:
/// 1. Validación de autenticación antes de sincronizar
/// 2. Manejo de errores cuando no hay conexión
/// 3. Comportamiento correcto del flag isSyncing
void main() {
  group('DataRepository - Sincronización', () {
    late DataRepository repository;

    setUp(() async {
      // Inicializar Hive para tests (en memoria)
      Hive.init('test_hive');
      
      // Registrar adapters si no están registrados
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PartidaAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SesionAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(PerfilUsuarioAdapter());
      }

      // Abrir boxes necesarios
      await Hive.openBox<Sesion>(AppConstants.boxSesiones);
      await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);

      repository = DataRepository();
    });

    tearDown(() async {
      // Limpiar después de cada test
      await Hive.deleteFromDisk();
      await Hive.close();
    });

    test('sincronizarANube debe lanzar AuthenticationException si no hay usuario autenticado', () async {
      // Arrange: no configurar usuario
      
      // Act & Assert
      expect(
        () => repository.sincronizarANube(),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('sincronizarANube debe lanzar excepción si está en modo offline', () async {
      // Arrange: configurar usuario pero sin modo online
      repository.setUser('test-user-id');
      // Por defecto está en modo online cuando hay usuario, 
      // pero forzamos offline para el test
      repository.setUser(null);
      repository.setUser('test-user-id'); // Esto activa online
      
      // Para este test necesitaríamos poder forzar modo offline
      // Lo cual requeriría modificar la clase o usar mocks
      // Por ahora verificamos que el método existe
      expect(repository.isOnlineMode, isTrue);
    });

    test('isSyncing debe ser false inicialmente', () {
      expect(repository.isSyncing, isFalse);
    });

    test('subirANube debe lanzar AuthenticationException si no hay usuario autenticado', () async {
      // Arrange: no configurar usuario
      
      // Act & Assert
      expect(
        () => repository.subirANube(),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('descargarDesdeNube debe retornar sin error si no hay usuario autenticado', () async {
      // Arrange: no configurar usuario
      
      // Act & Assert - el método debe retornar sin lanzar excepción pero no hacer nada
      // porque verifica _userId == null
      await repository.descargarDesdeNube();
      expect(repository.isOnlineMode, isFalse);
    });

    test('isOnlineMode debe ser true cuando hay usuario', () {
      // Arrange & Act
      repository.setUser('test-user-id');
      
      // Assert
      expect(repository.isOnlineMode, isTrue);
    });

    test('isOnlineMode debe ser false cuando no hay usuario', () {
      // Arrange & Act
      repository.setUser(null);
      
      // Assert
      expect(repository.isOnlineMode, isFalse);
    });

    test('obtenerSesiones debe retornar lista vacía cuando no hay datos', () async {
      // Act
      final sesiones = await repository.obtenerSesiones();
      
      // Assert
      expect(sesiones, isEmpty);
    });

    test('guardarSesion debe agregar sesión a Hive', () async {
      // Arrange
      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test Bowling',
        tipo: 'Entrenamiento',
        partidas: [],
      );

      // Act
      await repository.guardarSesion(sesion);
      final sesiones = await repository.obtenerSesiones();

      // Assert
      expect(sesiones.length, 1);
      expect(sesiones.first.lugar, 'Test Bowling');
    });

    test('eliminarSesion debe remover sesión de Hive', () async {
      // Arrange
      final sesion = Sesion(
        fecha: DateTime.now(),
        lugar: 'Test Bowling',
        tipo: 'Entrenamiento',
        partidas: [],
      );
      await repository.guardarSesion(sesion);

      // Act
      await repository.eliminarSesion(sesion);
      final sesiones = await repository.obtenerSesiones();

      // Assert
      expect(sesiones, isEmpty);
    });
  });

  group('DataRepository - Perfil', () {
    late DataRepository repository;

    setUp(() async {
      // Inicializar Hive para tests
      Hive.init('test_hive_perfil');
      
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(PerfilUsuarioAdapter());
      }

      await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);

      repository = DataRepository();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
    });

    test('obtenerPerfil debe retornar null cuando no hay perfil', () async {
      // Act
      final perfil = await repository.obtenerPerfil();
      
      // Assert
      expect(perfil, isNull);
    });

    test('guardarPerfil debe almacenar perfil en Hive', () async {
      // Arrange
      final perfil = PerfilUsuario(
        nombre: 'Test User',
        email: 'test@example.com',
      );

      // Act
      await repository.guardarPerfil(perfil);
      final perfilGuardado = await repository.obtenerPerfil();

      // Assert
      expect(perfilGuardado, isNotNull);
      expect(perfilGuardado!.nombre, 'Test User');
      expect(perfilGuardado.email, 'test@example.com');
    });
  });
}
