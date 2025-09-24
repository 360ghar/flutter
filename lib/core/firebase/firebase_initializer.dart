import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import '../utils/debug_logger.dart';
import 'remote_config_service.dart';
import 'push_notifications_service.dart';
import 'dynamic_links_service.dart';

/// Background FCM handler (required to be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    DebugLogger.info('📩 [FCM][BG] Message received: ${message.messageId ?? 'no-id'}');
  } catch (e, st) {
    DebugLogger.error('Failed to init Firebase in BG handler', e, st);
  }
}

class FirebaseInitializer {
  static bool _initialized = false;

  static bool _envFlag(String key, {bool fallback = false}) {
    try {
      final v = dotenv.env[key]?.toLowerCase();
      if (v == null) return fallback;
      return v == '1' || v == 'true' || v == 'yes';
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> init() async {
    if (_initialized) return;

    final shouldInit = _envFlag('FIREBASE_ENABLED', fallback: true);
    if (!shouldInit) {
      DebugLogger.startup('Firebase initialization skipped (FIREBASE_ENABLED=false)');
      return;
    }

    await Firebase.initializeApp();
    DebugLogger.startup('Firebase initialized');

    // Crashlytics minimal setup: enable in debug too for QA builds
    final crashlyticsEnabled = _envFlag('FIREBASE_CRASHLYTICS', fallback: true);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(crashlyticsEnabled);
    DebugLogger.startup('Crashlytics enabled: $crashlyticsEnabled');

    // Analytics disabled by default (privacy-by-default)
    final analyticsEnabled = _envFlag('FIREBASE_ANALYTICS', fallback: false);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(analyticsEnabled);
    DebugLogger.startup('Analytics enabled: $analyticsEnabled');

    // Performance disabled by default, can be toggled remotely later
    final perfEnabled = _envFlag('FIREBASE_PERFORMANCE', fallback: false);
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(perfEnabled);
    DebugLogger.startup('Performance enabled: $perfEnabled');

    // In-App Messaging collection disabled by default
    await FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(
      _envFlag('FIREBASE_IAM', fallback: false),
    );

    // Remote Config bootstrap with safe defaults
    await RemoteConfigService.initializeAndFetch();

    // Apply Remote Config toggles post-fetch
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
        RemoteConfigService.analyticsEnabled,
      );
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        RemoteConfigService.performanceEnabled,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        RemoteConfigService.crashlyticsEnabled,
      );
      await FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(
        RemoteConfigService.iamEnabled,
      );
    } catch (e, st) {
      DebugLogger.warning('Failed applying Remote Config toggles', e);
      DebugLogger.debug('RC toggle apply stack', st);
    }

    // Dynamic Links listener (no-op routing for now, just logging)
    await DynamicLinksService.initializeListener();

    // FCM background handler registration. Foreground permission prompt is opt-in.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _initialized = true;
  }

  /// No-op holder for future extensions
  static void wireGlobalErrorHandlers() {}
}
