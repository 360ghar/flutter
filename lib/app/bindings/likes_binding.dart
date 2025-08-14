import 'package:get/get.dart';
import '../controllers/likes_controller.dart';
import '../data/providers/api_client.dart';
import '../data/repositories/properties_repository.dart';
import '../data/repositories/swipes_repository.dart';

class LikesBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
    
    // Repositories
    Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    Get.lazyPut<SwipesRepository>(() => SwipesRepository(), fenix: true);
    
    // Screen controller
    Get.lazyPut<LikesController>(() => LikesController());
  }
}