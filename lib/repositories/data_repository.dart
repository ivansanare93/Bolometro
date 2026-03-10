import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import '../models/nota.dart';
import '../models/perfil_usuario.dart';
import '../models/user_progress.dart';
import '../models/achievement.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';
import '../exceptions/sync_exceptions.dart';

/// Repositorio que abstrae el acceso a datos
/// Maneja tanto almacenamiento local (Hive) como remoto (Firestore)
class DataRepository extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _userId;
  bool _isOnlineMode = false;
  bool _isSyncing = false;

  bool get isOnlineMode => _isOnlineMode;
  bool get isSyncing => _isSyncing;
  
  /// Obtener nombre del box de sesiones actual
  String get sesionesBoxName => _getSesionesBoxName();
  
  /// Obtener nombre del box de perfil actual
  String get perfilBoxName => _getPerfilBoxName();

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

  /// Obtener box de sesiones, abriéndolo si es necesario
  Future<Box<Sesion>> _getSesionesBox() async {
    final boxName = _getSesionesBoxName();
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<Sesion>(boxName);
    }
    return Hive.box<Sesion>(boxName);
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
    _userId = userId;
    _isOnlineMode = userId != null;
    
    // Asegurar que los boxes del usuario estén abiertos
    if (_userId != null) {
      await _getSesionesBox();
      await _getPerfilBox();
    }
    
    notifyListeners();
  }

  /// Limpiar datos locales del usuario cuando cierra sesión
  Future<void> clearUserData() async {
    if (_userId != null) {
      try {
        final sesionesBoxName = _getSesionesBoxName();
        final perfilBoxName = _getPerfilBoxName();
        
        // Cerrar y eliminar boxes del usuario
        if (Hive.isBoxOpen(sesionesBoxName)) {
          await Hive.box<Sesion>(sesionesBoxName).clear();
          await Hive.box<Sesion>(sesionesBoxName).close();
        }
        if (Hive.isBoxOpen(perfilBoxName)) {
          await Hive.box<PerfilUsuario>(perfilBoxName).clear();
          await Hive.box<PerfilUsuario>(perfilBoxName).close();
        }
        
        debugPrint('Datos locales del usuario limpiados');
      } catch (e) {
        debugPrint('Error al limpiar datos locales: $e');
      }
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

  /// Eliminar una sesión
  Future<void> eliminarSesion(Sesion sesion) async {
    try {
      // Eliminar localmente desde Hive usando el índice
      final box = await _getSesionesBox();
      final sesiones = box.values.toList();
      final index = sesiones.indexOf(sesion);
      
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

  // ===== Notas =====

  /// Obtener box de notas, abriéndolo si es necesario
  Future<Box<Nota>> _getNotasBox() async {
    if (!Hive.isBoxOpen(AppConstants.boxNotas)) {
      return await Hive.openBox<Nota>(AppConstants.boxNotas);
    }
    return Hive.box<Nota>(AppConstants.boxNotas);
  }

  /// Obtener todas las notas
  Future<List<Nota>> obtenerNotas() async {
    try {
      final box = await _getNotasBox();
      return box.values.toList().reversed.toList();
    } catch (e) {
      debugPrint('Error al obtener notas: $e');
      return [];
    }
  }

  /// Guardar una nota nueva
  Future<void> guardarNota(Nota nota) async {
    try {
      final box = await _getNotasBox();
      await box.add(nota);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al guardar nota: $e');
      rethrow;
    }
  }

  /// Actualizar una nota existente
  Future<void> actualizarNota(Nota nota) async {
    try {
      await nota.save();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar nota: $e');
      rethrow;
    }
  }

  /// Eliminar una nota
  Future<void> eliminarNota(Nota nota) async {
    try {
      await nota.delete();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar nota: $e');
      rethrow;
    }
  }

  /// Obtener perfil de usuario
  Future<PerfilUsuario?> obtenerPerfil() async {
    try {
      if (_isOnlineMode && _userId != null) {
        // Modo online: intentar obtener desde Firestore
        final perfilRemoto = await _firestoreService.obtenerPerfil(_userId!);
        if (perfilRemoto != null) {
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

      // Obtener perfil local una sola vez
      final boxPerfil = await _getPerfilBox();
      final perfilLocal = boxPerfil.get('perfil');

      // 3. Filtrar sesiones locales que NO existen en la nube
      final sesionesNuevas = sesionesLocales.where((sesion) {
        final id = sesion.fecha.millisecondsSinceEpoch.toString();
        return !idsRemotosSet.contains(id);
      }).toList();

      debugPrint('Sesiones nuevas a subir: ${sesionesNuevas.length}');

      // 4. Subir solo las sesiones nuevas y el perfil
      if (sesionesNuevas.isNotEmpty) {
        await _firestoreService.sincronizarDatosLocales(
          _userId!,
          sesionesNuevas,
          perfilLocal,
        );
      } else if (perfilLocal != null) {
        // Si no hay sesiones nuevas pero hay perfil, sincronizarlo
        debugPrint('No hay sesiones nuevas, sincronizando solo perfil...');
        await _firestoreService.guardarPerfil(_userId!, perfilLocal);
      } else {
        debugPrint('No hay sesiones ni perfil para sincronizar');
      }

      // 5. Sincronizar datos de gamificación
      await _sincronizarGamificacion(
        'Sincronizando datos de gamificación...',
        'Datos de gamificación sincronizados',
      );

      // 6. Obtener sesiones finales de la nube después de la subida
      debugPrint('Descargando estado final desde la nube...');
      final sesionesFinal = await _firestoreService.obtenerSesiones(_userId!);

      // 7. Actualizar almacenamiento local con datos de la nube (verdad única)
      // IMPORTANTE: Solo limpiamos después de confirmar que tenemos los datos de la nube
      debugPrint('Actualizando almacenamiento local con datos de la nube...');
      await boxSesiones.clear();
      await boxSesiones.addAll(sesionesFinal);

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

      debugPrint('Descarga completada: ${sesionesRemotas.length} sesiones');

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

      debugPrint('Subiendo todos los datos locales a la nube...');

      // 1. Obtener todas las sesiones locales
      final boxSesiones = await _getSesionesBox();
      final sesionesLocales = boxSesiones.values.toList();
      debugPrint('Sesiones locales a subir: ${sesionesLocales.length}');

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

      // 5. Subir datos de gamificación
      await _sincronizarGamificacion(
        'Subiendo datos de gamificación...',
        'Datos de gamificación subidos',
      );

      debugPrint('Subida completada: ${sesionesLocales.length} sesiones en la nube');

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
}
