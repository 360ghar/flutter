import 'package:get/get.dart';

import 'package:ghar360/core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/repositories/profile_repository.dart';
import 'package:ghar360/core/data/repositories/properties_repository.dart';
import 'package:ghar360/core/data/repositories/swipes_repository.dart';
import 'package:ghar360/features/dashboard/controllers/dashboard_controller.dart';
import 'package:ghar360/features/discover/bindings/discover_binding.dart';
import 'package:ghar360/features/explore/bindings/explore_binding.dart';
import 'package:ghar360/features/likes/bindings/likes_binding.dart';
import 'package:ghar360/features/profile/bindings/profile_binding.dart';
import 'package:ghar360/features/visits/bindings/visits_binding.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Register core repositories needed by features
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
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

    // Initialize all tab controllers
    ProfileBinding().dependencies();
    ExploreBinding().dependencies();
    DiscoverBinding().dependencies();
    LikesBinding().dependencies();
    VisitsBinding().dependencies();
    // PageStateService and repositories are now available for all features
  }
}
