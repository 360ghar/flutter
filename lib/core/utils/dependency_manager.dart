import 'package:get/get.dart';
import '../data/providers/api_service.dart';
import 'debug_logger.dart';
import '../../features/visits/controllers/visits_controller.dart';
import '../controllers/localization_controller.dart';

class DependencyManager {
  static final Map<String, bool> _initializedServices = {};

  /// Check if a service is already initialized
  static bool isServiceInitialized(String serviceName) {
    return _initializedServices[serviceName] ?? false;
  }

  /// Mark a service as initialized
  static void markServiceInitialized(String serviceName) {
    _initializedServices[serviceName] = true;
  }

  /// Clean up all non-permanent dependencies
  static void cleanupDependencies() {
    try {
      // Clean up controllers by type instead of tag since they are registered without tags
      _cleanupController<VisitsController>('VisitsController');
      _cleanupController<LocalizationController>('LocalizationController');
    } catch (e, stackTrace) {
      DebugLogger.error('Error during dependency cleanup', e, stackTrace);
    }
  }

  /// Helper method to clean up a specific controller type
  static void _cleanupController<T>(String controllerName) {
    try {
      if (Get.isRegistered<T>()) {
        Get.delete<T>();
        DebugLogger.info('Cleaned up $controllerName');
      }
    } catch (e) {
      DebugLogger.warning('Failed to cleanup $controllerName', e);
    }
  }

  /// Force cleanup of all dependencies (use with caution)
  static void forceCleanupAll() {
    try {
      Get.reset();
      _initializedServices.clear();
      DebugLogger.info('All dependencies forcefully cleaned up');
    } catch (e, stackTrace) {
      DebugLogger.error('Error during force cleanup', e, stackTrace);
    }
  }

  /// Check if critical services are available
  static bool areCriticalServicesAvailable() {
    try {
      return Get.isRegistered<ApiService>();
    } catch (e, stackTrace) {
      DebugLogger.error('Error checking critical services', e, stackTrace);
      return false;
    }
  }

  /// Safely get a dependency with error handling
  static T? safeFind<T>() {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
      return null;
    } catch (e, stackTrace) {
      DebugLogger.error('Error finding dependency ${T.toString()}', e, stackTrace);
      return null;
    }
  }

  /// Initialize a dependency safely
  static T? safeInit<T>(T Function() creator, {bool permanent = false}) {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
      return Get.put<T>(creator(), permanent: permanent);
    } catch (e, stackTrace) {
      DebugLogger.error('Error initializing dependency ${T.toString()}', e, stackTrace);
      return null;
    }
  }
}
