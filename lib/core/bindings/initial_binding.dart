import 'package:flutter/widgets.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/app_update_controller.dart';
import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/controllers/localization_controller.dart';
import 'package:ghar360/core/controllers/location_controller.dart';
import 'package:ghar360/core/controllers/offline_queue_service.dart';
import 'package:ghar360/core/controllers/theme_controller.dart';
import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/network/auth_header_provider.dart';
import 'package:ghar360/core/network/etag_cache.dart';
import 'package:ghar360/core/services/auth_navigation_service.dart';
import 'package:ghar360/core/services/deep_link_service.dart';
import 'package:ghar360/core/services/google_places_service.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/auth/data/auth_repository.dart';
import 'package:ghar360/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:ghar360/features/profile/data/profile_repository.dart';
import 'package:ghar360/features/profile/data/static_page_repository.dart';
import 'package:ghar360/features/properties/data/datasources/properties_remote_datasource.dart';
import 'package:ghar360/features/splash/data/app_update_repository.dart';
import 'package:ghar360/features/swipes/data/datasources/swipes_remote_datasource.dart';
import 'package:ghar360/features/visits/data/datasources/visits_remote_datasource.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    DebugLogger.info('🔧 InitialBinding: Starting dependency injection...');

    // ── Network layer ──
    Get.put<AuthHeaderProvider>(AuthHeaderProvider(), permanent: true);
    Get.put<ETagCache>(ETagCache(), permanent: true);
    Get.put<ApiClient>(
      ApiClient(authProvider: Get.find<AuthHeaderProvider>(), etagCache: Get.find<ETagCache>()),
      permanent: true,
    );

    // ── Datasources ──
    final apiClient = Get.find<ApiClient>();
    Get.put<PropertiesRemoteDatasource>(PropertiesRemoteDatasource(apiClient), permanent: true);
    Get.put<VisitsRemoteDatasource>(VisitsRemoteDatasource(apiClient), permanent: true);
    Get.put<SwipesRemoteDatasource>(SwipesRemoteDatasource(apiClient), permanent: true);
    Get.put<NotificationsRemoteDatasource>(
      NotificationsRemoteDatasource(apiClient),
      permanent: true,
    );

    // ── Repositories ──
    // All repositories marked as permanent to prevent garbage collection
    Get.put<AuthRepository>(AuthRepository(), permanent: true);
    Get.put<AppUpdateRepository>(AppUpdateRepository(), permanent: true);
    Get.put<ProfileRepository>(ProfileRepository(), permanent: true);
    Get.put<StaticPageRepository>(StaticPageRepository(), permanent: true);

    // Test API connection
    _initializeApiClient();

    // ── Services ──
    Get.put<GooglePlacesService>(GooglePlacesService(), permanent: true);

    // ── Core controllers ──
    _initializeCoreControllers();

    // Initialize offline queue early (connectivity listener + storage)
    try {
      Get.put<OfflineQueueService>(OfflineQueueService(), permanent: true).init();
      DebugLogger.success('✅ OfflineQueueService registered');
    } catch (e) {
      DebugLogger.error('💥 Failed to initialize OfflineQueueService: $e');
    }

    // ── Services (registered last — may depend on controllers) ──
    Get.put<DeepLinkService>(DeepLinkService());

    DebugLogger.success('✅ InitialBinding: All dependencies registered successfully');
  }

  void _initializeApiClient() {
    try {
      // Defer backend connection test until after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _testBackendConnection();
      });
    } catch (e) {
      DebugLogger.error('💥 Failed to initialize ApiClient: $e');
      throw Exception('Critical error: Cannot initialize API client');
    }
  }

  void _initializeCoreControllers() {
    // Register only essential controllers that don't make API calls on init
    try {
      Get.put<AuthController>(AuthController(), permanent: true);
      Get.put<AuthNavigationService>(AuthNavigationService(), permanent: true);
      Get.put<LocationController>(LocationController(), permanent: true);
      Get.put<LocalizationController>(LocalizationController(), permanent: true);
      Get.put<ThemeController>(ThemeController(), permanent: true);
      Get.put<AppUpdateController>(AppUpdateController(), permanent: true);
      DebugLogger.success('Core controllers registered');

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
      if (!Get.isRegistered<ApiClient>()) return;

      final apiClient = Get.find<ApiClient>();
      try {
        await apiClient.get(
          '${apiClient.baseUrl}/health',
          useCache: false,
          requireAuth: false,
          notifyUnauthorized: false,
        );
        DebugLogger.success('🎉 Backend connection test successful!');
      } catch (_) {
        await apiClient.get(
          '${apiClient.baseUrl}/',
          useCache: false,
          requireAuth: false,
          notifyUnauthorized: false,
        );
        DebugLogger.success('🎉 Backend reachable via root endpoint');
      }
    } catch (e) {
      DebugLogger.error('💥 Backend connection test error: $e');
    }
  }
}
