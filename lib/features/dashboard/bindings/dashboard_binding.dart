import 'package:get/get.dart';

import 'package:ghar360/core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/repositories/profile_repository.dart';
import 'package:ghar360/core/data/repositories/properties_repository.dart';
import 'package:ghar360/core/data/repositories/properties_repository_adapter.dart';
import 'package:ghar360/core/data/repositories/swipes_repository.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/dashboard/controllers/dashboard_controller.dart';
import 'package:ghar360/features/discover/bindings/discover_binding.dart';
import 'package:ghar360/features/explore/bindings/explore_binding.dart';
import 'package:ghar360/features/likes/bindings/likes_binding.dart';
import 'package:ghar360/features/profile/bindings/profile_binding.dart';
import 'package:ghar360/features/visits/bindings/visits_binding.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Use new architecture adapter for PropertiesRepository
    if (!Get.isRegistered<PropertiesRepository>()) {
      // Register adapter as PropertiesRepository for backward compatibility
      Get.lazyPut<PropertiesRepository>(() => Get.find<PropertiesRepositoryAdapter>(), fenix: true);
      DebugLogger.info('✅ Using PropertiesRepositoryAdapter (new architecture)');
    }

    if (!Get.isRegistered<SwipesRepository>()) {
      Get.lazyPut<SwipesRepository>(() => SwipesRepository(), fenix: true);
    }

    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(() => ProfileRepository(), fenix: true);
    }

    // Register PageStateService if not already registered
    if (!Get.isRegistered<PageStateService>()) {
      Get.lazyPut<PageStateService>(() => PageStateService(), fenix: true);
    }

    Get.lazyPut<DashboardController>(() => DashboardController());
    // Register feature bindings lazily; controllers instantiate on first use
    ProfileBinding().dependencies();
    ExploreBinding().dependencies();
    DiscoverBinding().dependencies();
    LikesBinding().dependencies();
    VisitsBinding().dependencies();
  }
}
