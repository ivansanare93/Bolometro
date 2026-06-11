const functions = require("firebase-functions");
const {defineString, defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const MAIL_USER = defineString("MAIL_USER");
const MAIL_PASS = defineSecret("MAIL_PASS");

/**
 * Returns localized notification strings for the given language code.
 * Falls back to Spanish if the language is not supported.
 * @param {string} lang - Language code (e.g. 'en', 'es')
 * @return {Object} Localized strings
 */
function getNotificationStrings(lang) {
  const strings = {
    en: {
      friendRequestTitle: "New friend request",
      friendRequestBody: (name) => `${name} has sent you a friend request`,
      friendRequestAcceptedTitle: "Request accepted",
      friendRequestAcceptedBody: (name) => `${name} accepted your friend request`,
      dailyEngagementTitle: "Daily reminder",
      dailyEngagementBody: (missingMinutes) =>
        `Use Bolometro ${missingMinutes} more min today to reach your 5-minute goal`,
    },
    es: {
      friendRequestTitle: "Nueva solicitud de amistad",
      friendRequestBody: (name) => `${name} te ha enviado una solicitud de amistad`,
      friendRequestAcceptedTitle: "Solicitud aceptada",
      friendRequestAcceptedBody: (name) => `${name} ha aceptado tu solicitud de amistad`,
      dailyEngagementTitle: "Recordatorio diario",
      dailyEngagementBody: (missingMinutes) =>
        `Usa Bolómetro ${missingMinutes} min más hoy para llegar a tu objetivo de 5 minutos`,
    },
  };
  return strings[lang] || strings["es"];
}

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

      // Obtener el idioma del usuario
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const lang = (userDoc.exists && userDoc.data().languageCode) || "es";
      const i18n = getNotificationStrings(lang);

      const title = i18n.friendRequestTitle;
      const body = i18n.friendRequestBody(notification.fromUserName || "");
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

      // Obtener el idioma del usuario
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const lang = (userDoc.exists && userDoc.data().languageCode) || "es";
      const i18n = getNotificationStrings(lang);

      const title = i18n.friendRequestAcceptedTitle;
      const body = i18n.friendRequestAcceptedBody(notification.acceptedByUserName || "");
      const data = {
        type: "friend_request_accepted",
        acceptedByUserName: notification.acceptedByUserName || "",
      };

      return sendPushNotification(userId, data, title, body);
    });

/**
 * Enviar notificación push para recordatorio diario de uso.
 * DISABLED: daily reminder feature is disabled.
 */
exports.sendDailyEngagementNotification = functions.firestore
    .document("users/{userId}/notifications/{notificationId}")
    .onCreate(async (snap, context) => {
      return null;
    });

/**
 * Crea recordatorios diarios para usuarios que no alcanzaron 5 minutos de uso.
 * DISABLED: daily reminder feature is disabled.
 */
exports.sendDailyEngagementReminders = functions.pubsub
    .schedule("0 20 * * *")
    .timeZone("Etc/UTC")
    .onRun(async () => {
      return null;
    });

/**
 * Envía un correo electrónico al recibir un nuevo documento en la colección feedback.
 *
 * Requiere los siguientes parámetros/secrets de Firebase Functions:
 *   firebase functions:params:set MAIL_USER="tu_cuenta@gmail.com"
 *   firebase functions:secrets:set MAIL_PASS
 *
 * Para Gmail, usa una "App Password" (contraseña de aplicación) en lugar de la contraseña
 * principal. Actívala en: https://myaccount.google.com/apppasswords
 */

// El transporter se crea una sola vez y se reutiliza entre invocaciones (warm start).
let _mailTransporter = null;

/**
 * Devuelve un transporter de Nodemailer configurado con Firebase params/secrets.
 * @return {Object|null} Transporter o null si faltan credenciales.
 */
function getMailTransporter() {
  if (_mailTransporter) return _mailTransporter;

  const gmailUser = MAIL_USER.value();
  const gmailPass = MAIL_PASS.value();

  if (!gmailUser || !gmailPass) return null;

  _mailTransporter = nodemailer.createTransport({
    service: "gmail",
    auth: {user: gmailUser, pass: gmailPass},
  });

  return _mailTransporter;
}

exports.sendFeedbackEmail = functions
    .runWith({secrets: ["MAIL_PASS"]})
    .firestore
    .document("feedback/{feedbackId}")
    .onCreate(async (snap, context) => {
      const feedback = snap.data();
      const feedbackId = context.params.feedbackId;

      const transporter = getMailTransporter();
      if (!transporter) {
        console.error(
            "Credenciales de correo no configuradas. " +
            "Ejecuta: firebase functions:params:set MAIL_USER=\"...\" " +
            "y firebase functions:secrets:set MAIL_PASS",
        );
        return null;
      }

      const gmailUser = MAIL_USER.value();
      const destinationEmail = feedback.destinationEmail || gmailUser;

      // Construir el asunto y cuerpo del correo
      const typeLabels = {suggestion: "Sugerencia", bug: "Error", other: "Otro"};
      const typeLabel = typeLabels[feedback.type] || feedback.type || "Desconocido";
      const subject = `[Bolometro Feedback] ${typeLabel} - ${feedback.platform || ""}`;

      const lines = [
        `Tipo: ${typeLabel}`,
        `Mensaje: ${feedback.message || ""}`,
        "",
        `Usuario ID: ${feedback.userId || ""}`,
        `Correo del usuario: ${feedback.authEmail || "(no proporcionado)"}`,
        `Valoración: ${feedback.rating != null ? `${feedback.rating}/5` : "(sin valoración)"}`,
        `Versión de la app: ${feedback.appVersion || ""}`,
        `Plataforma: ${feedback.platform || ""}`,
        `Idioma: ${feedback.languageCode || ""}`,
        `ID del documento: ${feedbackId}`,
      ];

      const mailOptions = {
        from: `Bolometro App <${gmailUser}>`,
        to: destinationEmail,
        subject: subject,
        text: lines.join("\n"),
      };

      try {
        const info = await transporter.sendMail(mailOptions);
        console.log("Correo de feedback enviado:", info.messageId);

        // Marcar el documento como procesado
        await snap.ref.update({status: "email_sent"});

        return info;
      } catch (error) {
        console.error("Error al enviar correo de feedback:", error);

        // Marcar el documento con el error para poder revisarlo
        await snap.ref.update({status: "email_error", emailError: String(error)});

        return null;
      }
    });
