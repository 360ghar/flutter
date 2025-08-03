import 'package:get/get.dart';
import '../../../controllers/swipe_controller.dart';
import '../../../utils/controller_helper.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PropertyController is available (SwipeController depends on it)
    ControllerHelper.ensurePropertyController();
    
    Get.lazyPut<SwipeController>(
      () => SwipeController(),
    );
  }
} 