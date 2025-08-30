import 'package:get/get.dart';
import '../controllers/likes_controller.dart';

class LikesBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories and core services are registered in DashboardBinding

    // Screen controller
    Get.lazyPut<LikesController>(() => LikesController());
  }
}
