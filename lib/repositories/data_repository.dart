import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import '../models/partida.dart';
import '../models/nota.dart';
import '../models/perfil_usuario.dart';
import '../models/user_progress.dart';
import '../models/achievement.dart';
import '../models/bowling_ball.dart';
import '../services/firestore_service.dart';
import '../services/arsenal_remote_store.dart';
import '../services/arsenal_sync_service.dart';
import '../utils/app_constants.dart';
import '../exceptions/sync_exceptions.dart';

/// Repositorio que abstrae el acceso a datos
/// Maneja tanto almacenamiento local (Hive) como remoto (Firestore)
class DataRepository extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final ArsenalRemoteStore _arsenalRemote;
  final bool autoSyncArsenal;
  final bool _arsenalBackupRequested;
  final Set<String>? _arsenalBackupTestUids;
  /// A local test build can restrict backup to explicitly chosen fictional UIDs.
  /// A defined but empty list disables backup for every account (fail closed).
  bool get arsenalBackupEnabled => _arsenalBackupRequested &&
      (_arsenalBackupTestUids == null || _arsenalBackupTestUids.contains(_userId));
  ArsenalSyncService? _arsenal;
  int _accountGeneration = 0;

  DataRepository({FirestoreService? firestoreService,
    ArsenalRemoteStore? arsenalRemote, this.autoSyncArsenal = true,
    bool? arsenalBackupEnabled, Set<String>? arsenalBackupTestUids})
      : _firestoreService = firestoreService ?? FirestoreService(),
        _arsenalRemote = arsenalRemote ?? FirestoreArsenalStore(),
        _arsenalBackupRequested = arsenalBackupEnabled ??
          const bool.fromEnvironment('ARSENAL_BACKUP_ENABLED', defaultValue: true),
        _arsenalBackupTestUids = arsenalBackupTestUids != null
          ? _normalizeTestUids(arsenalBackupTestUids)
          : const bool.hasEnvironment('ARSENAL_BACKUP_TEST_UIDS')
            ? _normalizeTestUids(const String.fromEnvironment('ARSENAL_BACKUP_TEST_UIDS').split(','))
            : null;

  static Set<String> _normalizeTestUids(Iterable<String> values) =>
      Set<String>.unmodifiable(values.map((value) => value.trim()).where((value) => value.isNotEmpty));

  String? get arsenalUserId => _userId;
  ArsenalSyncService? get arsenalSync => _arsenal;

  Future<void> sincronizarArsenal() async {
    if (!arsenalBackupEnabled) throw StateError('El respaldo remoto está pendiente de activación.');
    final service = _arsenal;
    if (service == null) throw AuthenticationException();
    await service.sync();
  }

  void _tryArsenalSync() {
    final service = _arsenal;
    if (!arsenalBackupEnabled || !autoSyncArsenal || service == null) return;
    unawaited(service.sync().catchError((Object error) {
      debugPrint('Arsenal conservado localmente; respaldo pendiente: $error');
    }));
  }

  static Future<void> _guestImportTail = Future.value();

  Future<int> bolasInvitadasDisponibles() async {
    if (_userId == null) return 0;
    final claims = await Hive.openBox<dynamic>('arsenal_guest_claims');
    final source = await Hive.openBox<BowlingBall>(AppConstants.boxBolas);
    return source.values.where((b) => claims.get('balls/${b.id}') == null ||
        claims.get('balls/${b.id}') == _userId).length;
  }

  /// Explicitly confirmed by the user. Claim before copy; retry is idempotent.
  /// A collision aborts before any existing account payload is overwritten.
  Future<void> importarArsenalInvitado() {
    final uid = _userId;
    final service = _arsenal;
    if (uid == null || service == null) throw AuthenticationException();
    final result = _guestImportTail.then((_) async {
      if (_userId != uid || service.paused) throw StateError('La cuenta ha cambiado');
      final claims = await Hive.openBox<dynamic>('arsenal_guest_claims');
      final sourceBalls = await Hive.openBox<BowlingBall>(AppConstants.boxBolas);
      final sourceMaintenance = await Hive.openBox<BallMaintenance>(AppConstants.boxMantenimientosBolas);
      final sourceSessions = await Hive.openBox<Sesion>(AppConstants.boxSesiones);
      final targetSessions = await _getSesionesBox();
      bool available(String key) => claims.get(key) == null || claims.get(key) == uid;
      final balls = sourceBalls.values.where((b) => available('balls/${b.id}')).toList();
      final ids = balls.map((b) => b.id).toSet();
      final maintenance = sourceMaintenance.values
          .where((m) => ids.contains(m.ballId) && available('ball_maintenance/${m.id}')).toList();
      final sessions = sourceSessions.values.where((s) =>
          s.partidas.any((p) => ids.contains(p.ballId)) &&
          s.partidas.every((p) => p.ballId == null || ids.contains(p.ballId)) &&
          available('sessions/${s.fecha.toIso8601String()}')).toList();
      void check(Map<String, dynamic>? target, Map<String, dynamic> source) {
        if (target != null && jsonEncode(target) != jsonEncode(source)) {
          throw StateError('Conflicto de IDs al importar. Ambas copias se conservan; no se ha sobrescrito el destino.');
        }
      }
      for (final ball in balls) check(service.balls.get(ball.id)?.toJson(), ball.toJson());
      for (final item in maintenance) check(service.maintenance.get(item.id)?.toJson(), item.toJson());
      for (final session in sessions) {
        final existing = targetSessions.values.where((s) => s.fecha == session.fecha);
        check(existing.isEmpty ? null : existing.first.toJson(), session.toJson());
      }
      Future<void> claim(String key) async {
        if (_userId != uid || service.paused) throw StateError('La cuenta ha cambiado');
        await claims.put(key, uid);
        await claims.flush();
      }
      for (final ball in balls) {
        await claim('balls/${ball.id}');
        await service.importIfAbsent('balls', ball.toJson());
      }
      for (final item in maintenance) {
        await claim('ball_maintenance/${item.id}');
        await service.importIfAbsent('ball_maintenance', item.toJson());
      }
      for (final session in sessions) {
        await claim('sessions/${session.fecha.toIso8601String()}');
        if (!targetSessions.values.any((s) => s.fecha == session.fecha)) {
          await targetSessions.add(session.copyWith(
            partidas: session.partidas.map((p) => p.copyWith()).toList()));
        }
      }
      notifyListeners();
      _tryArsenalSync();
    });
    _guestImportTail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  @override
  void dispose() {
    _arsenal?.paused = true;
    _arsenal = null;
    super.dispose();
  }
  
  String? _userId;
  bool _isOnlineMode = false;
  bool _isSyncing = false;

  bool get isOnlineMode => _isOnlineMode;
  bool get isSyncing => _isSyncing;
  
  /// Obtener nombre del box de sesiones actual
  String get sesionesBoxName => _getSesionesBoxName();
  
  /// Obtener nombre del box de perfil actual
  String get perfilBoxName => _getPerfilBoxName();

  /// Obtener nombre del box de notas actual
  String get notasBoxName => _getNotasBoxName();

  /// Obtener nombre del box de sesiones específico del usuario
  String _getSesionesBoxName() {
    if (_userId != null) {
      return '${AppConstants.boxSesiones}_$_userId';
    }
    return AppConstants.boxSesiones;
  }

  /// Obtener nombre del box de perfil específico del usuario
  String _getPerfilBoxName() {
    if (_userId != null) {
      return '${AppConstants.boxPerfilUsuario}_$_userId';
    }
    return AppConstants.boxPerfilUsuario;
  }

  /// Obtener nombre del box de notas específico del usuario
  String _getNotasBoxName() {
    if (_userId != null) {
      return '${AppConstants.boxNotas}_$_userId';
    }
    return AppConstants.boxNotas;
  }

  /// Obtener nombre del box de bolas específico del usuario
  String get bolasBoxName => _getBolasBoxName();
  String _getBolasBoxName() {
    if (_userId != null) {
      return '${AppConstants.boxBolas}_$_userId';
    }
    return AppConstants.boxBolas;
  }

  /// Obtener nombre del box de mantenimientos de bolas específico del usuario
  String get mantenimientosBolasBoxName => _getMantenimientosBolasBoxName();
  String _getMantenimientosBolasBoxName() {
    if (_userId != null) {
      return '${AppConstants.boxMantenimientosBolas}_$_userId';
    }
    return AppConstants.boxMantenimientosBolas;
  }

  /// Obtener box de sesiones, abriéndolo si es necesario
  Future<Box<Sesion>> _getSesionesBox() async {
    final boxName = _getSesionesBoxName();
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<Sesion>(boxName);
    }
    return Hive.box<Sesion>(boxName);
  }

  /// Obtener box de bolas, abriéndolo si es necesario
  Future<Box<BowlingBall>> _getBolasBox() async {
    final boxName = _getBolasBoxName();
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<BowlingBall>(boxName);
    }
    return Hive.box<BowlingBall>(boxName);
  }

  /// Obtener box de mantenimientos de bolas, abriéndolo si es necesario
  Future<Box<BallMaintenance>> _getMantenimientosBolasBox() async {
    final boxName = _getMantenimientosBolasBoxName();
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<BallMaintenance>(boxName);
    }
    return Hive.box<BallMaintenance>(boxName);
  }

  /// Obtener box de perfil, abriéndolo si es necesario
  Future<Box<PerfilUsuario>> _getPerfilBox() async {
    final boxName = _getPerfilBoxName();
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<PerfilUsuario>(boxName);
    }
    return Hive.box<PerfilUsuario>(boxName);
  }

  /// Sincronizar datos de gamificación en Firestore
  /// 
  /// Maneja la lógica de sincronización de progreso y logros:
  /// - Prioriza sincronizar progreso existente con logros
  /// - Si solo hay logros, crea progreso por defecto para preservarlos
  /// - Si no hay datos, no hace nada
  Future<void> _sincronizarGamificacion(String actionMessage, String completionMessage) async {
    try {
      debugPrint(actionMessage);
      
      final progressBox = await Hive.openBox<UserProgress>(AppConstants.boxUserProgress);
      final achievementsBox = await Hive.openBox<Achievement>(AppConstants.boxAchievements);
      
      final progressLocal = progressBox.isNotEmpty ? progressBox.getAt(0) : null;
      final achievementsLocal = achievementsBox.values.toList();
      
      // Lógica de sincronización:
      // 1. Caso normal: Hay progreso (con o sin logros) → sincronizar ambos
      // 2. Caso especial: Solo hay logros sin progreso → crear progreso por defecto para preservar logros
      if (progressLocal != null) {
        await _firestoreService.sincronizarGamificacion(
          _userId!,
          progressLocal,
          achievementsLocal, // Puede estar vacío si el usuario aún no ha desbloqueado logros
        );
        debugPrint('$completionMessage: ${achievementsLocal.length} logros');
      } else if (achievementsLocal.isNotEmpty) {
        // Si solo hay logros sin progreso, crear un progreso por defecto
        // UserProgress() crea: experiencePoints=0, currentLevel=1, unlockedAchievementIds=[]
        debugPrint('No hay progreso local, creando progreso por defecto para sincronizar logros');
        await _firestoreService.sincronizarGamificacion(
          _userId!,
          UserProgress(), // Crea: experiencePoints=0, currentLevel=1
          achievementsLocal,
        );
        debugPrint('$completionMessage con progreso por defecto');
      }
    } catch (e) {
      debugPrint('Error al sincronizar gamificación: $e');
      // Continuar con el resto de la sincronización
    }
  }

  /// Configurar el usuario autenticado y modo online
  Future<void> setUser(String? userId) async {
    final generation = ++_accountGeneration;
    final previous = _arsenal;
    _arsenal = null;
    if (previous != null) await previous.pause();
    if (generation != _accountGeneration) return;
    _userId = userId;
    _isOnlineMode = userId != null;
    
    // Asegurar que los boxes del usuario estén abiertos
    if (_userId != null) {
      await _getSesionesBox();
      await _getPerfilBox();
      await _getNotasBox();
      await _getBolasBox();
      await _getMantenimientosBolasBox();
      // Migrar datos guardados en modo offline al box del usuario autenticado.
      // Esto garantiza que los datos locales previos al primer inicio de sesión
      // estén disponibles cuando Firestore aún no los tenga (p.ej. primera vez
      // que el usuario inicia sesión con una cuenta de Google).
      await _migrarDatosOffline();
      if (generation != _accountGeneration) return;
      final balls = await _getBolasBox();
      final maintenance = await _getMantenimientosBolasBox();
      final journal = await Hive.openBox<dynamic>('arsenal_sync_$userId');
      if (generation != _accountGeneration) return;
      late final ArsenalSyncService service;
      service = ArsenalSyncService(uid: userId!, balls: balls,
        maintenance: maintenance, journal: journal, remote: _arsenalRemote,
        onChanged: () { if (identical(_arsenal, service)) notifyListeners(); });
      _arsenal = service;
      await service.recover();
      if (generation != _accountGeneration) { await service.pause(); return; }
      _tryArsenalSync();
    }
    
    notifyListeners();
  }

  /// Migra datos del box por defecto (modo offline) a los boxes específicos
  /// del usuario autenticado cuando dichos boxes están vacíos.
  ///
  /// Esto ocurre la primera vez que el usuario inicia sesión en un dispositivo
  /// donde ya tenía datos guardados en modo offline. La migración es segura
  /// porque [obtenerPerfil] siempre prioriza Firestore sobre Hive en modo
  /// online, por lo que el perfil remoto sobrescribirá el migrado si existe.
  Future<void> _migrarDatosOffline() async {
    try {
      final userPerfilBox = await _getPerfilBox();
      final userSesionesBox = await _getSesionesBox();
      final userNotasBox = await _getNotasBox();

      // Migrar perfil desde el box por defecto.
      // Nota: se incluye el fallback a getAt(0) para manejar el formato
      // heredado donde el perfil se guardaba con clave entera 0 antes de
      // migrar a la clave fija 'perfil'. El mismo patrón existe en
      // [obtenerPerfil] del repositorio.
      if (userPerfilBox.isEmpty && Hive.isBoxOpen(AppConstants.boxPerfilUsuario)) {
        final defaultPerfilBox = Hive.box<PerfilUsuario>(AppConstants.boxPerfilUsuario);
        final perfilOffline = defaultPerfilBox.get('perfil') ??
            (defaultPerfilBox.isNotEmpty ? defaultPerfilBox.getAt(0) : null);
        if (perfilOffline != null) {
          await userPerfilBox.put('perfil', perfilOffline.copyWith());
          debugPrint('Perfil offline migrado al box del usuario autenticado');
        }
      }

      // Migrar sesiones desde el box por defecto
      if (userSesionesBox.isEmpty && Hive.isBoxOpen(AppConstants.boxSesiones)) {
        final defaultSesionesBox = Hive.box<Sesion>(AppConstants.boxSesiones);
        if (defaultSesionesBox.isNotEmpty) {
          // Games linked to guest balls require explicit ownership selection.
          await userSesionesBox.addAll(defaultSesionesBox.values
              .where((s) => s.partidas.every((p) => p.ballId == null)).map((s) =>
              s.copyWith(partidas: s.partidas.map((p) => p.copyWith()).toList())));
          debugPrint(
            '${defaultSesionesBox.length} sesiones offline migradas al box del usuario autenticado',
          );
        }
      }

      // Migrar notas desde el box por defecto
      if (userNotasBox.isEmpty && Hive.isBoxOpen(AppConstants.boxNotas)) {
        final defaultNotasBox = Hive.box<Nota>(AppConstants.boxNotas);
        if (defaultNotasBox.isNotEmpty) {
          final notasMigradas = defaultNotasBox.values
              .map((n) => n.copyWith())
              .toList();
          await userNotasBox.addAll(notasMigradas);
          debugPrint(
            '${defaultNotasBox.length} notas offline migradas al box del usuario autenticado',
          );
        }
      }

      // Arsenal and its linked games are imported only by importarArsenalInvitado.
    } catch (e) {
      debugPrint('Error al migrar datos offline al usuario: $e');
    }
  }

  /// Cerrar la cuenta local sin eliminar su única copia de datos.
  /// Las cajas siguen aisladas por UID y se reabren al volver a esa cuenta.
  Future<void> clearUserData() async {
    if (_userId == null) return;
    ++_accountGeneration;

    final signingOutUserId = _userId;

    final sesionesBoxName = _getSesionesBoxName();
    final perfilBoxName = _getPerfilBoxName();
    final notasBoxName = _getNotasBoxName();
    final bolasBoxName = _getBolasBoxName();
    final mantenimientosBoxName = _getMantenimientosBolasBoxName();

    try {
      final service = _arsenal;
      _arsenal = null;
      if (service != null) await service.pause();
      // Cerrar boxes si están abiertas
      if (Hive.isBoxOpen(sesionesBoxName)) {
        await Hive.box<Sesion>(sesionesBoxName).close();
      }
      if (Hive.isBoxOpen(perfilBoxName)) {
        await Hive.box<PerfilUsuario>(perfilBoxName).close();
      }
      if (Hive.isBoxOpen(notasBoxName)) {
        await Hive.box<Nota>(notasBoxName).close();
      }
      if (Hive.isBoxOpen(bolasBoxName)) {
        await Hive.box<BowlingBall>(bolasBoxName).close();
      }
      if (Hive.isBoxOpen(mantenimientosBoxName)) {
        await Hive.box<BallMaintenance>(mantenimientosBoxName).close();
      }
      final journalName = 'arsenal_sync_$signingOutUserId';
      if (Hive.isBoxOpen(journalName)) await Hive.box<dynamic>(journalName).close();

      // Cerrar no implica borrar. Hive.close persiste las escrituras pendientes.
      // No desconectar una cuenta distinta si cambió durante los awaits.
      if (_userId == signingOutUserId) {
        _userId = null;
        _isOnlineMode = false;
        notifyListeners();
      }
      debugPrint('Cuenta local cerrada; datos conservados en sus cajas por UID');
    } catch (e) {
      debugPrint('No se pudo cerrar la cuenta local de forma segura: $e');
      rethrow;
    }
  }

  /// Obtener todas las sesiones
  Future<List<Sesion>> obtenerSesiones() async {
    try {
      if (_isOnlineMode && _userId != null) {
        // Modo online: obtener desde Firestore
        return await _firestoreService.obtenerSesiones(_userId!);
      } else {
        // Modo offline: obtener desde Hive
        final box = await _getSesionesBox();
        return box.values.toList();
      }
    } catch (e) {
      debugPrint('Error al obtener sesiones: $e');
      // Fallback a datos locales si falla Firestore
      try {
        final box = await _getSesionesBox();
        return box.values.toList();
      } catch (e) {
        debugPrint('Error al obtener sesiones desde Hive: $e');
        return [];
      }
    }
  }

  /// Obtener sesiones con paginación (para lazy loading)
  Future<List<Sesion>> obtenerSesionesPaginadas({
    int limite = 20,
    int offset = 0,
  }) async {
    try {
      if (_isOnlineMode && _userId != null) {
        // Modo online: usar paginación de Firestore
        return await _firestoreService.obtenerSesionesPaginadas(
          _userId!,
          limite: limite,
        );
      } else {
        // Modo offline: paginación local con Hive
        final box = await _getSesionesBox();
        final todasSesiones = box.values.toList();
        
        // Ordenar por fecha descendente
        todasSesiones.sort((a, b) => b.fecha.compareTo(a.fecha));
        
        final inicio = offset;
        final fin = (offset + limite).clamp(0, todasSesiones.length);
        
        if (inicio >= todasSesiones.length) {
          return [];
        }
        
        return todasSesiones.sublist(inicio, fin);
      }
    } catch (e) {
      debugPrint('Error al obtener sesiones paginadas: $e');
      return [];
    }
  }

  /// Guardar una nueva sesión
  Future<void> guardarSesion(Sesion sesion) async {
    try {
      // Guardar localmente primero
      final box = await _getSesionesBox();
      await box.add(sesion);

      // Si está online, guardar también en Firestore
      if (_isOnlineMode && _userId != null) {
        await _firestoreService.guardarSesion(_userId!, sesion);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar sesión: $e');
      rethrow;
    }
  }

  /// Actualizar una sesión existente (busca por fecha como identificador único)
  Future<void> actualizarSesion(Sesion sesion) async {
    try {
      final box = await _getSesionesBox();
      final sesionFecha = sesion.fecha.millisecondsSinceEpoch;
      final index = box.values.toList().indexWhere(
        (s) => s.fecha.millisecondsSinceEpoch == sesionFecha,
      );

      if (index != -1) {
        await box.putAt(index, sesion);
      } else {
        debugPrint('actualizarSesion: sesión no encontrada en Hive (fecha=$sesionFecha)');
      }

      if (_isOnlineMode && _userId != null) {
        await _firestoreService.guardarSesion(_userId!, sesion);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar sesión: $e');
      rethrow;
    }
  }

  /// Eliminar una sesión
  Future<void> eliminarSesion(Sesion sesion) async {
    try {
      // Eliminar localmente desde Hive usando fecha como identificador único
      final box = await _getSesionesBox();
      final sesionFecha = sesion.fecha.millisecondsSinceEpoch;
      final index = box.values.toList().indexWhere(
        (s) => s.fecha.millisecondsSinceEpoch == sesionFecha,
      );

      if (index != -1) {
        await box.deleteAt(index);
      }

      // Si está online, eliminar también de Firestore
      if (_isOnlineMode && _userId != null) {
        await _firestoreService.eliminarSesion(_userId!, sesion.fecha);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar sesión: $e');
      rethrow;
    }
  }

  /// Asigna [nuevaTemporada] a todas las [sesiones] indicadas (bulk).
  /// Persiste cada sesión actualizada en Hive y, si está en modo online,
  /// también en Firestore.  Notifica a los listeners una sola vez al final.
  Future<int> actualizarTemporadaEnLote(
    List<Sesion> sesiones,
    String? nuevaTemporada,
  ) async {
    int updated = 0;
    try {
      final box = await _getSesionesBox();
      final allSesiones = box.values.toList();

      for (final sesion in sesiones) {
        final millis = sesion.fecha.millisecondsSinceEpoch;
        final idx = allSesiones.indexWhere(
          (s) => s.fecha.millisecondsSinceEpoch == millis,
        );
        if (idx == -1) continue;

        final updatedSesion = sesion.copyWith(
          temporada: nuevaTemporada,
          clearTemporada: nuevaTemporada == null,
        );
        await box.putAt(idx, updatedSesion);
        allSesiones[idx] = updatedSesion;

        if (_isOnlineMode && _userId != null) {
          await _firestoreService.guardarSesion(_userId!, updatedSesion);
        }
        updated++;
      }

      if (updated > 0) notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar temporada en lote: $e');
      rethrow;
    }
    return updated;
  }

  // ===== Notas =====

  /// Obtener box de notas, abriéndolo si es necesario
  Future<Box<Nota>> _getNotasBox() async {
    final boxName = _getNotasBoxName();
    final box = !Hive.isBoxOpen(boxName)
        ? await Hive.openBox<Nota>(boxName)
        : Hive.box<Nota>(boxName);
    await _normalizarNotasBox(box);
    return box;
  }

  /// Garantiza que todas las notas estén indexadas por su [Nota.id].
  /// Esto evita duplicados al editar notas legacy guardadas con claves enteras.
  Future<void> _normalizarNotasBox(Box<Nota> box) async {
    final claves = box.keys.toList();
    final notasPorActualizar = <dynamic, Nota>{};
    final clavesParaEliminar = <dynamic>[];
    for (final key in claves) {
      final nota = box.get(key);
      if (nota == null) continue;
      if (key == nota.id) continue;
      notasPorActualizar[nota.id] = nota.copyWith();
      clavesParaEliminar.add(key);
    }

    if (notasPorActualizar.isNotEmpty) {
      await box.putAll(notasPorActualizar);
    }
    if (clavesParaEliminar.isNotEmpty) {
      await box.deleteAll(clavesParaEliminar);
    }
  }

  /// Obtener todas las notas
  Future<List<Nota>> obtenerNotas() async {
    try {
      if (_isOnlineMode && _userId != null) {
        await _sincronizarNotasConNube();
      }
      final box = await _getNotasBox();
      final notasActivas =
          box.values.where((n) => n.fechaEliminacion == null).toList();
      notasActivas.sort(
        (a, b) => b.fechaModificacion.compareTo(a.fechaModificacion),
      );
      return notasActivas;
    } catch (e) {
      debugPrint('Error al obtener notas: $e');
      return [];
    }
  }

  /// Guardar una nota nueva
  Future<void> guardarNota(Nota nota) async {
    try {
      final box = await _getNotasBox();
      final ahora = DateTime.now();
      nota.fechaModificacion = ahora;
      nota.fechaEliminacion = null;
      await box.put(nota.id, nota);
      if (_isOnlineMode && _userId != null) {
        await _firestoreService.guardarNota(_userId!, nota);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar nota: $e');
      rethrow;
    }
  }

  /// Actualizar una nota existente
  Future<void> actualizarNota(Nota nota) async {
    try {
      final box = await _getNotasBox();
      nota.fechaModificacion = DateTime.now();
      await box.put(nota.id, nota);
      if (_isOnlineMode && _userId != null) {
        await _firestoreService.guardarNota(_userId!, nota);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar nota: $e');
      rethrow;
    }
  }

  /// Eliminar una nota
  Future<void> eliminarNota(Nota nota) async {
    try {
      final box = await _getNotasBox();
      final ahora = DateTime.now();
      nota.fechaEliminacion = ahora;
      nota.fechaModificacion = ahora;
      await box.put(nota.id, nota);
      if (_isOnlineMode && _userId != null) {
        await _firestoreService.marcarNotaEliminada(_userId!, nota.id, ahora);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar nota: $e');
      rethrow;
    }
  }

  DateTime _notaVersion(Nota nota) {
    final deletedAt = nota.fechaEliminacion;
    if (deletedAt != null &&
        (deletedAt.isAfter(nota.fechaModificacion) ||
            deletedAt.isAtSameMomentAs(nota.fechaModificacion))) {
      return deletedAt;
    }
    return nota.fechaModificacion;
  }

  Future<void> _sincronizarNotasConNube() async {
    if (!_isOnlineMode || _userId == null) return;

    final box = await _getNotasBox();
    final notasLocales = box.values.toList();
    final notasRemotas = await _firestoreService.obtenerNotas(
      _userId!,
      includeDeleted: true,
    );

    final localesById = {for (final n in notasLocales) n.id: n};
    final remotasById = {for (final n in notasRemotas) n.id: n};
    final allIds = <String>{...localesById.keys, ...remotasById.keys};

    for (final id in allIds) {
      final local = localesById[id];
      final remote = remotasById[id];

      if (local == null && remote != null) {
        await box.put(id, remote);
        continue;
      }
      if (remote == null && local != null) {
        await _firestoreService.guardarNota(_userId!, local);
        continue;
      }
      if (local == null || remote == null) continue;

      final localVersion = _notaVersion(local);
      final remoteVersion = _notaVersion(remote);
      if (remoteVersion.isAfter(localVersion)) {
        await box.put(id, remote);
      } else if (localVersion.isAfter(remoteVersion)) {
        await _firestoreService.guardarNota(_userId!, local);
      }
    }
  }

  // ===== Bolas (equipación) =====

  /// Obtener todas las bolas activas (isActive == true), ordenadas por
  /// nombre. Usado para selección al registrar partidas.
  Future<List<BowlingBall>> listarBolasActivas() async {
    try {
      final box = await _getBolasBox();
      final activas = box.values.where((b) => b.isActive).toList();
      activas.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return activas;
    } catch (e) {
      debugPrint('Error al listar bolas activas: $e');
      return [];
    }
  }

  /// Obtener todas las bolas (activas y archivadas), ordenadas por fecha de
  /// creación descendente. Usado en el listado "Mis Bolas".
  Future<List<BowlingBall>> listarTodasLasBolas() async {
    try {
      final box = await _getBolasBox();
      final bolas = box.values.toList();
      bolas.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bolas;
    } catch (e) {
      debugPrint('Error al listar bolas: $e');
      return [];
    }
  }

  /// Buscar una bola por su id.
  Future<BowlingBall?> obtenerBola(String ballId) async {
    try {
      final box = await _getBolasBox();
      return box.get(ballId);
    } catch (e) {
      debugPrint('Error al obtener bola: $e');
      return null;
    }
  }

  /// Crear una nueva bola de bolos.
  Future<BowlingBall> crearBola(BowlingBall bola) async {
    final uid = _userId;
    final service = _arsenal;
    final box = await _getBolasBox();
    if (_userId != uid) throw StateError('La cuenta ha cambiado');
    if (box.containsKey(bola.id)) throw StateError('Ya existe una bola con este ID');
    if (uid != null) {
      if (service == null || service.uid != uid) throw StateError('Cuenta inicializándose');
      await service.save('balls', bola.toJson());
      _tryArsenalSync();
    } else {
      await box.put(bola.id, bola);
    }
    notifyListeners();
    return bola;
  }

  /// Actualizar una bola existente.
  Future<void> actualizarBola(BowlingBall bola) async {
    final uid = _userId;
    final service = _arsenal;
    final box = await _getBolasBox();
    if (_userId != uid) throw StateError('La cuenta ha cambiado');
    if (!box.containsKey(bola.id)) throw StateError('La bola no pertenece a esta cuenta');
    final updated = bola.copyWith(updatedAt: DateTime.now());
    if (uid != null) {
      if (service == null || service.uid != uid) throw StateError('Cuenta inicializándose');
      await service.save('balls', updated.toJson());
      _tryArsenalSync();
    } else {
      await box.put(updated.id, updated);
    }
    notifyListeners();
  }

  /// Archivar (soft delete) una bola. Se conserva para no perder el
  /// histórico de partidas/estadísticas asociadas a ella.
  Future<void> archivarBola(BowlingBall bola) async {
    await actualizarBola(bola.copyWith(isActive: false));
  }

  /// Reactivar una bola previamente archivada.
  Future<void> reactivarBola(BowlingBall bola) async {
    await actualizarBola(bola.copyWith(isActive: true));
  }

  /// Asigna (o quita, si [ballId] es null) una bola a la partida ubicada en
  /// el índice [indicePartida] dentro de [sesion], y persiste el cambio.
  Future<void> asignarBolaAPartida({
    required Sesion sesion,
    required int indicePartida,
    String? ballId,
  }) async {
    if (indicePartida < 0 || indicePartida >= sesion.partidas.length) {
      throw RangeError.index(indicePartida, sesion.partidas);
    }
    final partidas = List<Partida>.from(sesion.partidas);
    partidas[indicePartida] = partidas[indicePartida].copyWith(ballId: ballId);
    sesion.partidas = partidas;
    await actualizarSesion(sesion);
  }

  // ===== Mantenimiento de bolas =====

  /// Registrar un nuevo mantenimiento para una bola.
  Future<BallMaintenance> crearMantenimiento(BallMaintenance mantenimiento) async {
    final uid = _userId;
    final service = _arsenal;
    final box = await _getMantenimientosBolasBox();
    if (_userId != uid) throw StateError('La cuenta ha cambiado');
    if (box.containsKey(mantenimiento.id)) throw StateError('Ya existe este mantenimiento');
    final balls = await _getBolasBox();
    if (!balls.containsKey(mantenimiento.ballId)) throw StateError('Bola inexistente');
    if (uid != null) {
      if (service == null || service.uid != uid) throw StateError('Cuenta inicializándose');
      await service.save('ball_maintenance', mantenimiento.toJson());
      _tryArsenalSync();
    } else {
      await box.put(mantenimiento.id, mantenimiento);
    }
    notifyListeners();
    return mantenimiento;
  }

  /// Listar los mantenimientos registrados para una bola, más reciente primero.
  Future<List<BallMaintenance>> listarMantenimientosPorBola(String ballId) async {
    try {
      final box = await _getMantenimientosBolasBox();
      final registros = box.values.where((m) => m.ballId == ballId).toList();
      registros.sort((a, b) => b.date.compareTo(a.date));
      return registros;
    } catch (e) {
      debugPrint('Error al listar mantenimientos de la bola: $e');
      return [];
    }
  }

  /// Obtener todas las partidas (aplanando todas las sesiones) que usaron
  /// la bola indicada por [ballId]. Usado para calcular estadísticas por bola.
  Future<List<Partida>> obtenerPartidasPorBola(String ballId) async {
    final sesiones = await obtenerSesiones();
    final partidas = <Partida>[];
    for (final sesion in sesiones) {
      partidas.addAll(sesion.partidas.where((p) => p.ballId == ballId));
    }
    partidas.sort((a, b) {
      final fechaA = a.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
      final fechaB = b.fecha ?? DateTime.fromMillisecondsSinceEpoch(0);
      return fechaA.compareTo(fechaB);
    });
    return partidas;
  }

  /// Obtener perfil de usuario
  Future<PerfilUsuario?> obtenerPerfil() async {
    try {
      if (_isOnlineMode && _userId != null) {
        // Modo online: intentar obtener desde Firestore
        final perfilRemoto = await _firestoreService.obtenerPerfil(_userId!);
        if (perfilRemoto != null) {
          // Cachear el perfil remoto en Hive para que la UI pueda leerlo de
          // forma síncrona. Sin este paso, la pantalla de perfil (que lee
          // directamente de la box local en initState) vería una box vacía y
          // crearía un perfil en blanco, sobreescribiendo el dato real en
          // Firestore cuando se generara el código de amigo.
          final box = await _getPerfilBox();
          await box.put('perfil', perfilRemoto);
          debugPrint('Perfil remoto cacheado en Hive local');
          return perfilRemoto;
        }
      }

      // Modo offline o si no hay perfil remoto: obtener desde Hive
      final box = await _getPerfilBox();
      var perfil = box.get('perfil');
      // Migration: handle profiles saved with integer key 0 (legacy format)
      if (perfil == null && box.isNotEmpty) {
        perfil = box.getAt(0);
        if (perfil != null) {
          await box.put('perfil', perfil);
          await box.deleteAt(0);
          debugPrint('Perfil migrado a clave fija "perfil"');
        }
      }
      return perfil;
    } catch (e) {
      debugPrint('Error al obtener perfil: $e');
      return null;
    }
  }

  /// Guardar perfil de usuario
  Future<void> guardarPerfil(PerfilUsuario perfil) async {
    try {
      // Guardar localmente usando la clave fija 'perfil'
      final box = await _getPerfilBox();
      await box.put('perfil', perfil);

      // Si está online, guardar también en Firestore
      if (_isOnlineMode && _userId != null) {
        await _firestoreService.guardarPerfil(_userId!, perfil);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar perfil: $e');
      rethrow;
    }
  }

  /// Guardar perfil de usuario solo en el almacenamiento local (Hive).
  ///
  /// Úsese cuando se necesita persistir el perfil localmente sin arriesgar
  /// sobreescribir datos en Firestore —por ejemplo, al crear un perfil
  /// temporal durante el inicio de sesión antes de confirmar si Firestore
  /// ya tiene uno. La sincronización con Firestore la realizará después
  /// [sincronizarANube], que prioriza el perfil remoto como fuente de verdad.
  Future<void> guardarPerfilLocal(PerfilUsuario perfil) async {
    try {
      final box = await _getPerfilBox();
      await box.put('perfil', perfil);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar perfil localmente: $e');
      rethrow;
    }
  }

  /// Eliminar perfil de usuario
  Future<void> eliminarPerfil() async {
    try {
      // Eliminar localmente
      final box = await _getPerfilBox();
      await box.delete('perfil');

      // Si está online, eliminar también en Firestore
      if (_isOnlineMode && _userId != null) {
        await _firestoreService.eliminarPerfil(_userId!);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar perfil: $e');
      rethrow;
    }
  }

  /// Sincronizar datos locales a la nube
  /// 
  /// Realiza una sincronización bidireccional inteligente entre Hive y Firestore:
  /// 1. Descarga sesiones existentes en Firestore
  /// 2. Sube solo las sesiones locales que NO existen en la nube
  /// 3. Actualiza el almacenamiento local con los datos de la nube (verdad única)
  /// 
  /// Este enfoque evita que sesiones eliminadas de Firestore sean re-subidas,
  /// asegurando que Firestore sea la fuente de verdad para los datos sincronizados.
  /// 
  /// Requiere que el usuario esté autenticado.
  /// 
  /// Lanza:
  /// - [AuthenticationException] si el usuario no está autenticado
  /// - [OfflineModeException] si no hay conexión
  /// - [NetworkException] si hay problemas de red durante la sincronización
  /// - [PermissionException] si hay problemas de permisos en Firestore
  /// - [SyncException] para otros errores de sincronización
  Future<void> sincronizarANube() async {
    // Validar que el usuario está autenticado
    if (_userId == null) {
      throw AuthenticationException(
        'No se puede sincronizar: usuario no autenticado. '
        'Por favor, inicia sesión antes de sincronizar.'
      );
    }

    // Evitar sincronizaciones simultáneas
    if (_isSyncing) {
      debugPrint('Sincronización ya en curso, ignorando nueva solicitud');
      return;
    }

    // Validar modo online
    if (!_isOnlineMode) {
      throw OfflineModeException(
        'No se puede sincronizar: modo offline. '
        'Por favor, verifica tu conexión a Internet.'
      );
    }

    try {
      _isSyncing = true;
      notifyListeners();

      if (arsenalBackupEnabled) await sincronizarArsenal();
      debugPrint('Iniciando sincronización bidireccional...');

      // 1. Obtener sesiones existentes en Firestore (fuente de verdad)
      final sesionesRemotas = await _firestoreService.obtenerSesiones(_userId!);
      debugPrint('Sesiones en la nube: ${sesionesRemotas.length}');

      // Crear un Set de IDs de sesiones remotas para búsqueda rápida
      final idsRemotosSet = sesionesRemotas
          .map((s) => s.fecha.millisecondsSinceEpoch.toString())
          .toSet();

      // 2. Obtener datos locales desde Hive
      final boxSesiones = await _getSesionesBox();
      final sesionesLocales = boxSesiones.values.toList();
      debugPrint('Sesiones locales: ${sesionesLocales.length}');

      // Obtener perfil local y remoto para sincronización inteligente.
      // Firestore es la fuente de verdad: si ya existe un perfil en la nube
      // no lo sobreescribimos con la copia local (que podría ser incompleta
      // si se creó a partir de los datos de Google cuando Firestore no estaba
      // disponible temporalmente).
      final boxPerfil = await _getPerfilBox();
      final perfilLocal = boxPerfil.get('perfil');
      final perfilRemoto = await _firestoreService.obtenerPerfil(_userId!);

      // 3. Filtrar sesiones locales que NO existen en la nube
      final sesionesNuevas = sesionesLocales.where((sesion) {
        final id = sesion.fecha.millisecondsSinceEpoch.toString();
        return !idsRemotosSet.contains(id);
      }).toList();

      debugPrint('Sesiones nuevas a subir: ${sesionesNuevas.length}');

      // 4. Subir solo las sesiones nuevas.
      // El perfil se gestiona por separado (ver paso 5) para garantizar que
      // Firestore siempre sea la fuente de verdad.
      if (sesionesNuevas.isNotEmpty) {
        await _firestoreService.sincronizarDatosLocales(
          _userId!,
          sesionesNuevas,
          null, // El perfil se sincroniza de forma independiente abajo
        );
      }

      // 5. Sincronización de perfil: Firestore tiene prioridad sobre el local.
      // Si Firestore ya tiene un perfil, se usa como verdad única y se cachea
      // en Hive. Solo se sube el perfil local si Firestore no tiene ninguno,
      // evitando sobreescribir un perfil completo con uno mínimo creado a
      // partir de los datos de Google.
      if (perfilRemoto != null) {
        await boxPerfil.put('perfil', perfilRemoto);
        debugPrint('Perfil de Firestore usado como fuente de verdad');
      } else if (perfilLocal != null) {
        debugPrint('No hay perfil en Firestore, subiendo perfil local...');
        await _firestoreService.guardarPerfil(_userId!, perfilLocal);
      } else {
        debugPrint('No hay sesiones ni perfil para sincronizar');
      }

      // 6. Sincronizar datos de gamificación
      await _sincronizarGamificacion(
        'Sincronizando datos de gamificación...',
        'Datos de gamificación sincronizados',
      );

      // 6.1 Sincronizar notas con reconciliación por última modificación
      await _sincronizarNotasConNube();

      // 7. Obtener sesiones finales de la nube después de la subida
      debugPrint('Descargando estado final desde la nube...');
      final sesionesFinal = await _firestoreService.obtenerSesiones(_userId!);
      final notasFinal = await _firestoreService.obtenerNotas(
        _userId!,
        includeDeleted: true,
      );

      // 8. Actualizar almacenamiento local con datos de la nube (verdad única)
      // IMPORTANTE: Solo limpiamos después de confirmar que tenemos los datos de la nube
      debugPrint('Actualizando almacenamiento local con datos de la nube...');
      await boxSesiones.clear();
      await boxSesiones.addAll(sesionesFinal);
      final boxNotas = await _getNotasBox();
      await boxNotas.clear();
      for (final nota in notasFinal) {
        await boxNotas.put(nota.id, nota);
      }

      debugPrint('Sincronización bidireccional completada: ${sesionesFinal.length} sesiones totales');
      
      _isSyncing = false;
      notifyListeners();
    } on NetworkException {
      _isSyncing = false;
      notifyListeners();
      rethrow; // Re-lanzar la excepción específica
    } on PermissionException {
      _isSyncing = false;
      notifyListeners();
      rethrow; // Re-lanzar la excepción específica
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      
      // Convertir excepciones genéricas basándonos en el mensaje
      // (para compatibilidad con errores de Firebase que vienen como strings)
      final errorMsg = e.toString().toLowerCase();
      
      if (errorMsg.contains('network') || 
          errorMsg.contains('unavailable') ||
          errorMsg.contains('failed to connect')) {
        throw NetworkException(
          'Error de conexión durante la sincronización. '
          'Por favor, verifica tu conexión a Internet e intenta nuevamente.'
        );
      } else if (errorMsg.contains('permission') || 
                 errorMsg.contains('permission_denied')) {
        throw PermissionException(
          'Error de permisos durante la sincronización. '
          'Por favor, verifica que tienes los permisos necesarios en Firebase.'
        );
      } else {
        debugPrint('Error durante la sincronización: $e');
        throw SyncException(
          'Error durante la sincronización. '
          'Por favor, intenta nuevamente más tarde.',
          e is Exception ? e : null,
        );
      }
    }
  }

  /// Descargar datos desde la nube al almacenamiento local
  /// Sobrescribir los datos locales con los de la nube
  /// 
  /// Requiere que el usuario esté autenticado.
  /// 
  /// Lanza:
  /// - [AuthenticationException] si el usuario no está autenticado
  /// - [OfflineModeException] si no hay conexión
  Future<void> descargarDesdeNube() async {
    // Validar que el usuario está autenticado
    if (_userId == null) {
      throw AuthenticationException(
        'No se puede descargar: usuario no autenticado. '
        'Por favor, inicia sesión antes de sincronizar.'
      );
    }

    // Validar modo online
    if (!_isOnlineMode) {
      throw OfflineModeException(
        'No se puede descargar: modo offline. '
        'Por favor, verifica tu conexión a Internet.'
      );
    }

    // Evitar sincronizaciones simultáneas
    if (_isSyncing) {
      debugPrint('Sincronización ya en curso, ignorando nueva solicitud');
      return;
    }

    try {
      _isSyncing = true;
      notifyListeners();

      if (arsenalBackupEnabled) await sincronizarArsenal();
      debugPrint('Descargando datos desde la nube...');

      // Obtener sesiones desde Firestore
      final sesionesRemotas = await _firestoreService.obtenerSesiones(_userId!);
      
      // Guardar en Hive
      final boxSesiones = await _getSesionesBox();
      await boxSesiones.clear();
      for (final sesion in sesionesRemotas) {
        await boxSesiones.add(sesion);
      }

      // Obtener perfil desde Firestore
      final perfilRemoto = await _firestoreService.obtenerPerfil(_userId!);
      if (perfilRemoto != null) {
        final boxPerfil = await _getPerfilBox();
        await boxPerfil.clear();
        await boxPerfil.put('perfil', perfilRemoto);
      }

      // Obtener notas desde Firestore (incluyendo soft deleted para reconciliación)
      final notasRemotas = await _firestoreService.obtenerNotas(
        _userId!,
        includeDeleted: true,
      );
      final boxNotas = await _getNotasBox();
      await boxNotas.clear();
      for (final nota in notasRemotas) {
        await boxNotas.put(nota.id, nota);
      }

      // Obtener y guardar datos de gamificación desde Firestore
      try {
        debugPrint('Descargando datos de gamificación...');
        
        final progressRemoto = await _firestoreService.obtenerProgreso(_userId!);
        if (progressRemoto != null) {
          final progressBox = await Hive.openBox<UserProgress>(AppConstants.boxUserProgress);
          await progressBox.clear();
          await progressBox.add(progressRemoto);
          debugPrint('Progreso del usuario descargado');
        }
        
        final achievementsRemotos = await _firestoreService.obtenerLogros(_userId!);
        if (achievementsRemotos.isNotEmpty) {
          final achievementsBox = await Hive.openBox<Achievement>(AppConstants.boxAchievements);
          await achievementsBox.clear();
          for (var achievement in achievementsRemotos) {
            await achievementsBox.put(achievement.id, achievement);
          }
          debugPrint('${achievementsRemotos.length} logros descargados');
        }
      } catch (e) {
        debugPrint('Error al descargar datos de gamificación: $e');
        // Continuar sin gamificación si hay error
      }

      debugPrint(
        'Descarga completada: ${sesionesRemotas.length} sesiones, ${notasRemotas.length} notas',
      );

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      
      final errorMsg = e.toString().toLowerCase();
      
      if (errorMsg.contains('network') || 
          errorMsg.contains('unavailable') ||
          errorMsg.contains('failed to connect')) {
        throw NetworkException(
          'Error de conexión durante la descarga. '
          'Por favor, verifica tu conexión a Internet e intenta nuevamente.'
        );
      } else if (errorMsg.contains('permission') || 
                 errorMsg.contains('permission_denied')) {
        throw PermissionException(
          'Error de permisos durante la descarga. '
          'Por favor, verifica que tienes los permisos necesarios en Firebase.'
        );
      } else {
        debugPrint('Error al descargar desde la nube: $e');
        rethrow;
      }
    }
  }

  /// Subir todos los datos locales a la nube
  /// Sobrescribir completamente los datos de la nube con los datos locales
  /// 
  /// Este método es útil cuando el usuario quiere guardar su estado local actual,
  /// incluyendo sesiones eliminadas (que no estarán en la nube después de la subida).
  /// 
  /// Requiere que el usuario esté autenticado.
  /// 
  /// Lanza:
  /// - [AuthenticationException] si el usuario no está autenticado
  /// - [OfflineModeException] si no hay conexión
  /// - [SyncException] para otros errores de sincronización
  Future<void> subirANube() async {
    // Validar que el usuario está autenticado
    if (_userId == null) {
      throw AuthenticationException(
        'No se puede sincronizar: usuario no autenticado. '
        'Por favor, inicia sesión antes de sincronizar.'
      );
    }

    // Evitar sincronizaciones simultáneas
    if (_isSyncing) {
      debugPrint('Sincronización ya en curso, ignorando nueva solicitud');
      return;
    }

    // Validar modo online
    if (!_isOnlineMode) {
      throw OfflineModeException(
        'No se puede sincronizar: modo offline. '
        'Por favor, verifica tu conexión a Internet.'
      );
    }

    try {
      _isSyncing = true;
      notifyListeners();

      if (arsenalBackupEnabled) await sincronizarArsenal();
      debugPrint('Subiendo todos los datos locales a la nube...');

      // 1. Obtener todas las sesiones locales
      final boxSesiones = await _getSesionesBox();
      final sesionesLocales = boxSesiones.values.toList();
      debugPrint('Sesiones locales a subir: ${sesionesLocales.length}');
      final boxNotas = await _getNotasBox();
      final notasLocales = boxNotas.values.toList();
      debugPrint('Notas locales a subir: ${notasLocales.length}');

      // 2. Obtener perfil local
      final boxPerfil = await _getPerfilBox();
      final perfilLocal = boxPerfil.get('perfil');

      // 3. Eliminar todas las sesiones existentes en Firestore
      debugPrint('Eliminando sesiones existentes en la nube...');
      final sesionesRemotas = await _firestoreService.obtenerSesiones(_userId!);
      for (final sesionRemota in sesionesRemotas) {
        await _firestoreService.eliminarSesion(_userId!, sesionRemota.fecha);
      }

      // 4. Subir todas las sesiones locales
      debugPrint('Subiendo ${sesionesLocales.length} sesiones locales...');
      await _firestoreService.sincronizarDatosLocales(
        _userId!,
        sesionesLocales,
        perfilLocal,
      );

      // 4.1 Limpiar y subir todas las notas locales
      final notasRemotas = await _firestoreService.obtenerNotas(
        _userId!,
        includeDeleted: true,
      );
      for (final notaRemota in notasRemotas) {
        await _firestoreService.eliminarNotaFisica(_userId!, notaRemota.id);
      }
      for (final notaLocal in notasLocales) {
        await _firestoreService.guardarNota(_userId!, notaLocal);
      }

      // 5. Subir datos de gamificación
      await _sincronizarGamificacion(
        'Subiendo datos de gamificación...',
        'Datos de gamificación subidos',
      );

      debugPrint(
        'Subida completada: ${sesionesLocales.length} sesiones y ${notasLocales.length} notas en la nube',
      );

      _isSyncing = false;
      notifyListeners();
    } on NetworkException {
      _isSyncing = false;
      notifyListeners();
      rethrow;
    } on PermissionException {
      _isSyncing = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      
      final errorMsg = e.toString().toLowerCase();
      
      if (errorMsg.contains('network') || 
          errorMsg.contains('unavailable') ||
          errorMsg.contains('failed to connect')) {
        throw NetworkException(
          'Error de conexión durante la sincronización. '
          'Por favor, verifica tu conexión a Internet e intenta nuevamente.'
        );
      } else if (errorMsg.contains('permission') || 
                 errorMsg.contains('permission_denied')) {
        throw PermissionException(
          'Error de permisos durante la sincronización. '
          'Por favor, verifica que tienes los permisos necesarios en Firebase.'
        );
      } else {
        debugPrint('Error durante la subida: $e');
        throw SyncException(
          'Error durante la subida de datos. '
          'Por favor, intenta nuevamente más tarde.',
          e is Exception ? e : null,
        );
      }
    }
  }

  /// Stream de sesiones en tiempo real (solo en modo online)
  Stream<List<Sesion>>? streamSesiones() {
    if (_isOnlineMode && _userId != null) {
      return _firestoreService.streamSesiones(_userId!);
    }
    return null;
  }

  /// Submit app feedback to Firestore.
  Future<void> submitFeedback({
    required String userId,
    required String type,
    required String message,
    required String appVersion,
    required String platform,
    required String languageCode,
    String? authEmail,
    int? rating,
  }) async {
    await _firestoreService.submitFeedback(
      userId: userId,
      type: type,
      message: message,
      appVersion: appVersion,
      platform: platform,
      languageCode: languageCode,
      authEmail: authEmail,
      rating: rating,
    );
  }
}
