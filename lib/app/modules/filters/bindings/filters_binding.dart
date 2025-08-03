import 'package:get/get.dart';
import '../controllers/filters_controller.dart';
import '../../../utils/controller_helper.dart';

class FiltersBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PropertyController is available (PropertyFilterWidget uses it)
    ControllerHelper.ensurePropertyController();
    
    Get.lazyPut<FiltersController>(() => FiltersController());
  }
} 