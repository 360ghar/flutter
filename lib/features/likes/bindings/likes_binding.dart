import 'package:get/get.dart';

import 'package:ghar360/features/likes/controllers/likes_controller.dart';

class LikesBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories and core services are registered in DashboardBinding

    // Screen controller
    Get.lazyPut<LikesController>(() => LikesController());
  }
}
