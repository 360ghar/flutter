import 'package:get/get.dart';
import '../controllers/discover_controller.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/data/providers/api_client.dart';
import '../../../core/data/repositories/properties_repository.dart';
import '../../../core/data/repositories/swipes_repository.dart';

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
    // FilterService is now registered globally in InitialBinding
    
    // Screen controller
    Get.lazyPut<DiscoverController>(() => DiscoverController());
  }
}