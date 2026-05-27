import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/sesion.dart';
import '../models/nota.dart';
import '../models/perfil_usuario.dart';
import '../models/user_progress.dart';
import '../models/achievement.dart';
import '../utils/app_constants.dart';
import '../utils/url_utils.dart';
import '../exceptions/sync_exceptions.dart';

/// Servicio para interactuar con Firestore
/// Maneja la sincronización de datos del usuario en la nube
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _feedbackDestinationEmail = 'appbolometro@gmail.com';
  static const int _dailyEngagementTargetMinutes = 5;

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

  /// Obtiene la clave de día local en formato YYYY-MM-DD.
  String _getLocalDayKey(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '${localDate.year}-$month-$day';
  }

  /// Obtener referencia a la colección de notas del usuario
  CollectionReference _getNotasCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('notas');
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

  /// Guardar o actualizar una nota en Firestore
  Future<void> guardarNota(String userId, Nota nota) async {
    try {
      await _getNotasCollection(userId).doc(nota.id).set(
            nota.toJson(),
            SetOptions(merge: true),
          );
      debugPrint('Nota guardada en Firestore: ${nota.id}');
    } catch (e) {
      debugPrint('Error al guardar nota en Firestore: $e');
      rethrow;
    }
  }

  /// Obtener notas del usuario desde Firestore
  Future<List<Nota>> obtenerNotas(
    String userId, {
    bool includeDeleted = false,
  }) async {
    try {
      final snapshot = await _getNotasCollection(userId).get();
      final notas = snapshot.docs
          .map((doc) => Nota.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      if (includeDeleted) return notas;
      return notas.where((n) => n.fechaEliminacion == null).toList();
    } catch (e) {
      debugPrint('Error al obtener notas desde Firestore: $e');
      return [];
    }
  }

  /// Marca una nota como eliminada (soft delete)
  Future<void> marcarNotaEliminada(
    String userId,
    String notaId,
    DateTime deletedAt,
  ) async {
    try {
      await _getNotasCollection(userId).doc(notaId).set(
        {
          'fechaEliminacion': deletedAt.toIso8601String(),
          'deletedAt': deletedAt.toIso8601String(),
          'fechaModificacion': deletedAt.toIso8601String(),
          'updatedAt': deletedAt.toIso8601String(),
        },
        SetOptions(merge: true),
      );
      debugPrint('Nota marcada como eliminada en Firestore: $notaId');
    } catch (e) {
      debugPrint('Error al marcar nota eliminada en Firestore: $e');
      rethrow;
    }
  }

  /// Eliminar una nota de Firestore (hard delete)
  Future<void> eliminarNotaFisica(String userId, String notaId) async {
    try {
      await _getNotasCollection(userId).doc(notaId).delete();
      debugPrint('Nota eliminada físicamente de Firestore: $notaId');
    } catch (e) {
      debugPrint('Error al eliminar nota físicamente de Firestore: $e');
      rethrow;
    }
  }

  /// Eliminar el perfil del usuario de Firestore
  Future<void> eliminarPerfil(String userId) async {
    try {
      final docRef = _getPerfilDocument(userId);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        await docRef.update({'perfil': FieldValue.delete()});
        debugPrint('Perfil eliminado de Firestore');
      }
    } catch (e) {
      debugPrint('Error al eliminar perfil de Firestore: $e');
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
        'googlePhotoUrl': UrlUtils.sanitizePhotoUrl(perfil.googlePhotoUrl),
        'googleDisplayName': perfil.googleDisplayName,
        'isFromGoogle': perfil.isFromGoogle,
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

      /// Obtiene la preferencia del usuario para recordatorios diarios.
      /// Si no existe aún, por defecto retorna true.
      Future<bool> obtenerPreferenciaRecordatorioDiario(String userId) async {
        try {
          final docSnapshot = await _getPerfilDocument(userId).get();
          if (!docSnapshot.exists) return true;
          final data = docSnapshot.data() as Map<String, dynamic>?;
          if (data == null) return true;
          final value = data['dailyReminderEnabled'];
          if (value is bool) return value;
          return true;
        } catch (e) {
          debugPrint('Error al obtener preferencia de recordatorio diario: $e');
          return true;
        }
      }

      /// Actualiza la preferencia del usuario para recordatorios diarios.
      Future<void> actualizarPreferenciaRecordatorioDiario(
        String userId,
        bool enabled,
      ) async {
        try {
          final now = DateTime.now();
          await _getPerfilDocument(userId).set({
            'dailyReminderEnabled': enabled,
            'timezoneOffsetMinutes': now.timeZoneOffset.inMinutes,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error al actualizar preferencia de recordatorio diario: $e');
          rethrow;
        }
      }

      /// Registra actividad diaria en minutos para un usuario autenticado.
      Future<void> registrarActividadDiaria(
        String userId, {
        required int minutesToAdd,
      }) async {
        if (minutesToAdd <= 0) return;

        try {
          final now = DateTime.now();
          final dayKey = _getLocalDayKey(now);
          final dayDocRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('daily_engagement')
              .doc(dayKey);
          final metricDocRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('daily_engagement_metrics')
              .doc(dayKey);
          final userDocRef = _getPerfilDocument(userId);

          await _firestore.runTransaction((transaction) async {
            final daySnapshot = await transaction.get(dayDocRef);
            final dayData = daySnapshot.data() as Map<String, dynamic>?;
            final currentMinutes = (dayData?['minutesUsed'] as num?)?.toInt() ?? 0;
            final updatedMinutes = currentMinutes + minutesToAdd;

            transaction.set(dayDocRef, {
              'dateKey': dayKey,
              'minutesUsed': FieldValue.increment(minutesToAdd),
              'targetMinutes': _dailyEngagementTargetMinutes,
              'lastActiveAt': FieldValue.serverTimestamp(),
              'timezoneOffsetMinutes': now.timeZoneOffset.inMinutes,
            }, SetOptions(merge: true));

            transaction.set(userDocRef, {
              'timezoneOffsetMinutes': now.timeZoneOffset.inMinutes,
              'lastEngagementActivityAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            if (currentMinutes < _dailyEngagementTargetMinutes &&
                updatedMinutes >= _dailyEngagementTargetMinutes) {
              transaction.set(metricDocRef, {
                'dateKey': dayKey,
                'goalReached': true,
                'goalReachedAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          });
        } catch (e) {
          debugPrint('Error al registrar actividad diaria: $e');
        }
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
        googlePhotoUrl: perfilData['googlePhotoUrl'],
        googleDisplayName: perfilData['googleDisplayName'],
        isFromGoogle: perfilData['isFromGoogle'] ?? false,
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

  /// Saves feedback submitted from the app in a global collection.
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
    try {
      final feedbackData = <String, dynamic>{
        'userId': userId,
        'type': type,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'appVersion': appVersion,
        'platform': platform,
        'languageCode': languageCode,
        'destinationEmail': _feedbackDestinationEmail,
        'status': 'new',
      };

      if (authEmail != null && authEmail.trim().isNotEmpty) {
        feedbackData['authEmail'] = authEmail.trim();
      }
      if (rating != null) {
        feedbackData['rating'] = rating;
      }

      await _firestore.collection('feedback').add(feedbackData);
      debugPrint('Feedback saved to Firestore');
    } catch (e) {
      debugPrint('Error saving feedback to Firestore: $e');
      rethrow;
    }
  }
}
