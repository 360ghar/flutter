import 'package:get/get.dart';

import 'package:ghar360/core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/repositories/properties_repository.dart';
import 'package:ghar360/core/data/repositories/swipes_repository.dart';
import 'package:ghar360/features/likes/controllers/likes_controller.dart';
import 'package:ghar360/features/visits/controllers/visits_controller.dart';

class PropertyDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // Register PropertiesRepository if not already registered
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    }

    // Register SwipesRepository if not already registered (required by PageStateService/LikesController)
    if (!Get.isRegistered<SwipesRepository>()) {
      Get.lazyPut<SwipesRepository>(() => SwipesRepository(), fenix: true);
    }

    // Register PageStateService if not already registered (required by LikesController)
    if (!Get.isRegistered<PageStateService>()) {
      Get.lazyPut<PageStateService>(() => PageStateService(), fenix: true);
    }

    // Register LikesController for favorite management
    if (!Get.isRegistered<LikesController>()) {
      Get.lazyPut<LikesController>(() => LikesController(), fenix: true);
    }

    // Register VisitsController if not already registered
    if (!Get.isRegistered<VisitsController>()) {
      Get.lazyPut<VisitsController>(() => VisitsController(), fenix: true);
    }
  }
}
