import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

class RemoteConfigService {
  static FirebaseRemoteConfig get _rc => FirebaseRemoteConfig.instance;

  static const _defaults = <String, dynamic>{
    'analytics_enabled': false,
    'performance_enabled': false,
    'crashlytics_enabled': true,
    'iam_enabled': false,
    'push_enabled': true,
    // sampling ratios (0.0 - 1.0)
    'perf_http_sampling': 0.0,
    'perf_trace_sampling': 0.0,
    // App Version Management (for in-app update feature)
    // Set these values in Firebase Console -> Remote Config
    'android_latest_version': '1.0.0',
    'android_min_version': '1.0.0',
    'android_force_update': false,
    'android_update_url': 'https://play.google.com/store/apps/details?id=com.ghar360.app',
    'android_release_notes': '',
    'ios_latest_version': '1.0.0',
    'ios_min_version': '1.0.0',
    'ios_force_update': false,
    'ios_update_url': 'https://apps.apple.com/app/id123456789',
    'ios_release_notes': '',
  };

  static Future<void> initializeAndFetch() async {
    try {
      await _rc.setDefaults(_defaults);
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 15),
          minimumFetchInterval: kReleaseMode
              ? const Duration(hours: 1)
              : const Duration(minutes: 1),
        ),
      );
      await _rc.fetchAndActivate();
      DebugLogger.startup('Remote Config fetched.');
    } catch (e, st) {
      DebugLogger.warning('Remote Config init failed', e, st);
    }
  }

  /// Force-fetch Remote Config (bypasses cache interval)
  /// Use this when you need the latest values immediately (e.g., on app resume)
  static Future<bool> forceFetch() async {
    try {
      final activated = await _rc.fetchAndActivate();
      DebugLogger.debug('Remote Config force-fetched, activated: $activated');
      return activated;
    } catch (e, st) {
      DebugLogger.warning('Remote Config force-fetch failed', e, st);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Feature Toggles
  // ─────────────────────────────────────────────────────────────────────────
  static bool get analyticsEnabled => _rc.getBool('analytics_enabled');
  static bool get performanceEnabled => _rc.getBool('performance_enabled');
  static bool get crashlyticsEnabled => _rc.getBool('crashlytics_enabled');
  static bool get iamEnabled => _rc.getBool('iam_enabled');
  static bool get pushEnabled => _rc.getBool('push_enabled');

  static double get perfHttpSampling => _rc.getDouble('perf_http_sampling');
  static double get perfTraceSampling => _rc.getDouble('perf_trace_sampling');

  // ─────────────────────────────────────────────────────────────────────────
  // App Version Management (Android)
  // ─────────────────────────────────────────────────────────────────────────
  static String get androidLatestVersion => _rc.getString('android_latest_version');
  static String get androidMinVersion => _rc.getString('android_min_version');
  static bool get androidForceUpdate => _rc.getBool('android_force_update');
  static String get androidUpdateUrl => _rc.getString('android_update_url');
  static String get androidReleaseNotes => _rc.getString('android_release_notes');

  // ─────────────────────────────────────────────────────────────────────────
  // App Version Management (iOS)
  // ─────────────────────────────────────────────────────────────────────────
  static String get iosLatestVersion => _rc.getString('ios_latest_version');
  static String get iosMinVersion => _rc.getString('ios_min_version');
  static bool get iosForceUpdate => _rc.getBool('ios_force_update');
  static String get iosUpdateUrl => _rc.getString('ios_update_url');
  static String get iosReleaseNotes => _rc.getString('ios_release_notes');
}
