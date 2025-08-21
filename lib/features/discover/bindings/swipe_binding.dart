import 'package:get/get.dart';
import '../controllers/swipe_controller.dart';
import '../../property_details/controllers/property_controller.dart';
import '../../../core/data/repositories/properties_repository.dart';

class SwipeBinding extends Bindings {
  @override
  void dependencies() {
    // Register PropertiesRepository if not already registered
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    }
    
    // Register PropertyController if not already registered (SwipeController depends on it)
    if (!Get.isRegistered<PropertyController>()) {
      Get.lazyPut<PropertyController>(() => PropertyController(), fenix: true);
    }
    
    Get.lazyPut<SwipeController>(
      () => SwipeController(),
    );
  }
} 