import 'dart:math' show sqrt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/perfil_usuario.dart';
import '../exceptions/sync_exceptions.dart';
import 'notification_service.dart';

/// Servicio para gestionar amistades en Firestore
class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Obtener referencia a la colección de amigos del usuario
  CollectionReference _getFriendsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('friends');
  }

  /// Obtener referencia a la colección de solicitudes de amistad del usuario
  CollectionReference _getFriendRequestsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('friendRequests');
  }

  /// Buscar un usuario por email
  /// Devuelve información básica del usuario si existe
  Future<Map<String, dynamic>?> buscarUsuarioPorEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('perfil.email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final perfil = data['perfil'] as Map<String, dynamic>?;

      if (perfil == null) {
        return null;
      }

      return {
        'userId': doc.id,
        'nombre': perfil['nombre'] ?? '',
        'email': perfil['email'] ?? email,
        'photoUrl': perfil['avatarPath'],
      };
    } catch (e) {
      debugPrint('Error al buscar usuario por email: $e');
      return null;
    }
  }

  /// Buscar un usuario por código de amigo
  /// Devuelve información básica del usuario si existe
  Future<Map<String, dynamic>?> buscarUsuarioPorCodigoAmigo(String friendCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('perfil.friendCode', isEqualTo: friendCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      final perfil = data['perfil'] as Map<String, dynamic>?;

      if (perfil == null) {
        return null;
      }

      return {
        'userId': doc.id,
        'nombre': perfil['nombre'] ?? '',
        'email': perfil['email'],
        'photoUrl': perfil['avatarPath'],
        'friendCode': perfil['friendCode'],
      };
    } catch (e) {
      debugPrint('Error al buscar usuario por código de amigo: $e');
      return null;
    }
  }

  /// Enviar solicitud de amistad
  /// Crea una solicitud en la colección del destinatario
  Future<bool> enviarSolicitudAmistad({
    required String fromUserId,
    required String fromUserName,
    String? fromUserEmail,
    String? fromUserPhotoUrl,
    required String toUserId,
  }) async {
    try {
      // Verificar que no se envíe solicitud a uno mismo
      if (fromUserId == toUserId) {
        debugPrint('No puedes enviarte una solicitud de amistad a ti mismo');
        return false;
      }

      // Verificar si ya son amigos
      final existingFriend =
          await _getFriendsCollection(fromUserId).doc(toUserId).get();
      if (existingFriend.exists) {
        debugPrint('Ya son amigos');
        return false;
      }

      // Verificar si ya existe una solicitud pendiente
      final existingRequest = await _getFriendRequestsCollection(toUserId)
          .where('fromUserId', isEqualTo: fromUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        debugPrint('Ya existe una solicitud pendiente');
        return false;
      }

      final requestId =
          '${fromUserId}_${toUserId}_${DateTime.now().millisecondsSinceEpoch}';

      final request = FriendRequest(
        requestId: requestId,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        fromUserPhotoUrl: fromUserPhotoUrl,
        toUserId: toUserId,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      await _getFriendRequestsCollection(toUserId)
          .doc(requestId)
          .set(request.toJson());

      // Enviar notificación push al destinatario
      await _notificationService.sendFriendRequestNotification(
        toUserId: toUserId,
        fromUserName: fromUserName,
        requestId: requestId,
      );

      debugPrint('Solicitud de amistad enviada: $requestId');
      return true;
    } catch (e) {
      debugPrint('Error al enviar solicitud de amistad: $e');

      final errorMsg = e.toString();
      if (errorMsg.contains('PERMISSION_DENIED')) {
        throw PermissionException(
            'Error de permisos al enviar solicitud de amistad.');
      } else if (errorMsg.contains('UNAVAILABLE') ||
          errorMsg.contains('network')) {
        throw NetworkException(
            'Error de red al enviar solicitud. Verifica tu conexión.');
      } else {
        return false;
      }
    }
  }

  /// Obtener solicitudes de amistad pendientes
  Future<List<FriendRequest>> obtenerSolicitudesPendientes(
      String userId) async {
    try {
      final querySnapshot = await _getFriendRequestsCollection(userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              FriendRequest.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener solicitudes pendientes: $e');
      return [];
    }
  }

  /// Aceptar solicitud de amistad
  /// Crea la relación de amistad bidireccional y actualiza el estado de la solicitud
  Future<bool> aceptarSolicitudAmistad(
      String userId, FriendRequest request) async {
    try {
      final batch = _firestore.batch();

      // Actualizar estado de la solicitud
      final requestRef =
          _getFriendRequestsCollection(userId).doc(request.requestId);
      batch.update(requestRef, {
        'status': 'accepted',
        'respondedAt': DateTime.now().toIso8601String(),
      });

      // Agregar amigo en la colección del usuario actual
      final friend1 = Friend(
        userId: request.fromUserId,
        nombre: request.fromUserName,
        email: request.fromUserEmail,
        photoUrl: request.fromUserPhotoUrl,
        fechaAmistad: DateTime.now(),
      );

      batch.set(
        _getFriendsCollection(userId).doc(request.fromUserId),
        friend1.toJson(),
      );

      // Agregar amigo en la colección del usuario que envió la solicitud
      // Primero necesitamos obtener los datos del usuario actual
      final currentUserDoc = await _firestore.collection('users').doc(userId).get();
      final currentUserData = currentUserDoc.data();
      final currentUserPerfil = currentUserData?['perfil'] as Map<String, dynamic>?;

      final friend2 = Friend(
        userId: userId,
        nombre: currentUserPerfil?['nombre'] ?? '',
        email: currentUserPerfil?['email'],
        photoUrl: currentUserPerfil?['avatarPath'],
        fechaAmistad: DateTime.now(),
      );

      batch.set(
        _getFriendsCollection(request.fromUserId).doc(userId),
        friend2.toJson(),
      );

      await batch.commit();

      // Enviar notificación push al usuario que envió la solicitud
      await _notificationService.sendFriendRequestAcceptedNotification(
        toUserId: request.fromUserId,
        acceptedByUserName: currentUserPerfil?['nombre'] ?? 'Un usuario',
      );

      debugPrint('Solicitud de amistad aceptada: ${request.requestId}');
      return true;
    } catch (e) {
      debugPrint('Error al aceptar solicitud de amistad: $e');

      final errorMsg = e.toString();
      if (errorMsg.contains('PERMISSION_DENIED')) {
        throw PermissionException(
            'Error de permisos al aceptar solicitud de amistad.');
      } else if (errorMsg.contains('UNAVAILABLE') ||
          errorMsg.contains('network')) {
        throw NetworkException(
            'Error de red al aceptar solicitud. Verifica tu conexión.');
      } else {
        return false;
      }
    }
  }

  /// Rechazar solicitud de amistad
  Future<bool> rechazarSolicitudAmistad(
      String userId, String requestId) async {
    try {
      await _getFriendRequestsCollection(userId).doc(requestId).update({
        'status': 'rejected',
        'respondedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('Solicitud de amistad rechazada: $requestId');
      return true;
    } catch (e) {
      debugPrint('Error al rechazar solicitud de amistad: $e');
      return false;
    }
  }

  /// Obtener lista de amigos
  Future<List<Friend>> obtenerAmigos(String userId) async {
    try {
      final querySnapshot = await _getFriendsCollection(userId)
          .orderBy('fechaAmistad', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Friend.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error al obtener lista de amigos: $e');
      return [];
    }
  }

  /// Eliminar amistad
  /// Elimina la relación bidireccional
  Future<bool> eliminarAmigo(String userId, String friendId) async {
    try {
      final batch = _firestore.batch();

      // Eliminar de la colección del usuario actual
      batch.delete(_getFriendsCollection(userId).doc(friendId));

      // Eliminar de la colección del amigo
      batch.delete(_getFriendsCollection(friendId).doc(userId));

      await batch.commit();

      debugPrint('Amistad eliminada: $userId <-> $friendId');
      return true;
    } catch (e) {
      debugPrint('Error al eliminar amistad: $e');
      return false;
    }
  }

  /// Obtener estadísticas de un amigo para rankings
  /// Lee las sesiones del amigo y calcula estadísticas básicas y extendidas
  Future<Map<String, dynamic>?> obtenerEstadisticasAmigo(
      String friendId) async {
    try {
      final sesionesSnapshot = await _firestore
          .collection('users')
          .doc(friendId)
          .collection('sesiones')
          .get();

      if (sesionesSnapshot.docs.isEmpty) {
        return {
          'userId': friendId,
          'totalPartidas': 0,
          'promedioGeneral': 0.0,
          'mejorPartida': 0,
          'strikesPercent': 0.0,
          'sparesPercent': 0.0,
          'consistencia': 0.0,
        };
      }

      int totalPartidas = 0;
      int sumaTotal = 0;
      int mejorPartida = 0;
      List<int> puntuaciones = [];
      int totalFrames = 0;
      int strikes = 0;
      int spares = 0;

      for (final doc in sesionesSnapshot.docs) {
        final data = doc.data();
        final partidas = data['partidas'] as List<dynamic>?;

        if (partidas != null) {
          for (final partidaData in partidas) {
            final puntuacionTotal = partidaData['puntuacionTotal'] as int?;
            final frames = partidaData['frames'] as List<dynamic>?;
            
            if (puntuacionTotal != null) {
              totalPartidas++;
              sumaTotal += puntuacionTotal;
              puntuaciones.add(puntuacionTotal);
              if (puntuacionTotal > mejorPartida) {
                mejorPartida = puntuacionTotal;
              }
            }

            // Calcular strikes y spares de los frames
            if (frames != null) {
              for (final frame in frames) {
                if (frame is List) {
                  totalFrames++;
                  if (frame.isNotEmpty) {
                    // Check for strike
                    if (frame[0] == 'X') {
                      strikes++;
                    }
                    // Check for spare
                    else if (frame.contains('/')) {
                      spares++;
                    }
                  }
                }
              }
            }
          }
        }
      }

      final promedioGeneral =
          totalPartidas > 0 ? sumaTotal / totalPartidas : 0.0;

      // Calcular porcentajes
      final strikesPercent = totalFrames > 0 ? (strikes / totalFrames) * 100 : 0.0;
      final sparesPercent = totalFrames > 0 ? (spares / totalFrames) * 100 : 0.0;

      // Calcular consistencia (desviación estándar)
      double consistencia = 0.0;
      if (puntuaciones.length > 1) {
        double sumaDiferenciasCuadrado = 0;
        for (final puntuacion in puntuaciones) {
          final diferencia = puntuacion - promedioGeneral;
          sumaDiferenciasCuadrado += diferencia * diferencia;
        }
        consistencia = sqrt(sumaDiferenciasCuadrado / puntuaciones.length);
      }

      return {
        'userId': friendId,
        'totalPartidas': totalPartidas,
        'promedioGeneral': promedioGeneral,
        'mejorPartida': mejorPartida,
        'strikesPercent': strikesPercent,
        'sparesPercent': sparesPercent,
        'consistencia': consistencia,
      };
    } catch (e) {
      debugPrint('Error al obtener estadísticas del amigo: $e');
      return null;
    }
  }

  /// Stream de amigos en tiempo real
  Stream<List<Friend>> streamAmigos(String userId) {
    return _getFriendsCollection(userId)
        .orderBy('fechaAmistad', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Friend.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  /// Stream de solicitudes pendientes en tiempo real
  Stream<List<FriendRequest>> streamSolicitudesPendientes(String userId) {
    return _getFriendRequestsCollection(userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              FriendRequest.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
