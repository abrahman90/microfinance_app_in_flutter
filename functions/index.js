const functions = require ("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.setUserClaims = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Only authenticated users can make requests",
    );
  }

  const {targetUserId, claims} = data;

  if (!targetUserId || typeof claims !== "object") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The function must be called with targetUserId and claims",
    );
  }

  try {
    await admin.auth().setCustomUserClaims(targetUserId, claims);
    return {success: true};
  } catch (error) {
    console.error("Error setting claims:", error);
    throw new functions.https.HttpsError(
        "internal",
        "Unable to set custom claims",
    );
  }
});

exports.sendNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    
    if (!notification) {
      console.log('No notification data');
      return null;
    }

    const { fcmToken, title, body } = notification;

    if (!fcmToken) {
      console.log('No FCM token found');
      return null;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      token: fcmToken,
    };

    try {
      await admin.messaging().send(message);
      console.log('Successfully sent notification');
      
      // Update notification status
      await snap.ref.update({
        'sent': true,
        'sentAt': admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return null;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });