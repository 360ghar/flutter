import 'package:get/get.dart';
import '../../../controllers/explore_controller.dart';
import '../../filters/controllers/filters_controller.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    // PropertyController is already registered in InitialBinding.
    // ExploreController will find it using Get.find().

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