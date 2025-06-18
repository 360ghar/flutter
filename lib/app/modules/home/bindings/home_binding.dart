import 'package:get/get.dart';
import '../../../controllers/property_controller.dart';
import '../../../controllers/swipe_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyController>(
      () => PropertyController(Get.find()),
    );
    Get.lazyPut<SwipeController>(
      () => SwipeController(),
    );
  }
} 