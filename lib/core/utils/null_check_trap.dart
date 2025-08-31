import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/page_state_service.dart';
import 'debug_logger.dart';

class NullCheckTrap {
  static bool _fired = false;
  static bool _stringFired = false;

  static bool get hasFired => _fired;

  static void _logCommonContext({String source = 'unknown'}) {
    try {
      DebugLogger.error('🚨 [NULL_CHECK_TRAP] SOURCE: $source');
      DebugLogger.error(
        '🚨 [NULL_CHECK_TRAP] Current route: ${Get.currentRoute}',
      );

      if (Get.isRegistered<PageStateService>()) {
        final svc = Get.find<PageStateService>();
        final explore = svc.exploreState.value;
        final discover = svc.discoverState.value;
        final likes = svc.likesState.value;

        DebugLogger.error(
          '🚨 [NULL_CHECK_TRAP] Current page: ${svc.currentPageType.value}',
        );

        String locSummary(state) => state.selectedLocation == null
            ? 'no-location'
            : '(${state.selectedLocation!.latitude}, ${state.selectedLocation!.longitude})';

        DebugLogger.error(
          '🚨 [NULL_CHECK_TRAP] Explore => props:${explore.properties.length}, loading:${explore.isLoading}, error:${explore.error != null}, loc:${locSummary(explore)}',
        );
        DebugLogger.error(
          '🚨 [NULL_CHECK_TRAP] Discover => props:${discover.properties.length}, loading:${discover.isLoading}, error:${discover.error != null}, loc:${locSummary(discover)}',
        );
        DebugLogger.error(
          '🚨 [NULL_CHECK_TRAP] Likes => props:${likes.properties.length}, loading:${likes.isLoading}, error:${likes.error != null}, loc:${locSummary(likes)}',
        );
      } else {
        DebugLogger.error(
          '🚨 [NULL_CHECK_TRAP] PageStateService not registered yet',
        );
      }
    } catch (e) {
      // Avoid throwing from the trap itself
      DebugLogger.warning('⚠️ [NULL_CHECK_TRAP] Context logging failed: $e');
    }
  }

  static void capture(
    dynamic error,
    StackTrace stack, {
    String source = 'zone',
  }) {
    if (_fired) return;
    final text = error?.toString() ?? '';
    if (!text.contains('Null check operator used on a null value')) return;
    _fired = true;

    DebugLogger.error(
      '🔥 [NULL_CHECK_TRAP] FIRST NULL CHECK OPERATOR EXCEPTION CAPTURED',
    );
    DebugLogger.error('🔥 [NULL_CHECK_TRAP] Error type: ${error.runtimeType}');
    DebugLogger.error('🔥 [NULL_CHECK_TRAP] Error: $error');
    _logCommonContext(source: source);
    DebugLogger.error('🔥 [NULL_CHECK_TRAP] STACK TRACE (full):');
    DebugLogger.error(stack.toString());
  }

  static void captureFlutterError(FlutterErrorDetails details) {
    if (_fired) return;
    final text = details.exception.toString();
    if (!text.contains('Null check operator used on a null value')) return;
    _fired = true;

    DebugLogger.error(
      '🔥 [NULL_CHECK_TRAP] FIRST NULL CHECK OPERATOR (FlutterError)',
    );
    DebugLogger.error('🔥 [NULL_CHECK_TRAP] Library: ${details.library}');
    DebugLogger.error('🔥 [NULL_CHECK_TRAP] Context: ${details.context}');
    DebugLogger.error(
      '🔥 [NULL_CHECK_TRAP] Exception: ${details.exception.runtimeType} | ${details.exception}',
    );
    _logCommonContext(source: 'flutter_error');
    DebugLogger.error('🔥 [NULL_CHECK_TRAP] STACK TRACE (FlutterError):');
    DebugLogger.error(details.stack?.toString() ?? 'no stack');
  }

  // Capture one-time occurrences where the null-check message is only a String,
  // e.g., when UI passes error text into an error mapper. This logs the current
  // stack to pinpoint call sites even without a thrown exception.
  static void captureStringOccurrence(
    String message, {
    String source = 'mapper',
  }) {
    if (_stringFired) return;
    if (!message.contains('Null check operator used on a null value')) return;
    _stringFired = true;

    DebugLogger.error(
      '🔥 [NULL_CHECK_TRAP] STRING-ONLY NULL CHECK MESSAGE CAPTURED',
    );
    DebugLogger.error('🔥 [NULL_CHECK_TRAP] Message: $message');
    _logCommonContext(source: source);
    final stack = StackTrace.current;
    DebugLogger.error('🔥 [NULL_CHECK_TRAP] STACK TRACE (call site):');
    DebugLogger.error(stack.toString());
  }
}
