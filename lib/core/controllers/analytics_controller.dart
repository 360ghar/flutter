import 'package:get/get.dart';
import '../data/providers/api_service.dart';
import 'auth_controller.dart';
import '../utils/debug_logger.dart';

class AnalyticsController extends GetxController {
  late final ApiService _apiService;
  late final AuthController _authController;
  
  // Session tracking
  String? _sessionId;
  final Map<String, dynamic> _sessionEvents = {};

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();
    
    // Always initialize session (even for non-authenticated users)
    _initializeSession();
  }

  void _initializeSession() {
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    
    // Track app open
    trackEvent('app_opened', {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': GetPlatform.isAndroid ? 'android' : GetPlatform.isIOS ? 'ios' : 'web',
    });
  }


  Future<void> trackEvent(String eventType, Map<String, dynamic> eventData) async {
    try {
      // Add session data
      final enrichedEventData = {
        ...eventData,
        'session_id': _sessionId,
        'timestamp': DateTime.now().toIso8601String(),
        'user_agent': _getUserAgent(),
      };

      // Store locally for offline support
      _sessionEvents[eventType] = enrichedEventData;

      // Send to backend if authenticated
      if (_authController.isAuthenticated) {
        await _apiService.trackEvent(
          eventType,
          enrichedEventData,
          sessionId: _sessionId,
          userAgent: _getUserAgent(),
        );
      }
      
      DebugLogger.info('Event tracked: $eventType');
    } catch (e, stackTrace) {
      DebugLogger.error('Error tracking event $eventType', e, stackTrace);
    }
  }

  String _getUserAgent() {
    if (GetPlatform.isAndroid) {
      return 'GharApp/1.0.0 (Android)';
    } else if (GetPlatform.isIOS) {
      return 'GharApp/1.0.0 (iOS)';
    } else if (GetPlatform.isWeb) {
      return 'GharApp/1.0.0 (Web)';
    } else {
      return 'GharApp/1.0.0 (Unknown)';
    }
  }

  // Specific tracking methods for common events
  Future<void> trackPropertyView(String propertyId, {
    String source = 'unknown',
    int viewDuration = 0,
  }) async {
    await trackEvent('property_view', {
      'property_id': propertyId,
      'source': source,
      'view_duration_seconds': viewDuration,
    });
  }

  Future<void> trackPropertySwipe(String propertyId, String direction, bool isLiked) async {
    await trackEvent('property_swipe', {
      'property_id': propertyId,
      'swipe_direction': direction,
      'is_liked': isLiked,
    });
  }

  Future<void> trackSearch(String query, Map<String, dynamic> filters, int resultsCount) async {
    await trackEvent('property_search', {
      'search_query': query,
      'filters': filters,
      'results_count': resultsCount,
    });
  }

  Future<void> trackFilterChange(Map<String, dynamic> oldFilters, Map<String, dynamic> newFilters) async {
    await trackEvent('filter_changed', {
      'old_filters': oldFilters,
      'new_filters': newFilters,
      'filter_changes': _getFilterChanges(oldFilters, newFilters),
    });
  }

  Map<String, dynamic> _getFilterChanges(Map<String, dynamic> oldFilters, Map<String, dynamic> newFilters) {
    final changes = <String, dynamic>{};
    
    // Compare each filter
    final allKeys = {...oldFilters.keys, ...newFilters.keys};
    
    for (final key in allKeys) {
      final oldValue = oldFilters[key];
      final newValue = newFilters[key];
      
      if (oldValue != newValue) {
        changes[key] = {
          'from': oldValue,
          'to': newValue,
        };
      }
    }
    
    return changes;
  }

  Future<void> trackScreenView(String screenName, {
    Map<String, dynamic>? screenParams,
  }) async {
    await trackEvent('screen_view', {
      'screen_name': screenName,
      'screen_params': screenParams ?? {},
    });
  }

  Future<void> trackUserAction(String action, {
    Map<String, dynamic>? actionData,
  }) async {
    await trackEvent('user_action', {
      'action': action,
      'action_data': actionData ?? {},
    });
  }

  Future<void> trackPropertyInterest(String propertyId, String interestType) async {
    await trackEvent('property_interest', {
      'property_id': propertyId,
      'interest_type': interestType,
    });
  }

  Future<void> trackVisitScheduled(String propertyId, String visitType) async {
    await trackEvent('visit_scheduled', {
      'property_id': propertyId,
      'visit_type': visitType,
    });
  }

  Future<void> trackLocationPermission(bool granted) async {
    await trackEvent('location_permission', {
      'granted': granted,
    });
  }

  Future<void> trackAppFeatureUsage(String feature, Map<String, dynamic> usageData) async {
    await trackEvent('feature_usage', {
      'feature': feature,
      'usage_data': usageData,
    });
  }

  Future<void> trackError(String errorType, String errorMessage, {
    String? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    await trackEvent('app_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'context': context ?? {},
    });
  }

  Future<void> trackPerformance(String operation, int durationMs, {
    bool success = true,
    Map<String, dynamic>? metadata,
  }) async {
    await trackEvent('performance', {
      'operation': operation,
      'duration_ms': durationMs,
      'success': success,
      'metadata': metadata ?? {},
    });
  }


  // Session management
  void endSession() {
    trackEvent('session_ended', {
      'session_duration_ms': _getSessionDuration(),
      'events_count': _sessionEvents.length,
    });
    _sessionEvents.clear();
  }

  int _getSessionDuration() {
    if (_sessionId == null) return 0;
    final sessionStart = int.tryParse(_sessionId!.split('_').last) ?? 0;
    return DateTime.now().millisecondsSinceEpoch - sessionStart;
  }

  @override
  void onClose() {
    endSession();
    super.onClose();
  }

  // Debug methods (remove in production)
  void printSessionEvents() {
    DebugLogger.debug('Session Events: $_sessionEvents');
  }

  Map<String, dynamic> get debugInfo => {
    'session_id': _sessionId,
    'events_count': _sessionEvents.length,
    'session_duration_ms': _getSessionDuration(),
    'is_authenticated': _authController.isAuthenticated,
  };
}