import 'package:get/get.dart';
import '../../features/property_details/controllers/property_controller.dart';
import '../controllers/user_controller.dart';
import '../data/repositories/property_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/providers/api_provider.dart';
import 'debug_logger.dart';

class ControllerHelper {
  /// Ensures PropertyController is registered with all its dependencies
  static void ensurePropertyController() {
    try {
      // Ensure IApiProvider is available (should be registered in InitialBinding)
      if (!Get.isRegistered<IApiProvider>()) {
        DebugLogger.warning('⚠️ IApiProvider not registered, PropertyController registration may fail');
        return;
      }
      
      // Ensure PropertyRepository is available
      if (!Get.isRegistered<PropertyRepository>()) {
        Get.lazyPut<PropertyRepository>(
          () => PropertyRepository(Get.find<IApiProvider>()),
          fenix: true, // Allow recreation if needed
        );
        DebugLogger.info('✅ PropertyRepository registered via ControllerHelper');
      }
      
      // Ensure PropertyController is available
      if (!Get.isRegistered<PropertyController>()) {
        Get.lazyPut<PropertyController>(
          () => PropertyController(Get.find<PropertyRepository>()),
          fenix: true, // Allow recreation if needed
        );
        DebugLogger.info('✅ PropertyController registered via ControllerHelper');
      }
    } catch (e) {
      DebugLogger.error('💥 Error in ensurePropertyController: $e');
      rethrow;
    }
  }
  
  /// Ensures UserController is registered with all its dependencies
  static void ensureUserController() {
    try {
      // Ensure IApiProvider is available (should be registered in InitialBinding)
      if (!Get.isRegistered<IApiProvider>()) {
        DebugLogger.warning('⚠️ IApiProvider not registered, UserController registration may fail');
        return;
      }
      
      // Ensure UserRepository is available
      if (!Get.isRegistered<UserRepository>()) {
        Get.lazyPut<UserRepository>(
          () => UserRepository(Get.find<IApiProvider>()),
          fenix: true, // Allow recreation if needed
        );
        DebugLogger.info('✅ UserRepository registered via ControllerHelper');
      }
      
      // Ensure UserController is available
      if (!Get.isRegistered<UserController>()) {
        Get.lazyPut<UserController>(
          () => UserController(),
          fenix: true, // Allow recreation if needed
        );
        DebugLogger.info('✅ UserController registered via ControllerHelper');
      }
    } catch (e) {
      DebugLogger.error('💥 Error in ensureUserController: $e');
      rethrow;
    }
  }
  
  /// Check if all required dependencies are available for PropertyController
  static bool get canCreatePropertyController {
    return Get.isRegistered<IApiProvider>();
  }
  
  /// Check if all required dependencies are available for UserController
  static bool get canCreateUserController {
    return Get.isRegistered<IApiProvider>();
  }
}