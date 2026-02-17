const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

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

        // Construir el mensaje de notificación
        const message = {
          notification: {
            title: "Nueva solicitud de amistad",
            body: `${notification.fromUserName} te ha enviado una solicitud de amistad`,
          },
          data: {
            type: "friend_request",
            requestId: notification.requestId || "",
            fromUserName: notification.fromUserName || "",
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
                badge: 1,
              },
            },
          },
        };

        // Enviar la notificación
        const response = await admin.messaging().send(message);
        console.log("Successfully sent friend request notification:", response);

        return response;
      } catch (error) {
        console.error("Error sending friend request notification:", error);
        return null;
      }
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

        // Construir el mensaje de notificación
        const message = {
          notification: {
            title: "Solicitud aceptada",
            body: `${notification.acceptedByUserName} ha aceptado tu solicitud de amistad`,
          },
          data: {
            type: "friend_request_accepted",
            acceptedByUserName: notification.acceptedByUserName || "",
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
                badge: 1,
              },
            },
          },
        };

        // Enviar la notificación
        const response = await admin.messaging().send(message);
        console.log("Successfully sent friend request accepted notification:", response);

        return response;
      } catch (error) {
        console.error("Error sending friend request accepted notification:", error);
        return null;
      }
    });
