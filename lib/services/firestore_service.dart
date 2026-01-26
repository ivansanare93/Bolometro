import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sesion.dart';
import '../models/perfil_usuario.dart';

/// Servicio para interactuar con Firestore
/// Maneja la sincronización de datos del usuario en la nube
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtener referencia a la colección de sesiones del usuario
  CollectionReference _getSesionesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('sesiones');
  }

  /// Obtener referencia al documento de perfil del usuario
  DocumentReference _getPerfilDocument(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// Guardar o actualizar una sesión en Firestore
  Future<void> guardarSesion(String userId, Sesion sesion) async {
    try {
      final sesionData = sesion.toJson();
      // Usar el timestamp de la fecha como ID del documento para facilitar ordenamiento
      final docId = sesion.fecha.millisecondsSinceEpoch.toString();
      
      await _getSesionesCollection(userId).doc(docId).set(sesionData);
      debugPrint('Sesión guardada en Firestore: $docId');
    } catch (e) {
      debugPrint('Error al guardar sesión en Firestore: $e');
      rethrow;
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
      };

      await _getPerfilDocument(userId).set(
        {'perfil': perfilData},
        SetOptions(merge: true),
      );
      debugPrint('Perfil guardado en Firestore');
    } catch (e) {
      debugPrint('Error al guardar perfil en Firestore: $e');
      rethrow;
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
  Future<void> sincronizarDatosLocales(
    String userId,
    List<Sesion> sesionesLocales,
    PerfilUsuario? perfilLocal,
  ) async {
    try {
      // Sincronizar sesiones
      for (final sesion in sesionesLocales) {
        await guardarSesion(userId, sesion);
      }

      // Sincronizar perfil si existe
      if (perfilLocal != null) {
        await guardarPerfil(userId, perfilLocal);
      }

      debugPrint('Sincronización completada: ${sesionesLocales.length} sesiones');
    } catch (e) {
      debugPrint('Error durante la sincronización: $e');
      rethrow;
    }
  }
}
