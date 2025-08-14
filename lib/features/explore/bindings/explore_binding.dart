import 'package:get/get.dart';
import '../controllers/explore_controller.dart';
import '../../filters/controllers/filters_controller.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/data/providers/api_client.dart';
import '../../../core/data/repositories/properties_repository.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    // Core services (ensure they exist)
    if (!Get.isRegistered<ApiClient>()) {
      Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
    }
    
    // Repositories
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    }
    
    // Shared controllers (only register if not already registered)
    if (!Get.isRegistered<LocationController>()) {
      Get.lazyPut<LocationController>(() => LocationController(), fenix: true);
    }
    if (!Get.isRegistered<FiltersController>()) {
      Get.lazyPut<FiltersController>(() => FiltersController(), fenix: true);
    }
    
    // Screen controller
    Get.lazyPut<ExploreController>(() => ExploreController());
  }
}