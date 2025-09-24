import 'package:get/get.dart';
import 'package:ghar360/features/auth/data/auth_repository.dart';
import '../data/providers/api_service.dart';
import '../data/repositories/app_update_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../controllers/auth_controller.dart';
import '../controllers/app_update_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/localization_controller.dart';
import '../controllers/theme_controller.dart';
import '../utils/debug_logger.dart';
import '../utils/offline_queue_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    DebugLogger.info('🔧 InitialBinding: Starting dependency injection...');

    // Register API Service first
    Get.put<ApiService>(ApiService());
    DebugLogger.success('✅ ApiService registered');

    // NEW: Register AuthRepository
    Get.put<AuthRepository>(AuthRepository());
    DebugLogger.success('✅ AuthRepository registered');

    Get.put<AppUpdateRepository>(AppUpdateRepository(), permanent: true);
    DebugLogger.success('✅ AppUpdateRepository registered');

    // Register ProfileRepository for AuthController
    Get.put<ProfileRepository>(ProfileRepository());
    DebugLogger.success('✅ ProfileRepository registered');

    // Test API connection
    _initializeApiService();

    // Register Core Controllers in proper order
    _initializeCoreControllers();

    // Initialize Offline Queue Service (persistent, background retry)
    if (!Get.isRegistered<OfflineQueueService>()) {
      final service = Get.put<OfflineQueueService>(OfflineQueueService(), permanent: true);
      service.start();
      DebugLogger.success('✅ OfflineQueueService started');
    }

    // Note: Repositories and feature controllers will be initialized
    // in route-specific bindings to prevent unauthorized API calls

    DebugLogger.success('✅ InitialBinding: Core dependencies registered successfully');
  }

  void _initializeApiService() {
    try {
      // Test connection asynchronously without blocking initialization
      Future.delayed(const Duration(milliseconds: 500), () {
        _testBackendConnection();
      });
    } catch (e) {
      DebugLogger.error('💥 Failed to initialize ApiService: $e');
      throw Exception('Critical error: Cannot initialize API service');
    }
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

      Get.put<AppUpdateController>(AppUpdateController(), permanent: true);
      DebugLogger.success('✅ AppUpdateController registered');

      // Note: PageStateService and repositories (PropertiesRepository, SwipesRepository)
      // are now registered in DashboardBinding to prevent unauthorized API calls
      // and ensure proper lifecycle management
    } catch (e) {
      DebugLogger.error('💥 Error initializing core controllers: $e');
      rethrow;
    }
  }

  void _testBackendConnection() async {
    try {
      if (Get.isRegistered<ApiService>()) {
        final apiService = Get.find<ApiService>();
        final isConnected = await apiService.testConnection();
        if (isConnected) {
          DebugLogger.success('🎉 Backend connection test successful!');
        } else {
          DebugLogger.warning('❌ Backend connection test failed');
          DebugLogger.info('💡 Make sure your backend server is running');
        }
      }
    } catch (e) {
      DebugLogger.error('💥 Backend connection test error: $e');
    }
  }
}
