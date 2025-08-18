import 'package:get/get.dart';
import '../controllers/likes_controller.dart';
import '../../../core/data/repositories/properties_repository.dart';
import '../../../core/data/repositories/swipes_repository.dart';

class LikesBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories (ApiService is already registered in InitialBinding)
    Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    Get.lazyPut<SwipesRepository>(() => SwipesRepository(), fenix: true);
    
    // Screen controller
    Get.lazyPut<LikesController>(() => LikesController());
  }
}