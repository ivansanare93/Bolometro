import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/sesion.dart';
import '../models/perfil_usuario.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';

/// Repositorio que abstrae el acceso a datos
/// Maneja tanto almacenamiento local (Hive) como remoto (Firestore)
class DataRepository extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _userId;
  bool _isOnlineMode = false;
  bool _isSyncing = false;

  bool get isOnlineMode => _isOnlineMode;
  bool get isSyncing => _isSyncing;

  /// Configurar el usuario autenticado y modo online
  void setUser(String? userId) {
    _userId = userId;
    _isOnlineMode = userId != null;
    notifyListeners();
  }

  /// Obtener todas las sesiones
  Future<List<Sesion>> obtenerSesiones() async {
    try {
      if (_isOnlineMode && _userId != null) {
        // Modo online: obtener desde Firestore
        return await _firestoreService.obtenerSesiones(_userId!);
      } else {
        // Modo offline: obtener desde Hive
        final box = Hive.box<Sesion>(AppConstants.boxSesiones);
        return box.values.toList();
      }
    } catch (e) {
      debugPrint('Error al obtener sesiones: $e');
      // Fallback a datos locales si falla Firestore
      try {
        final box = Hive.box<Sesion>(AppConstants.boxSesiones);
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
        final box = Hive.box<Sesion>(AppConstants.boxSesiones);
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
      final box = Hive.box<Sesion>(AppConstants.boxSesiones);
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
      // Eliminar localmente
      await sesion.delete();

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
      final box = Hive.box<PerfilUsuario>(AppConstants.boxPerfilUsuario);
      if (box.isNotEmpty) {
        return box.getAt(0);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener perfil: $e');
      return null;
    }
  }

  /// Guardar perfil de usuario
  Future<void> guardarPerfil(PerfilUsuario perfil) async {
    try {
      // Guardar localmente
      final box = Hive.box<PerfilUsuario>(AppConstants.boxPerfilUsuario);
      if (box.isEmpty) {
        await box.add(perfil);
      } else {
        await box.putAt(0, perfil);
      }

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

  /// Sincronizar datos locales a la nube
  Future<void> sincronizarANube() async {
    if (!_isOnlineMode || _userId == null || _isSyncing) {
      return;
    }

    try {
      _isSyncing = true;
      notifyListeners();

      // Obtener datos locales
      final boxSesiones = Hive.box<Sesion>(AppConstants.boxSesiones);
      final sesionesLocales = boxSesiones.values.toList();

      final boxPerfil = Hive.box<PerfilUsuario>(AppConstants.boxPerfilUsuario);
      final perfilLocal = boxPerfil.isNotEmpty ? boxPerfil.getAt(0) : null;

      // Sincronizar con Firestore
      await _firestoreService.sincronizarDatosLocales(
        _userId!,
        sesionesLocales,
        perfilLocal,
      );

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error durante la sincronización: $e');
      _isSyncing = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Descargar datos desde la nube al almacenamiento local
  Future<void> descargarDesdeNube() async {
    if (!_isOnlineMode || _userId == null) {
      return;
    }

    try {
      // Obtener sesiones desde Firestore
      final sesionesRemotas = await _firestoreService.obtenerSesiones(_userId!);
      
      // Guardar en Hive
      final boxSesiones = Hive.box<Sesion>(AppConstants.boxSesiones);
      await boxSesiones.clear();
      for (final sesion in sesionesRemotas) {
        await boxSesiones.add(sesion);
      }

      // Obtener perfil desde Firestore
      final perfilRemoto = await _firestoreService.obtenerPerfil(_userId!);
      if (perfilRemoto != null) {
        final boxPerfil = Hive.box<PerfilUsuario>(AppConstants.boxPerfilUsuario);
        await boxPerfil.clear();
        await boxPerfil.add(perfilRemoto);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al descargar desde la nube: $e');
      rethrow;
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
