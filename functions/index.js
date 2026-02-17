const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Helper function para enviar notificaciones push
 * @param {string} userId - ID del usuario destinatario
 * @param {Object} notificationData - Datos de la notificación
 * @param {string} title - Título de la notificación
 * @param {string} body - Cuerpo de la notificación
 * @return {Promise} Resultado del envío
 */
async function sendPushNotification(userId, notificationData, title, body) {
  try {
    // Obtener el token FCM del usuario destinatario
    const userDoc = await admin.firestore().collection("users").doc(userId).get();

    if (!userDoc.exists) {
      console.error("User document does not exist:", userId);
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log("No FCM token found for user:", userId);
      return null;
    }

    // Obtener el número de notificaciones no leídas para el badge
    const unreadSnapshot = await admin.firestore()
        .collection("users")
        .doc(userId)
        .collection("notifications")
        .where("read", "==", false)
        .get();

    const badgeCount = unreadSnapshot.size;

    // Construir el mensaje de notificación
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        ...notificationData,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      token: fcmToken,
      android: {
        priority: "high",
        notification: {
          sound: "default",
          channelId: "friend_requests",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: badgeCount,
          },
        },
      },
    };

    // Enviar la notificación
    const response = await admin.messaging().send(message);
    console.log("Successfully sent notification:", response, "Badge count:", badgeCount);

    return response;
  } catch (error) {
    console.error("Error sending notification:", error);
    return null;
  }
}

/**
 * Enviar notificación push cuando se crea una nueva notificación de solicitud de amistad
 */
exports.sendFriendRequestNotification = functions.firestore
    .document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const notification = snap.data();
      const userId = context.params.userId;

      // Solo procesar notificaciones de tipo 'friend_request'
      if (notification.type !== "friend_request") {
        console.log("Not a friend request notification, skipping");
        return null;
      }

      const title = "Nueva solicitud de amistad";
      const body = `${notification.fromUserName} te ha enviado una solicitud de amistad`;
      const data = {
        type: "friend_request",
        requestId: notification.requestId || "",
        fromUserName: notification.fromUserName || "",
      };

      return sendPushNotification(userId, data, title, body);
    });

/**
 * Enviar notificación push cuando se acepta una solicitud de amistad
 */
exports.sendFriendRequestAcceptedNotification = functions.firestore
    .document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      const notification = snap.data();
      const userId = context.params.userId;

      // Solo procesar notificaciones de tipo 'friend_request_accepted'
      if (notification.type !== "friend_request_accepted") {
        console.log("Not a friend request accepted notification, skipping");
        return null;
      }

      const title = "Solicitud aceptada";
      const body = `${notification.acceptedByUserName} ha aceptado tu solicitud de amistad`;
      const data = {
        type: "friend_request_accepted",
        acceptedByUserName: notification.acceptedByUserName || "",
      };

      return sendPushNotification(userId, data, title, body);
    });

