import 'package:get/get.dart';

import 'package:ghar360/core/data/repositories/properties_repository_adapter.dart';
import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/network/auth_header_provider.dart';
import 'package:ghar360/core/network/etag_cache.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ghar360/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:ghar360/features/properties/data/datasources/properties_remote_datasource.dart';
import 'package:ghar360/features/properties/data/repositories/properties_repository_impl.dart';
import 'package:ghar360/features/properties/domain/usecases/get_properties_usecase.dart';
import 'package:ghar360/features/swipes/data/datasources/swipes_remote_datasource.dart';
import 'package:ghar360/features/swipes/domain/usecases/log_swipe_usecase.dart';
import 'package:ghar360/features/visits/data/datasources/visits_remote_datasource.dart';
import 'package:ghar360/features/visits/domain/usecases/get_visits_usecase.dart';
import 'package:ghar360/features/visits/domain/usecases/schedule_visit_usecase.dart';

/// Service locator for dependency injection.
/// Manages lifecycle of core network and data layer components.
class ServiceLocator {
  static bool _initialized = false;

  /// Initializes all core services.
  static void init() {
    if (_initialized) return;

    DebugLogger.info('🏗️ ServiceLocator: Initializing new architecture...');

    // Network layer
    Get.put<AuthHeaderProvider>(AuthHeaderProvider(), permanent: true);
    Get.put<ETagCache>(ETagCache(), permanent: true);
    Get.put<ApiClient>(
      ApiClient(authProvider: Get.find<AuthHeaderProvider>(), etagCache: Get.find<ETagCache>()),
      permanent: true,
    );

    // Datasources
    Get.put<PropertiesRemoteDatasource>(
      PropertiesRemoteDatasource(Get.find<ApiClient>()),
      permanent: true,
    );
    Get.put<AuthRemoteDatasource>(AuthRemoteDatasource(Get.find<ApiClient>()), permanent: true);
    Get.put<VisitsRemoteDatasource>(VisitsRemoteDatasource(Get.find<ApiClient>()), permanent: true);
    Get.put<SwipesRemoteDatasource>(SwipesRemoteDatasource(Get.find<ApiClient>()), permanent: true);
    Get.put<NotificationsRemoteDatasource>(
      NotificationsRemoteDatasource(Get.find<ApiClient>()),
      permanent: true,
    );

    // Repositories
    Get.put<PropertiesRepositoryImpl>(
      PropertiesRepositoryImpl(Get.find<PropertiesRemoteDatasource>()),
      permanent: true,
    );

    // Use cases
    Get.put<GetPropertiesUseCase>(
      GetPropertiesUseCase(Get.find<PropertiesRepositoryImpl>()),
      permanent: true,
    );
    Get.put<GetVisitsUseCase>(
      GetVisitsUseCase(Get.find<VisitsRemoteDatasource>()),
      permanent: true,
    );
    Get.put<ScheduleVisitUseCase>(
      ScheduleVisitUseCase(Get.find<VisitsRemoteDatasource>()),
      permanent: true,
    );
    Get.put<LogSwipeUseCase>(LogSwipeUseCase(Get.find<SwipesRemoteDatasource>()), permanent: true);

    // Backward compatibility adapter
    Get.put<PropertiesRepositoryAdapter>(PropertiesRepositoryAdapter(), permanent: true);
    DebugLogger.success('✅ PropertiesRepositoryAdapter registered for backward compatibility');

    _initialized = true;
    DebugLogger.success('✅ ServiceLocator: New architecture initialized successfully');
  }

  /// Clears all caches.
  static void clearCaches() {
    try {
      Get.find<ETagCache>().clear();
      Get.find<ApiClient>().clearCache();
    } catch (_) {}
  }
}
