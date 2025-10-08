import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

class PushNotificationsService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Minimal local notifications setup (no permission prompts here)
  static Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _fln.initialize(settings);

    // Create a high-importance default channel for Android 8+
    try {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'General Notifications',
        description: 'General updates and alerts',
        importance: Importance.max,
      );

      final androidPlugin = _fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    } catch (e, st) {
      DebugLogger.warning('Failed to create Android notification channel', e, st);
    }
  }

  static Future<void> initializeForegroundHandling() async {
    if (_initialized) return;
    await initLocalNotifications();

    // Show heads-up notifications when message arrives in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      DebugLogger.info('📩 [FCM][FG] ${message.messageId ?? 'no-id'}');
      final notification = message.notification;
      if (notification != null) {
        await _showLocal(notification, message.data);
      }
    });

    _initialized = true;
  }

  static Future<NotificationSettings> requestUserPermission({bool provisional = false}) async {
    // iOS/Apple platforms
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: provisional,
      sound: true,
    );
    DebugLogger.info('🔔 FCM permission: ${settings.authorizationStatus}');
    // Android 13+ requires runtime permission for notifications
    try {
      final androidPlugin = _fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e, st) {
      DebugLogger.warning('Android notifications permission request failed', e, st);
    }
    return settings;
  }

  static Future<String?> getToken() async {
    try {
      String? token;
      if (kIsWeb) {
        token = await _messaging.getToken(vapidKey: null);
      } else if (Platform.isIOS || Platform.isMacOS) {
        token = await _messaging.getAPNSToken();
        token ??= await _messaging.getToken();
      } else {
        token = await _messaging.getToken();
      }
      DebugLogger.info('🔑 FCM token: ${token ?? 'null'}');
      return token;
    } catch (e, st) {
      DebugLogger.warning('FCM getToken failed', e, st);
      return null;
    }
  }

  static Future<void> _showLocal(RemoteNotification notification, Map<String, dynamic> data) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'General Notifications',
        channelDescription: 'General updates and alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final id = (DateTime.now().millisecondsSinceEpoch & 0x7fffffff);
    await _fln.show(
      id,
      notification.title,
      notification.body,
      details,
      payload: data.isEmpty ? null : jsonEncode(data),
    );
  }
}
