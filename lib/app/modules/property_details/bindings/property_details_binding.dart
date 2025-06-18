import 'package:get/get.dart';
import '../../../controllers/property_controller.dart';
import '../../../controllers/visits_controller.dart';

class PropertyDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // No need to re-create PropertyController, just ensure it's available
    Get.find<PropertyController>();
    Get.lazyPut<VisitsController>(() => VisitsController());
  }
} 