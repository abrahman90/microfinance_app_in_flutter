import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      // Get FCM token
      String? token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
      
      if (token != null) {
        // Save token to Firestore for the current user
        await _saveTokenToFirestore(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _saveTokenToFirestore(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification clicks when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

      // Handle initial message when app is opened from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  // Save FCM token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token saved for user: $userId');
      } else {
        debugPrint('No user logged in to save FCM token');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }
  }

  // Handle notification clicks
  void _handleNotificationClick(RemoteMessage message) {
    debugPrint('Notification clicked!');
    debugPrint('Message data: ${message.data}');

    // Get the current context
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('No context available');
      return;
    }

    // Navigate to the appropriate screen based on the notification data
    if (message.data['type'] == 'loan_approved') {
      Navigator.of(context).pushNamed('/loan_details', arguments: {
        'loanId': message.data['loanId'],
      });
    } else if (message.data['type'] == 'loan_rejected') {
      Navigator.of(context).pushNamed('/loan_history');
    }
  }

  // Send notification to a specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('Attempting to send notification to user: $userId');
      
      // Get user's FCM token from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      String? fcmToken = userDoc.get('fcmToken');

      if (fcmToken != null) {
        debugPrint('Found FCM token for user: $fcmToken');
        
        // Send notification using Cloud Functions
        await _firestore.collection('notifications').add({
          'userId': userId,
          'title': title,
          'body': body,
          'fcmToken': fcmToken,
          'data': data ?? {},
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
        
        debugPrint('Notification sent successfully');
      } else {
        debugPrint('No FCM token found for user: $userId');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); 