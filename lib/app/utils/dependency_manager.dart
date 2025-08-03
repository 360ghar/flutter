import 'package:get/get.dart';
import '../data/providers/api_service.dart';
import '../data/providers/api_provider.dart';

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
      // List of controllers that should be disposed when not needed
      final controllersToCleanup = [
        'PropertyController',
        'UserController', 
        'SwipeController',
        'VisitsController',
        'LocalizationController',
      ];

      for (String controllerName in controllersToCleanup) {
        try {
          if (Get.isRegistered(tag: controllerName)) {
            Get.delete(tag: controllerName);
            print('✅ Cleaned up $controllerName');
          }
        } catch (e) {
          print('⚠️ Failed to cleanup $controllerName: $e');
        }
      }
    } catch (e) {
      print('❌ Error during dependency cleanup: $e');
    }
  }

  /// Force cleanup of all dependencies (use with caution)
  static void forceCleanupAll() {
    try {
      Get.reset();
      _initializedServices.clear();
      print('🧹 All dependencies forcefully cleaned up');
    } catch (e) {
      print('❌ Error during force cleanup: $e');
    }
  }

  /// Check if critical services are available
  static bool areCriticalServicesAvailable() {
    try {
      return Get.isRegistered<ApiService>() && 
             (Get.isRegistered<IApiProvider>());
    } catch (e) {
      print('❌ Error checking critical services: $e');
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
    } catch (e) {
      print('❌ Error finding dependency ${T.toString()}: $e');
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
    } catch (e) {
      print('❌ Error initializing dependency ${T.toString()}: $e');
      return null;
    }
  }
} 