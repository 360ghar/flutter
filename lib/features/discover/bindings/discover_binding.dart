import 'package:get/get.dart';
import '../controllers/discover_controller.dart';
import '../../../core/data/repositories/properties_repository.dart';
import '../../../core/data/repositories/swipes_repository.dart';

class DiscoverBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories (ApiService is already registered in InitialBinding)
    Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    Get.lazyPut<SwipesRepository>(() => SwipesRepository(), fenix: true);
    
    // Shared controllers (LocationController and FilterService already registered in InitialBinding)
    
    // Screen controller
    Get.lazyPut<DiscoverController>(() => DiscoverController());
  }
}