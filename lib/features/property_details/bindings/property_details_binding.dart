import 'package:get/get.dart';
import '../../visits/controllers/visits_controller.dart';
import '../../likes/controllers/likes_controller.dart';
import '../../../core/data/repositories/properties_repository.dart';

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
