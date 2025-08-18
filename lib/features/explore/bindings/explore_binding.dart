import 'package:get/get.dart';
import '../controllers/explore_controller.dart';
import '../../../core/data/repositories/properties_repository.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories (ApiService already registered in InitialBinding)
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    }
    
    // LocationController and FilterService are already registered globally in InitialBinding
    
    // Screen controller
    Get.lazyPut<ExploreController>(() => ExploreController());
  }
}