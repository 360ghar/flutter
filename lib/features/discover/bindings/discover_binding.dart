import 'package:get/get.dart';

import 'package:ghar360/features/discover/controllers/discover_controller.dart';

class DiscoverBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories and core services are registered in DashboardBinding

    // Screen controller
    Get.lazyPut<DiscoverController>(() => DiscoverController());
  }
}
