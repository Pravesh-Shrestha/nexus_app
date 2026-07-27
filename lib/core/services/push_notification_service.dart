import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:nexus_app/main.dart';
import 'package:nexus_app/features/home/presentation/notifications_screen.dart';
import 'package:nexus_app/features/chat/presentation/inbox_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM Background Message Handled: ${message.messageId}');
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
    'nexus_push_channel',
    'Nexus Notifications',
    description: 'Heads-up banners for Nexus games, squads, and connections',
    importance: Importance.high,
    playSound: true,
  );

  static void _handleNotificationTap(Map<String, dynamic> data) {
    debugPrint('Processing notification tap payload: $data');
    final String type = data['type'] ?? '';
    
    // Perform routing based on notification type
    if (type == 'friend_request' || type == 'invite' || type == 'mention') {
      MyApp.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
    } else if (type == 'chat') {
      MyApp.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const InboxScreen()),
      );
    }
  }

  static Future<void> initialize() async {
    // 1. Set up Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Configure Local Notifications for Foreground Banners
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(response.payload!);
            _handleNotificationTap(data);
          } catch (e) {
            debugPrint('Error decoding notification payload: $e');
          }
        }
      },
    );

    // Create the high importance channel on Android
    final androidImplementation = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(_androidChannel);
    }

    // 3. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: android.smallIcon ?? '@mipmap/launcher_icon',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 4. Handle Notification Tap when App is in Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });

    // 5. Handle Notification Tap when App was opened from Terminated State
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });

    // 6. Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
    });
  }

  static Future<void> requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('FCM Permission Status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('FCM Request Permission Error: $e');
    }
  }

  static Future<void> getAndSaveToken(String userId) async {
    if (userId.isEmpty) return;
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token Retrieved: $token');
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FCM Get Token Error: $e');
    }
  }

  static Future<String?> _getAccessToken() async {
    try {
      final String serviceAccountJson = await rootBundle.loadString('assets/config/service-account.json');
      final Map<String, dynamic> accountCredentials = jsonDecode(serviceAccountJson);
      final auth.ServiceAccountCredentials credentials = auth.ServiceAccountCredentials.fromJson(accountCredentials);
      final List<String> scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final client = await auth.clientViaServiceAccount(credentials, scopes);
      return client.credentials.accessToken.data;
    } catch (e) {
      debugPrint('Failed to get FCM Access Token: $e');
      return null;
    }
  }

  static Future<void> sendPushToUser({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    Map<String, String>? extraData,
  }) async {
    try {
      // 1. Fetch recipient tokens from Firestore
      final recipientDoc = await FirebaseFirestore.instance.collection('users').doc(recipientId).get();
      if (!recipientDoc.exists) return;

      final List<dynamic> tokens = recipientDoc.data()?['fcmTokens'] ?? [];
      if (tokens.isEmpty) return;

      // 2. Fetch OAuth2 token
      final String? accessToken = await _getAccessToken();
      if (accessToken == null) return;

      final String url = 'https://fcm.googleapis.com/v1/projects/nexus-flutter-fe83a/messages:send';

      for (final dynamic token in tokens) {
        final Map<String, dynamic> payload = {
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'type': type,
              ...?extraData,
            },
          }
        };

        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          debugPrint('Successfully sent push notification to token: $token');
        } else {
          debugPrint('Failed to send push notification: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }
}
