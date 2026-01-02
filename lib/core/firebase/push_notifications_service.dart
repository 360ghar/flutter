import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Callback type for when a notification is tapped
typedef NotificationTapCallback = void Function(Map<String, dynamic> data);

/// Callback type for registering FCM token with backend
typedef TokenRegistrationCallback = Future<void> Function(String token);

class PushNotificationsService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _currentToken;

  /// Callback to handle notification taps
  static NotificationTapCallback? onNotificationTap;

  /// Callback to register token with backend
  static TokenRegistrationCallback? onTokenRegistration;

  /// Get the current FCM token (may be null if not yet retrieved)
  static String? get currentToken => _currentToken;

  /// Initialize local notifications with proper channel setup
  static Future<void> initLocalNotifications() async {
    DebugLogger.info('🔔 Initializing local notifications...');

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _fln.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Create a high-importance default channel for Android 8+
    try {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'General Notifications',
        description: 'General updates and alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidPlugin = _fln
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
      DebugLogger.success('🔔 Notification channel "high_importance_channel" created');
    } catch (e, st) {
      DebugLogger.warning('Failed to create Android notification channel', e, st);
    }
  }

  /// Handle notification tap when app is in foreground or background
  static void _onNotificationTapped(NotificationResponse response) {
    DebugLogger.info('🔔 Notification tapped: ${response.payload}');
    _handleNotificationPayload(response.payload);
  }

  /// Handle notification tap when app was terminated
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    DebugLogger.info('🔔 Background notification tapped: ${response.payload}');
    _handleNotificationPayload(response.payload);
  }

  /// Process the notification payload and trigger callback
  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      onNotificationTap?.call(data);
      _navigateByPayload(data);
    } catch (e) {
      DebugLogger.warning('Failed to parse notification payload', e);
    }
  }

  /// Navigate based on notification data
  static void _navigateByPayload(Map<String, dynamic> data) {
    // Example navigation logic - customize based on your app's needs
    final route = data['route'] as String?;
    final propertyId = data['property_id'] as String?;

    if (route != null && route.isNotEmpty) {
      DebugLogger.info('🔔 Navigating to route: $route');
      Get.toNamed(route, arguments: data);
    } else if (propertyId != null) {
      DebugLogger.info('🔔 Navigating to property: $propertyId');
      Get.toNamed('/property/$propertyId');
    }
  }

  /// Initialize FCM handling for all app states
  static Future<void> initializeForegroundHandling() async {
    if (_initialized) {
      DebugLogger.debug('🔔 Push notifications already initialized');
      return;
    }

    DebugLogger.info('🔔 Initializing FCM handling...');
    await initLocalNotifications();

    // Configure foreground notification presentation options (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      DebugLogger.info('📩 [FCM][FOREGROUND] Message ID: ${message.messageId ?? 'no-id'}');
      DebugLogger.info('📩 [FCM][FOREGROUND] Title: ${message.notification?.title}');
      DebugLogger.info('📩 [FCM][FOREGROUND] Body: ${message.notification?.body}');
      DebugLogger.info('📩 [FCM][FOREGROUND] Data: ${message.data}');

      final notification = message.notification;
      if (notification != null) {
        await _showLocal(notification, message.data);
      }
    });

    // Handle notification tap when app is in background (but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      DebugLogger.info('📩 [FCM][OPENED_APP] Message tapped from background: ${message.messageId}');
      _handleRemoteMessage(message);
    });

    // Handle notification tap that launched the app from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      DebugLogger.info('📩 [FCM][INITIAL] App launched via notification: ${initialMessage.messageId}');
      // Delay navigation slightly to ensure app is fully loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleRemoteMessage(initialMessage);
      });
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      DebugLogger.info('🔑 FCM token refreshed: ${_truncateToken(newToken)}');
      _currentToken = newToken;
      await _registerToken(newToken);
    });

    _initialized = true;
    DebugLogger.success('🔔 FCM handling initialized successfully');
  }

  /// Handle FCM remote message data
  static void _handleRemoteMessage(RemoteMessage message) {
    onNotificationTap?.call(message.data);
    _navigateByPayload(message.data);
  }

  /// Request notification permissions from the user
  static Future<NotificationSettings> requestUserPermission({bool provisional = false}) async {
    DebugLogger.info('🔔 Requesting FCM permission...');

    // iOS/Apple platforms - request permission via FCM
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: provisional,
      sound: true,
    );

    final status = settings.authorizationStatus;
    switch (status) {
      case AuthorizationStatus.authorized:
        DebugLogger.success('🔔 FCM permission: AUTHORIZED');
        break;
      case AuthorizationStatus.provisional:
        DebugLogger.info('🔔 FCM permission: PROVISIONAL');
        break;
      case AuthorizationStatus.denied:
        DebugLogger.warning('🔔 FCM permission: DENIED - notifications will not work!');
        break;
      case AuthorizationStatus.notDetermined:
        DebugLogger.warning('🔔 FCM permission: NOT DETERMINED');
        break;
    }

    // Android 13+ requires runtime permission for notifications
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidPlugin = _fln
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        if (granted == true) {
          DebugLogger.success('🔔 Android notification permission: GRANTED');
        } else {
          DebugLogger.warning('🔔 Android notification permission: DENIED or not requested');
        }
      } catch (e, st) {
        DebugLogger.warning('Android notifications permission request failed', e, st);
      }
    }

    return settings;
  }

  /// Get the FCM token and optionally register it with the backend
  static Future<String?> getToken() async {
    try {
      String? token;
      if (kIsWeb) {
        // For web, you may need a VAPID key
        token = await _messaging.getToken(vapidKey: null);
      } else if (Platform.isIOS || Platform.isMacOS) {
        // Wait for APNS token first on iOS
        final apnsToken = await _messaging.getAPNSToken();
        DebugLogger.info('🍎 APNS token: ${apnsToken != null ? "received" : "null"}');
        token = await _messaging.getToken();
      } else {
        token = await _messaging.getToken();
      }

      if (token != null) {
        DebugLogger.success('🔑 FCM token retrieved: ${_truncateToken(token)}');
        _currentToken = token;
        await _registerToken(token);
      } else {
        DebugLogger.warning('🔑 FCM token is null - notifications will not work!');
      }

      return token;
    } catch (e, st) {
      DebugLogger.error('FCM getToken failed', e, st);
      return null;
    }
  }

  /// Register the FCM token with the backend
  static Future<void> _registerToken(String token) async {
    if (onTokenRegistration != null) {
      try {
        await onTokenRegistration!(token);
        DebugLogger.success('🔑 FCM token registered with backend');
      } catch (e, st) {
        DebugLogger.warning('Failed to register FCM token with backend', e, st);
      }
    } else {
      DebugLogger.debug('🔑 No token registration callback set - token not sent to backend');
      // Log the full token in debug mode for manual testing
      if (kDebugMode) {
        DebugLogger.info('🔑 FULL FCM TOKEN (for testing): $token');
      }
    }
  }

  /// Show a local notification for foreground FCM messages
  static Future<void> _showLocal(RemoteNotification notification, Map<String, dynamic> data) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'General Notifications',
        channelDescription: 'General updates and alerts',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final id = (DateTime.now().millisecondsSinceEpoch & 0x7fffffff);
    await _fln.show(
      id,
      notification.title,
      notification.body,
      details,
      payload: data.isEmpty ? null : jsonEncode(data),
    );
    DebugLogger.info('🔔 Local notification displayed: ${notification.title}');
  }

  /// Truncate token for logging (security)
  static String _truncateToken(String token) {
    if (token.length <= 20) return token;
    return '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
  }

  /// Check if notifications are enabled for the app
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _fln
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      }
      return true; // iOS handles this differently
    } catch (e) {
      DebugLogger.warning('Failed to check notification enabled status', e);
      return false;
    }
  }

  /// Delete the FCM token (useful for logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      DebugLogger.info('🔑 FCM token deleted');
    } catch (e, st) {
      DebugLogger.warning('Failed to delete FCM token', e, st);
    }
  }
}
