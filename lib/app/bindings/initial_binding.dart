import 'package:get/get.dart';
import '../data/providers/api_provider.dart';
import '../data/providers/api_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/location_controller.dart';
import '../controllers/localization_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/analytics_controller.dart';
import '../controllers/filter_controller.dart';
import '../utils/debug_logger.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    DebugLogger.info('🔧 InitialBinding: Starting dependency injection...');
    
    // Register API Service first
    Get.put<ApiService>(ApiService(), permanent: true);
    DebugLogger.success('✅ ApiService registered');

    // Register API Providers with better error handling
    _initializeApiProviders();

    // Register Core Controllers in proper order
    _initializeCoreControllers();

    // Note: Repositories and feature controllers will be initialized
    // in route-specific bindings to prevent unauthorized API calls

    DebugLogger.success('✅ InitialBinding: Core dependencies registered successfully');
  }

  void _initializeApiProviders() {
    try {
      final apiProvider = RealApiProvider();
      Get.put<IApiProvider>(apiProvider, permanent: true);
      DebugLogger.success('✅ RealApiProvider registered for backend integration');
      
      // Test connection asynchronously without blocking initialization
      Future.delayed(const Duration(milliseconds: 500), () {
        _testBackendConnection();
      });
    } catch (e) {
      DebugLogger.error('💥 Failed to initialize RealApiProvider: $e');
      throw Exception('Critical error: Cannot initialize API provider');
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
      
      Get.put<AnalyticsController>(AnalyticsController(), permanent: true);
      DebugLogger.success('✅ AnalyticsController registered');
      
      Get.put<PropertyFilterController>(PropertyFilterController(), permanent: true);
      DebugLogger.success('✅ PropertyFilterController registered');
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