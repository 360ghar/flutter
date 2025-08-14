import 'package:get/get.dart';
import '../../../utils/controller_helper.dart';
import '../controllers/likes_controller.dart';

class FavouritesBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PropertyController is available
    ControllerHelper.ensurePropertyController();
    if (!Get.isRegistered<LikesController>()) {
      Get.lazyPut<LikesController>(() => LikesController(), fenix: true);
    }
  }
} 