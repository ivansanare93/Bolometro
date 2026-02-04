import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/sesion.dart';
import '../models/perfil_usuario.dart';
import '../models/user_progress.dart';
import '../models/achievement.dart';
import '../utils/app_constants.dart';
import '../exceptions/sync_exceptions.dart';

/// Servicio para interactuar con Firestore
/// Maneja la sincronización de datos del usuario en la nube
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Genera un código de amigo único de 8 caracteres
  String _generarCodigoAmigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Sin caracteres confusos
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Verifica si un código de amigo ya existe en la base de datos
  Future<bool> _codigoAmigoExiste(String friendCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('perfil.friendCode', isEqualTo: friendCode)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error al verificar código de amigo: $e');
      return false;
    }
  }

  /// Genera un código de amigo único verificando que no exista
  Future<String> generarCodigoAmigoUnico() async {
    String codigo;
    bool existe;
    int intentos = 0;
    const maxIntentos = 10; // Límite de intentos para evitar bucles infinitos
    
    do {
      codigo = _generarCodigoAmigo();
      existe = await _codigoAmigoExiste(codigo);
      intentos++;
      
      if (intentos >= maxIntentos) {
        debugPrint('Se alcanzó el límite de intentos al generar código de amigo');
        // Si hay muchas colisiones, agregar timestamp para garantizar unicidad
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        codigo = '${_generarCodigoAmigo().substring(0, 6)}${timestamp.substring(timestamp.length - 2)}';
        break;
      }
    } while (existe);
    
    return codigo;
  }

  /// Obtener referencia a la colección de sesiones del usuario
  CollectionReference _getSesionesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('sesiones');
  }

  /// Obtener referencia al documento de perfil del usuario
  DocumentReference _getPerfilDocument(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// Obtener referencia al documento de progreso del usuario
  DocumentReference _getProgressDocument(String userId) {
    return _firestore.collection('users').doc(userId).collection('gamification').doc('progress');
  }

  /// Obtener referencia a la colección de logros del usuario
  CollectionReference _getAchievementsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('gamification').doc('progress').collection('achievements');
  }

  /// Guardar o actualizar una sesión en Firestore
  /// 
  /// Guarda una sesión en la colección "sesiones" del usuario.
  /// La colección se crea automáticamente si no existe.
  /// Usa el timestamp de la fecha como ID del documento para facilitar ordenamiento.
  /// 
  /// [userId] - ID del usuario autenticado
  /// [sesion] - Sesión a guardar
  Future<void> guardarSesion(String userId, Sesion sesion) async {
    try {
      final sesionData = sesion.toJson();
      // Usar el timestamp de la fecha como ID del documento para facilitar ordenamiento
      final docId = sesion.fecha.millisecondsSinceEpoch.toString();
      
      // Firestore creará automáticamente la colección si no existe
      await _getSesionesCollection(userId).doc(docId).set(
        sesionData,
        SetOptions(merge: true), // Usar merge para actualizar si ya existe
      );
      
      debugPrint('Sesión guardada en Firestore: $docId');
    } catch (e) {
      debugPrint('Error al guardar sesión en Firestore: $e');
      
      // Lanzar excepciones específicas basadas en el tipo de error
      final errorMsg = e.toString();
      
      if (errorMsg.contains('PERMISSION_DENIED')) {
        throw PermissionException(
          'Error de permisos al guardar sesión. '
          'Verifica las reglas de seguridad de Firestore.'
        );
      } else if (errorMsg.contains('UNAVAILABLE') || 
                 errorMsg.contains('network')) {
        throw NetworkException(
          'Error de red al guardar sesión. '
          'Verifica tu conexión a Internet.'
        );
      } else {
        rethrow;
      }
    }
  }

  /// Obtener todas las sesiones del usuario desde Firestore
  Future<List<Sesion>> obtenerSesiones(String userId) async {
    try {
      final querySnapshot = await _getSesionesCollection(userId)
          .orderBy('fecha', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Sesion.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener sesiones desde Firestore: $e');
      return [];
    }
  }

  /// Obtener sesiones con paginación (para lazy loading)
  Future<List<Sesion>> obtenerSesionesPaginadas(
    String userId, {
    int limite = 20,
    DocumentSnapshot? ultimoDocumento,
  }) async {
    try {
      Query query = _getSesionesCollection(userId)
          .orderBy('fecha', descending: true)
          .limit(limite);

      if (ultimoDocumento != null) {
        query = query.startAfterDocument(ultimoDocumento);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => Sesion.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener sesiones paginadas desde Firestore: $e');
      return [];
    }
  }

  /// Eliminar una sesión de Firestore
  Future<void> eliminarSesion(String userId, DateTime fechaSesion) async {
    try {
      final docId = fechaSesion.millisecondsSinceEpoch.toString();
      await _getSesionesCollection(userId).doc(docId).delete();
      debugPrint('Sesión eliminada de Firestore: $docId');
    } catch (e) {
      debugPrint('Error al eliminar sesión de Firestore: $e');
      rethrow;
    }
  }

  /// Guardar o actualizar el perfil del usuario
  /// 
  /// Guarda el perfil en el documento principal del usuario.
  /// El documento se crea automáticamente si no existe.
  /// 
  /// [userId] - ID del usuario autenticado
  /// [perfil] - Perfil del usuario a guardar
  Future<void> guardarPerfil(String userId, PerfilUsuario perfil) async {
    try {
      final perfilData = {
        'nombre': perfil.nombre,
        'email': perfil.email,
        'avatarPath': perfil.avatarPath,
        'club': perfil.club,
        'manoDominante': perfil.manoDominante,
        'fechaNacimiento': perfil.fechaNacimiento?.toIso8601String(),
        'bio': perfil.bio,
        'friendCode': perfil.friendCode,
      };

      // Firestore creará automáticamente el documento si no existe
      await _getPerfilDocument(userId).set(
        {'perfil': perfilData},
        SetOptions(merge: true), // Usar merge para no sobrescribir otros campos
      );
      
      debugPrint('Perfil guardado en Firestore');
    } catch (e) {
      debugPrint('Error al guardar perfil en Firestore: $e');
      
      // Lanzar excepciones específicas basadas en el tipo de error
      final errorMsg = e.toString();
      
      if (errorMsg.contains('PERMISSION_DENIED')) {
        throw PermissionException(
          'Error de permisos al guardar perfil. '
          'Verifica las reglas de seguridad de Firestore.'
        );
      } else if (errorMsg.contains('UNAVAILABLE') || 
                 errorMsg.contains('network')) {
        throw NetworkException(
          'Error de red al guardar perfil. '
          'Verifica tu conexión a Internet.'
        );
      } else {
        rethrow;
      }
    }
  }

  /// Obtener el perfil del usuario
  Future<PerfilUsuario?> obtenerPerfil(String userId) async {
    try {
      final docSnapshot = await _getPerfilDocument(userId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('perfil')) {
        return null;
      }

      final perfilData = data['perfil'] as Map<String, dynamic>;
      return PerfilUsuario(
        nombre: perfilData['nombre'] ?? '',
        email: perfilData['email'],
        avatarPath: perfilData['avatarPath'],
        club: perfilData['club'],
        manoDominante: perfilData['manoDominante'],
        fechaNacimiento: perfilData['fechaNacimiento'] != null
            ? DateTime.parse(perfilData['fechaNacimiento'])
            : null,
        bio: perfilData['bio'],
        friendCode: perfilData['friendCode'],
      );
    } catch (e) {
      debugPrint('Error al obtener perfil desde Firestore: $e');
      return null;
    }
  }

  /// Stream de sesiones en tiempo real
  Stream<List<Sesion>> streamSesiones(String userId) {
    return _getSesionesCollection(userId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Sesion.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Sincronizar datos desde Hive a Firestore (migración inicial)
  /// 
  /// Sube todas las sesiones locales y el perfil del usuario a Firestore.
  /// Crea las colecciones y documentos dinámicamente si no existen.
  /// 
  /// [userId] - ID del usuario autenticado
  /// [sesionesLocales] - Lista de sesiones almacenadas localmente en Hive
  /// [perfilLocal] - Perfil del usuario almacenado localmente (opcional)
  /// 
  /// Lanza excepciones si hay problemas de red o permisos.
  Future<void> sincronizarDatosLocales(
    String userId,
    List<Sesion> sesionesLocales,
    PerfilUsuario? perfilLocal,
  ) async {
    try {
      debugPrint('Iniciando sincronización para usuario: $userId');
      
      int sesionesSubidas = 0;
      int erroresSesiones = 0;

      // Sincronizar sesiones una por una
      // Firestore creará automáticamente las colecciones si no existen
      for (final sesion in sesionesLocales) {
        try {
          await guardarSesion(userId, sesion);
          sesionesSubidas++;
          
          // Log de progreso
          if (sesionesSubidas % AppConstants.intervaloLogSincronizacion == 0) {
            debugPrint('Progreso: $sesionesSubidas/${sesionesLocales.length} sesiones sincronizadas');
          }
        } catch (e) {
          erroresSesiones++;
          debugPrint('Error al sincronizar sesión individual: $e');
          // Continuar con las demás sesiones incluso si una falla
        }
      }

      // Sincronizar perfil si existe
      if (perfilLocal != null) {
        try {
          await guardarPerfil(userId, perfilLocal);
          debugPrint('Perfil sincronizado exitosamente');
        } catch (e) {
          debugPrint('Error al sincronizar perfil: $e');
          // El error del perfil no debe detener toda la sincronización
        }
      }

      // Resumen de sincronización
      debugPrint(
        'Sincronización completada: '
        '$sesionesSubidas/${sesionesLocales.length} sesiones subidas exitosamente'
        '${erroresSesiones > 0 ? ', $erroresSesiones errores' : ''}'
      );

      // Si no se subió ninguna sesión y hubo errores, lanzar excepción
      if (sesionesSubidas == 0 && erroresSesiones > 0) {
        throw SyncException(
          'No se pudo sincronizar ninguna sesión. '
          'Verifica tu conexión y permisos de Firestore.'
        );
      }
    } catch (e) {
      debugPrint('Error crítico durante la sincronización: $e');
      rethrow;
    }
  }

  /// Guardar progreso del usuario en Firestore
  Future<void> guardarProgreso(String userId, UserProgress progress) async {
    try {
      await _getProgressDocument(userId).set(
        progress.toJson(),
        SetOptions(merge: true),
      );
      debugPrint('Progreso guardado en Firestore');
    } catch (e) {
      debugPrint('Error al guardar progreso en Firestore: $e');
      rethrow;
    }
  }

  /// Obtener progreso del usuario desde Firestore
  Future<UserProgress?> obtenerProgreso(String userId) async {
    try {
      final doc = await _getProgressDocument(userId).get();
      if (doc.exists) {
        return UserProgress.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error al obtener progreso desde Firestore: $e');
      return null;
    }
  }

  /// Guardar logro en Firestore
  Future<void> guardarLogro(String userId, Achievement achievement) async {
    try {
      await _getAchievementsCollection(userId)
          .doc(achievement.id)
          .set(achievement.toJson(), SetOptions(merge: true));
      debugPrint('Logro guardado en Firestore: ${achievement.id}');
    } catch (e) {
      debugPrint('Error al guardar logro en Firestore: $e');
      rethrow;
    }
  }

  /// Obtener logros desde Firestore
  Future<List<Achievement>> obtenerLogros(String userId) async {
    try {
      final querySnapshot = await _getAchievementsCollection(userId).get();
      return querySnapshot.docs
          .map((doc) => Achievement.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener logros desde Firestore: $e');
      return [];
    }
  }

  /// Sincronizar todos los datos de gamificación
  Future<void> sincronizarGamificacion(
    String userId,
    UserProgress progress,
    List<Achievement> achievements,
  ) async {
    try {
      // Usar batch para operaciones atómicas
      final batch = _firestore.batch();

      // Guardar progreso
      batch.set(
        _getProgressDocument(userId),
        progress.toJson(),
        SetOptions(merge: true),
      );

      // Guardar logros en batch
      for (var achievement in achievements) {
        batch.set(
          _getAchievementsCollection(userId).doc(achievement.id),
          achievement.toJson(),
          SetOptions(merge: true),
        );
      }

      // Ejecutar todas las operaciones
      await batch.commit();

      debugPrint('Gamificación sincronizada en Firestore');
    } catch (e) {
      debugPrint('Error al sincronizar gamificación: $e');
      rethrow;
    }
  }
}
