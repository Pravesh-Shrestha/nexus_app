const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// 1. Message Trigger: when a new message is sent in chats/{chatId}/messages/{messageId}
exports.onNewMessage = onDocumentCreated("chats/{chatId}/messages/{messageId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const messageData = snapshot.data();
  const senderId = messageData.senderId;
  const text = messageData.text || "";
  const messageType = messageData.type || "text";
  const chatId = event.params.chatId;

  try {
    // Fetch the chat room to identify the participants
    const chatDoc = await admin.firestore().collection("chats").doc(chatId).get();
    if (!chatDoc.exists) return;

    const participants = chatDoc.data().participants || [];
    // Find recipient ID(s)
    const recipientIds = participants.filter(id => id !== senderId);

    if (recipientIds.length === 0) return;

    // Fetch sender profile details to customize the notification message
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ? (senderDoc.data().fullName || "A user") : "A user";

    const bodyText = messageType === "image" ? `${senderName} sent a photo.` : text;

    for (const recipientId of recipientIds) {
      // Fetch recipient's FCM tokens
      const recipientDoc = await admin.firestore().collection("users").doc(recipientId).get();
      if (!recipientDoc.exists) continue;

      const tokens = recipientDoc.data().fcmTokens || [];
      if (tokens.length === 0) continue;

      // Construct FCM notification
      const payload = {
        notification: {
          title: senderName,
          body: bodyText,
        },
        data: {
          type: "chat",
          chatId: chatId,
        },
      };

      // Send to registered tokens
      const response = await admin.messaging().sendEachForMulticast({
        tokens: tokens,
        notification: payload.notification,
        data: payload.data,
      });

      console.log(`Successfully sent ${response.successCount} chat notifications to ${recipientId}.`);
    }
  } catch (error) {
    console.error("Error processing onNewMessage push trigger:", error);
  }
});

// 2. Notification Trigger: when a new document is created in users/{userId}/notifications/{notificationId}
exports.onNewNotification = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const notifData = snapshot.data();
  const title = notifData.title || "Nexus Alert";
  const body = notifData.body || "";
  const type = notifData.type || "general";
  const userId = event.params.userId;

  try {
    // Fetch recipient's FCM tokens
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) return;

    const tokens = userDoc.data().fcmTokens || [];
    if (tokens.length === 0) return;

    const payload = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type,
      },
    };

    // Send to registered tokens
    const response = await admin.messaging().sendEachForMulticast({
      tokens: tokens,
      notification: payload.notification,
      data: payload.data,
    });

    console.log(`Successfully sent ${response.successCount} app notifications to user ${userId}.`);
  } catch (error) {
    console.error("Error processing onNewNotification push trigger:", error);
  }
});
