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
      // Migrar datos guardados en modo offline al box del usuario autenticado.
      // Esto garantiza que los datos locales previos al primer inicio de sesión
      // estén disponibles cuando Firestore aún no los tenga (p.ej. primera vez
      // que el usuario inicia sesión con una cuenta de Google).
      await _migrarDatosOffline();
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

      // Solo migrar si los boxes del usuario están completamente vacíos
      // (primer inicio de sesión en este dispositivo).
      if (userPerfilBox.isNotEmpty || userSesionesBox.isNotEmpty) return;

      // Migrar perfil desde el box por defecto.
      // Nota: se incluye el fallback a getAt(0) para manejar el formato
      // heredado donde el perfil se guardaba con clave entera 0 antes de
      // migrar a la clave fija 'perfil'. El mismo patrón existe en
      // [obtenerPerfil] del repositorio.
      if (Hive.isBoxOpen(AppConstants.boxPerfilUsuario)) {
        final defaultPerfilBox = Hive.box<PerfilUsuario>(AppConstants.boxPerfilUsuario);
        final perfilOffline = defaultPerfilBox.get('perfil') ??
            (defaultPerfilBox.isNotEmpty ? defaultPerfilBox.getAt(0) : null);
        if (perfilOffline != null) {
          await userPerfilBox.put('perfil', perfilOffline);
          debugPrint('Perfil offline migrado al box del usuario autenticado');
        }
      }

      // Migrar sesiones desde el box por defecto
      if (Hive.isBoxOpen(AppConstants.boxSesiones)) {
        final defaultSesionesBox = Hive.box<Sesion>(AppConstants.boxSesiones);
        if (defaultSesionesBox.isNotEmpty) {
          await userSesionesBox.addAll(defaultSesionesBox.values);
          debugPrint(
            '${defaultSesionesBox.length} sesiones offline migradas al box del usuario autenticado',
          );
        }
      }
    } catch (e) {
      debugPrint('Error al migrar datos offline al usuario: $e');
    }
  }

  /// Limpiar datos locales del usuario cuando cierra sesión
  Future<void> clearUserData() async {
    if (_userId == null) return;

    final sesionesBoxName = _getSesionesBoxName();
    final perfilBoxName = _getPerfilBoxName();

    try {
      // Cerrar boxes si están abiertas
      if (Hive.isBoxOpen(sesionesBoxName)) {
        await Hive.box<Sesion>(sesionesBoxName).close();
      }
      if (Hive.isBoxOpen(perfilBoxName)) {
        await Hive.box<PerfilUsuario>(perfilBoxName).close();
      }

      // Borrar del disco para evitar mezcla de datos entre usuarios
      await Hive.deleteBoxFromDisk(sesionesBoxName);
      await Hive.deleteBoxFromDisk(perfilBoxName);

      debugPrint('Datos locales del usuario eliminados del disco');
    } catch (e) {
      debugPrint('Error al borrar datos locales del usuario: $e');
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

      // 7. Obtener sesiones finales de la nube después de la subida
      debugPrint('Descargando estado final desde la nube...');
      final sesionesFinal = await _firestoreService.obtenerSesiones(_userId!);

      // 8. Actualizar almacenamiento local con datos de la nube (verdad única)
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
