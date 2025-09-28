import 'package:get/get.dart';

import 'package:ghar360/core/data/repositories/properties_repository.dart';
import 'package:ghar360/features/likes/controllers/likes_controller.dart';
import 'package:ghar360/features/visits/controllers/visits_controller.dart';

class PropertyDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // Register PropertiesRepository if not already registered
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    }

    // Register LikesController for favorite management
    if (!Get.isRegistered<LikesController>()) {
      Get.lazyPut<LikesController>(() => LikesController(), fenix: true);
    }

    Get.lazyPut<VisitsController>(() => VisitsController());
  }
}
