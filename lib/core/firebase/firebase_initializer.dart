import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ghar360/core/firebase/deep_link_service.dart';
import 'package:ghar360/core/firebase/remote_config_service.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/firebase_options.dart';

/// Background FCM handler (required to be a top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    DebugLogger.startup('Firebase initialized');

    // App Check (Play Integrity / DeviceCheck). Web uses reCAPTCHA v3 if provided.
    final appCheckEnabled = _envFlag('FIREBASE_APPCHECK', fallback: true);
    if (appCheckEnabled) {
      try {
        if (kIsWeb) {
          final siteKey = dotenv.env['RECAPTCHA_V3_SITE_KEY'];
          if (siteKey != null && siteKey.isNotEmpty) {
            await FirebaseAppCheck.instance.activate(providerWeb: ReCaptchaV3Provider(siteKey));
            DebugLogger.startup('App Check (Web) activated with reCAPTCHA v3');
          } else {
            DebugLogger.warning(
              'App Check (Web) site key missing; skipping web App Check activation',
            );
          }
        } else {
          final debugMode = _envFlag('FIREBASE_APPCHECK_DEBUG', fallback: !kReleaseMode);
          await FirebaseAppCheck.instance.activate(
            androidProvider: debugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
            appleProvider: debugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
          );
          await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
          DebugLogger.startup('Firebase App Check activated (debugMode=$debugMode)');
        }
      } catch (e, st) {
        DebugLogger.warning('App Check activation failed', e, st);
      }
    }

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
    bool rcFetched = false;
    try {
      await RemoteConfigService.initializeAndFetch();
      rcFetched = true;
    } catch (e, st) {
      DebugLogger.warning('Remote Config fetch failed; keeping env flags', e, st);
    }

    // Apply Remote Config toggles post-fetch and honor user consent when available
    try {
      if (!rcFetched) {
        // Preserve env-based settings if RC not fetched
        DebugLogger.debug('Skip RC toggles application (no fresh config)');
        _initialized = true;
        return;
      }
      final storage = GetStorage();
      bool consent(String key) {
        final v = storage.read(key);
        return v is bool ? v : true; // Default allow until explicit choice
      }

      final analyticsOn = RemoteConfigService.analyticsEnabled && consent('consent_analytics');
      final perfOn = RemoteConfigService.performanceEnabled && consent('consent_performance');

      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(analyticsOn);
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(perfOn);
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        RemoteConfigService.crashlyticsEnabled,
      );
      await FirebaseInAppMessaging.instance.setAutomaticDataCollectionEnabled(
        RemoteConfigService.iamEnabled,
      );
      DebugLogger.startup('Consent gating → analytics=$analyticsOn, performance=$perfOn');
    } catch (e, st) {
      DebugLogger.warning('Failed applying Remote Config toggles', e, st);
    }

    // Deep Links listener (App Links - replaces deprecated Firebase Dynamic Links)
    await DeepLinkService.initializeListener();

    // FCM background handler registration. Foreground permission prompt is opt-in.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _initialized = true;
  }

  /// No-op holder for future extensions
  static void wireGlobalErrorHandlers() {}
}
