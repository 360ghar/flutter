import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:ghar360/core/firebase/remote_config_service.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final Set<String> _seenProperties = <String>{};

  static bool get _enabled => RemoteConfigService.analyticsEnabled;

  static Future<void> setUserId(String? userId) async {
    if (!_enabled) return;
    try {
      await _analytics.setUserId(id: userId);
    } catch (e, st) {
      DebugLogger.warning('Analytics setUserId failed', e);
      DebugLogger.debug('Analytics setUserId stack', st);
    }
  }

  static Future<void> setUserProperty(String name, String value) async {
    if (!_enabled) return;
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e, st) {
      DebugLogger.warning('Analytics setUserProperty failed', e);
      DebugLogger.debug('Analytics setUserProperty stack', st);
    }
  }

  static Future<void> logVital(String name, {Map<String, Object?>? params}) async {
    if (!_enabled) return;
    try {
      await _analytics.logEvent(name: name, parameters: params);
      DebugLogger.debug('📊 Analytics event: $name ${params ?? {}}');
    } catch (e, st) {
      DebugLogger.warning('Analytics logEvent failed', e);
      DebugLogger.debug('Analytics logEvent stack', st);
    }
  }

  // Suggested canonical events for vital flows
  static Future<void> login({String? method}) => logVital('login', params: {'method': method});
  static Future<void> signUp({String? method}) => logVital('sign_up', params: {'method': method});
  static Future<void> viewProperty(String propertyId) =>
      logVital('property_view', params: {'id': propertyId});
  static Future<void> viewPropertyOnce(String propertyId) async {
    if (_seenProperties.contains(propertyId)) return;
    _seenProperties.add(propertyId);
    await viewProperty(propertyId);
  }

  static Future<void> likeProperty(String propertyId) =>
      logVital('property_like', params: {'id': propertyId});
  static Future<void> scheduleVisit(String propertyId) =>
      logVital('visit_schedule', params: {'id': propertyId});
  static Future<void> applyFilter(Map<String, Object?> snapshot) =>
      logVital('filters_apply', params: snapshot);
}
