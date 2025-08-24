import 'package:get/get.dart';
import '../controllers/explore_controller.dart';
import '../../../core/data/providers/property_api_service.dart';
import '../../../core/data/providers/google_places_service.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/utils/debug_logger.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    DebugLogger.info('🔧 ExploreBinding dependencies() called.');

    // API Services
    if (!Get.isRegistered<PropertyApiService>()) {
      Get.lazyPut<PropertyApiService>(() => PropertyApiService(), fenix: true);
      DebugLogger.success('✅ PropertyApiService registered');
    } else {
      DebugLogger.info('ℹ️ PropertyApiService already registered');
    }

    if (!Get.isRegistered<GooglePlacesService>()) {
      Get.put(GooglePlacesService()); // Use put() for static service
      DebugLogger.success('✅ GooglePlacesService registered');
    } else {
      DebugLogger.info('ℹ️ GooglePlacesService already registered');
    }

    // Controllers - Check if already registered globally
    if (!Get.isRegistered<FilterService>()) {
      Get.lazyPut<FilterService>(() => FilterService(), fenix: true);
      DebugLogger.success('✅ FilterService registered');
    } else {
      DebugLogger.info('ℹ️ FilterService already registered');
    }

    if (!Get.isRegistered<LocationController>()) {
      Get.lazyPut<LocationController>(() => LocationController(), fenix: true);
      DebugLogger.success('✅ LocationController registered');
    } else {
      DebugLogger.info('ℹ️ LocationController already registered');
    }

    // Screen controller - with error handling
    try {
      if (!Get.isRegistered<ExploreController>()) {
        Get.lazyPut<ExploreController>(() => ExploreController(), fenix: true);
        DebugLogger.success('✅ ExploreController registered');
      } else {
        DebugLogger.info('ℹ️ ExploreController already registered');
      }
    } catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to register ExploreController', e, stackTrace);
      // Fallback registration
      Get.put(ExploreController());
      DebugLogger.warning('⚠️ ExploreController registered as fallback with put()');
    }

    DebugLogger.success('🎉 All Explore dependencies registered successfully');
  }
}