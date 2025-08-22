import 'package:get/get.dart';
import '../data/providers/api_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/localization_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/filter_service.dart';
import '../utils/debug_logger.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    DebugLogger.info('🔧 InitialBinding: Starting dependency injection...');

    // Register API Service first
    Get.put<ApiService>(ApiService(), permanent: true);
    DebugLogger.success('✅ ApiService registered');

    // Register Core Controllers in proper order
    _initializeCoreControllers();

    // Note: Repositories and feature controllers will be initialized
    // in route-specific bindings to prevent unauthorized API calls

    DebugLogger.success('✅ InitialBinding: Core dependencies registered successfully');
  }

  void _initializeCoreControllers() {
    // Register only essential controllers that don't make API calls on init
    try {
      Get.put<AuthController>(AuthController(), permanent: true);
      DebugLogger.success('✅ AuthController registered');

      Get.put<LocationController>(LocationController(), permanent: true);
      DebugLogger.success('✅ LocationController registered');

      Get.put<LocalizationController>(LocalizationController(), permanent: true);
      DebugLogger.success('✅ LocalizationController registered');

      Get.put<ThemeController>(ThemeController(), permanent: true);
      DebugLogger.success('✅ ThemeController registered');

      Get.put<FilterService>(FilterService(), permanent: true);
      DebugLogger.success('✅ FilterService registered');
    } catch (e) {
      DebugLogger.error('💥 Error initializing core controllers: $e');
      rethrow;
    }
  }
} 