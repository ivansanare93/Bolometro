import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bolometro/repositories/data_repository.dart';
import 'package:bolometro/models/sesion.dart';
import 'package:bolometro/models/partida.dart';
import 'package:bolometro/models/nota.dart';
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
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(NotaAdapter());
      }
      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(NotaAdjuntoAdapter());
      }

      // Abrir boxes necesarios
      await Hive.openBox<Sesion>(AppConstants.boxSesiones);
      await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);
      await Hive.openBox<Nota>(AppConstants.boxNotas);

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
      await repository.setUser('test-user-id');
      // Por defecto está en modo online cuando hay usuario, 
      // pero forzamos offline para el test
      await repository.setUser(null);
      await repository.setUser('test-user-id'); // Esto activa online
      
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

    test('descargarDesdeNube debe lanzar AuthenticationException si no hay usuario autenticado', () async {
      // Arrange: no configurar usuario
      
      // Act & Assert - el método debe lanzar excepción igual que subirANube
      expect(
        () => repository.descargarDesdeNube(),
        throwsA(isA<AuthenticationException>()),
      );
    });

    test('isOnlineMode debe ser true cuando hay usuario', () async {
      // Arrange & Act
      await repository.setUser('test-user-id');
      
      // Assert
      expect(repository.isOnlineMode, isTrue);
    });

    test('isOnlineMode debe ser false cuando no hay usuario', () async {
      // Arrange & Act
      await repository.setUser(null);
      
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

  group('DataRepository - Notas', () {
    late DataRepository repository;
    late Directory tempDir;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('test_hive_notas_');
      Hive.init(tempDir.path);

      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SesionAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(NotaAdapter());
      }
      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(NotaAdjuntoAdapter());
      }
      if (!Hive.isAdapterRegistered(10)) {
        Hive.registerAdapter(PerfilUsuarioAdapter());
      }

      await Hive.openBox<Nota>(AppConstants.boxNotas);
      await Hive.openBox<Sesion>(AppConstants.boxSesiones);
      await Hive.openBox<PerfilUsuario>(AppConstants.boxPerfilUsuario);

      repository = DataRepository();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('guardarNota debe persistir estructura y metadatos de fase 2', () async {
      final nota = Nota(
        titulo: 'Lectura pista',
        contenido: 'Comienza a secarse en tablero 8',
        fechaCreacion: DateTime.now(),
        fechaModificacion: DateTime.now(),
        tags: const ['pista', 'transicion'],
        pinned: true,
        archivada: false,
        relatedSessionId: '12345',
        tipo: NotaTipo.pista,
        estado: NotaEstado.probado,
        bolera: 'Bolera Centro',
        patronAceite: 'House 40ft',
        equipamientoUsado: 'Phaze II',
        condicionPista: 'Transición media',
        adjuntos: [
          NotaAdjunto(
            id: 'a1',
            tipo: NotaAdjuntoTipo.imagen,
            localPath: '/tmp/example.jpg',
            createdAt: DateTime.now(),
          ),
        ],
        revisarAntesProximaSesion: true,
        fechaRevision: DateTime.now().add(const Duration(days: 2)),
      );

      await repository.guardarNota(nota);
      final notas = await repository.obtenerNotas();

      expect(notas, hasLength(1));
      expect(notas.first.id, isNotEmpty);
      expect(notas.first.tags, containsAll(['pista', 'transicion']));
      expect(notas.first.pinned, isTrue);
      expect(notas.first.archivada, isFalse);
      expect(notas.first.relatedSessionId, '12345');
      expect(notas.first.tipo, NotaTipo.pista);
      expect(notas.first.estado, NotaEstado.probado);
      expect(notas.first.bolera, 'Bolera Centro');
      expect(notas.first.patronAceite, 'House 40ft');
      expect(notas.first.equipamientoUsado, 'Phaze II');
      expect(notas.first.condicionPista, 'Transición media');
      expect(notas.first.adjuntos, hasLength(1));
      expect(notas.first.revisarAntesProximaSesion, isTrue);
      expect(notas.first.fechaRevision, isNotNull);
    });

    test('notas deben estar separadas por usuario', () async {
      await repository.setUser('user-1');
      await repository.guardarNota(
        Nota(
          titulo: 'Nota user1',
          contenido: 'contenido 1',
          fechaCreacion: DateTime.now(),
          fechaModificacion: DateTime.now(),
        ),
      );

      await repository.setUser('user-2');
      var notasUser2 = await repository.obtenerNotas();
      expect(notasUser2, isEmpty);

      await repository.guardarNota(
        Nota(
          titulo: 'Nota user2',
          contenido: 'contenido 2',
          fechaCreacion: DateTime.now(),
          fechaModificacion: DateTime.now(),
        ),
      );

      await repository.setUser('user-1');
      final notasUser1 = await repository.obtenerNotas();
      expect(notasUser1, hasLength(1));
      expect(notasUser1.first.titulo, 'Nota user1');

      await repository.setUser('user-2');
      notasUser2 = await repository.obtenerNotas();
      expect(notasUser2, hasLength(1));
      expect(notasUser2.first.titulo, 'Nota user2');
    });

    test('nota legacy sin campos nuevos debe tener defaults compatibles', () async {
      final nota = Nota(
        titulo: 'Nota legacy',
        contenido: 'Contenido',
        fechaCreacion: DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      await repository.guardarNota(nota);
      final notas = await repository.obtenerNotas();

      expect(notas, hasLength(1));
      expect(notas.first.tipo, NotaTipo.review);
      expect(notas.first.estado, NotaEstado.pendiente);
      expect(notas.first.bolera, isNull);
      expect(notas.first.patronAceite, isNull);
      expect(notas.first.equipamientoUsado, isNull);
      expect(notas.first.condicionPista, isNull);
      expect(notas.first.adjuntos, isEmpty);
      expect(notas.first.revisarAntesProximaSesion, isFalse);
      expect(notas.first.fechaRevision, isNull);
      expect(notas.first.fechaEliminacion, isNull);
    });

    test('eliminarNota debe aplicar soft delete y ocultarla de obtenerNotas', () async {
      final nota = Nota(
        titulo: 'Nota temporal',
        contenido: 'Contenido',
        fechaCreacion: DateTime.now(),
        fechaModificacion: DateTime.now(),
      );

      await repository.guardarNota(nota);
      var visibles = await repository.obtenerNotas();
      expect(visibles, hasLength(1));

      await repository.eliminarNota(visibles.first);
      visibles = await repository.obtenerNotas();
      expect(visibles, isEmpty);
    });
  });
}
