import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
        debugPrint('Notification tapped: ${response.payload}');
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
          payload: message.data.toString(),
        );
      }
    });

    // 4. Handle token refresh
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
}
