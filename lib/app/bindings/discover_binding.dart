import 'package:get/get.dart';
import '../controllers/discover_controller.dart';
import '../controllers/filters_controller.dart';
import '../controllers/location_controller.dart';
import '../data/providers/api_client.dart';
import '../data/repositories/properties_repository.dart';
import '../data/repositories/swipes_repository.dart';

class DiscoverBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
    
    // Repositories
    Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    Get.lazyPut<SwipesRepository>(() => SwipesRepository(), fenix: true);
    
    // Shared controllers
    Get.lazyPut<LocationController>(() => LocationController(), fenix: true);
    Get.lazyPut<FiltersController>(() => FiltersController(), fenix: true);
    
    // Screen controller
    Get.lazyPut<DiscoverController>(() => DiscoverController());
  }
}