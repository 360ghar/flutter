import 'package:get/get.dart';
import '../controllers/swipe_controller.dart';
import '../../../core/utils/controller_helper.dart';

class SwipeBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PropertyController is available (SwipeController depends on it)
    ControllerHelper.ensurePropertyController();
    
    Get.lazyPut<SwipeController>(
      () => SwipeController(),
    );
  }
} 