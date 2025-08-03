import 'package:get/get.dart';
import '../../../controllers/explore_controller.dart';
import '../../../utils/controller_helper.dart';
import '../../filters/controllers/filters_controller.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PropertyController is available (ExploreController depends on it)
    ControllerHelper.ensurePropertyController();

    // Create FiltersController if not already available
    if (!Get.isRegistered<FiltersController>()) {
      Get.lazyPut<FiltersController>(
        () => FiltersController(),
        fenix: true,
      );
    }
    
    // Create ExploreController after dependencies
    Get.lazyPut<ExploreController>(
      () => ExploreController(),
    );
  }
} 