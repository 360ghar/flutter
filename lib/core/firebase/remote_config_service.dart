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

  static bool get analyticsEnabled => _rc.getBool('analytics_enabled');
  static bool get performanceEnabled => _rc.getBool('performance_enabled');
  static bool get crashlyticsEnabled => _rc.getBool('crashlytics_enabled');
  static bool get iamEnabled => _rc.getBool('iam_enabled');
  static bool get pushEnabled => _rc.getBool('push_enabled');

  static double get perfHttpSampling => _rc.getDouble('perf_http_sampling');
  static double get perfTraceSampling => _rc.getDouble('perf_trace_sampling');
}
