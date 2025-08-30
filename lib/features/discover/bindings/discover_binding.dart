import 'package:get/get.dart';
import '../controllers/discover_controller.dart';

class DiscoverBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories and core services are registered in DashboardBinding

    // Screen controller: eagerly initialize to avoid missing instance in GetView
    Get.put<DiscoverController>(DiscoverController());
  }
}
