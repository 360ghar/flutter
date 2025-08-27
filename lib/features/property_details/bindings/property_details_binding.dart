import 'package:get/get.dart';
import '../../visits/controllers/visits_controller.dart';
import '../controllers/property_controller.dart';
import '../../../core/data/repositories/properties_repository.dart';

class PropertyDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // Register PropertiesRepository if not already registered
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
    }
    
    // Register PropertyController
    Get.lazyPut<PropertyController>(() => PropertyController(), fenix: true);
    
    Get.lazyPut<VisitsController>(() => VisitsController());
  }
} 
