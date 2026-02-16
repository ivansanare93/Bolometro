import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para gestionar notificaciones push con Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    try {
      // Solicitar permisos de notificación
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Permisos de notificación concedidos');

        // Obtener el token FCM
        _fcmToken = await _messaging.getToken();
        debugPrint('FCM Token: $_fcmToken');

        // Escuchar cambios en el token
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('FCM Token actualizado: $newToken');
        });

        // Configurar manejadores de mensajes
        _setupMessageHandlers();
      } else {
        debugPrint('Permisos de notificación denegados');
      }
    } catch (e) {
      debugPrint('Error al inicializar notificaciones: $e');
    }
  }

  /// Configurar manejadores de mensajes
  void _setupMessageHandlers() {
    // Mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensaje recibido en primer plano: ${message.notification?.title}');
      _handleMessage(message);
    });

    // Mensajes cuando la app está en segundo plano pero abierta
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notificación abierta desde segundo plano: ${message.notification?.title}');
      _handleMessage(message);
    });
  }

  /// Manejar un mensaje recibido
  void _handleMessage(RemoteMessage message) {
    // Aquí puedes agregar lógica personalizada según el tipo de notificación
    final data = message.data;
    final type = data['type'];

    debugPrint('Tipo de notificación: $type');
    debugPrint('Datos: $data');

    // Los mensajes se manejarán en la UI a través de streams o callbacks
  }

  /// Guardar el token FCM del usuario en Firestore
  Future<void> saveUserToken(String userId) async {
    if (_fcmToken == null) {
      debugPrint('No hay token FCM para guardar');
      return;
    }

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Token FCM guardado para usuario: $userId');
    } catch (e) {
      debugPrint('Error al guardar token FCM: $e');
    }
  }

  /// Eliminar el token FCM del usuario de Firestore
  Future<void> deleteUserToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      debugPrint('Token FCM eliminado para usuario: $userId');
    } catch (e) {
      debugPrint('Error al eliminar token FCM: $e');
    }
  }

  /// Enviar notificación de solicitud de amistad
  /// Nota: Esta función agrega la notificación a una colección en Firestore
  /// Las notificaciones push reales se enviarán desde Cloud Functions
  Future<void> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserName,
    required String requestId,
  }) async {
    try {
      // Guardar notificación en Firestore
      // Cloud Functions puede leer esto y enviar la push notification
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
        'type': 'friend_request',
        'fromUserName': fromUserName,
        'requestId': requestId,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      debugPrint('Notificación de solicitud de amistad creada para: $toUserId');
    } catch (e) {
      debugPrint('Error al crear notificación de solicitud de amistad: $e');
    }
  }

  /// Enviar notificación de solicitud aceptada
  Future<void> sendFriendRequestAcceptedNotification({
    required String toUserId,
    required String acceptedByUserName,
  }) async {
    try {
      // Guardar notificación en Firestore
      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
        'type': 'friend_request_accepted',
        'acceptedByUserName': acceptedByUserName,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      debugPrint('Notificación de solicitud aceptada creada para: $toUserId');
    } catch (e) {
      debugPrint('Error al crear notificación de solicitud aceptada: $e');
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<void> markNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'read': true});
      }

      await batch.commit();
      debugPrint('Notificaciones marcadas como leídas para: $userId');
    } catch (e) {
      debugPrint('Error al marcar notificaciones como leídas: $e');
    }
  }

  /// Obtener stream de notificaciones no leídas
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

/// Manejador de mensajes en segundo plano
/// Debe ser una función de nivel superior
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Manejando mensaje en segundo plano: ${message.messageId}');
}
