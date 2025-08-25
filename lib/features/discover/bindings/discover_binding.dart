import 'package:get/get.dart';
import '../controllers/discover_controller.dart';

class DiscoverBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories and core services are registered in InitialBinding
    // Shared controllers (LocationController and FilterService already registered in InitialBinding)

    // Screen controller
    Get.lazyPut<DiscoverController>(() => DiscoverController());
  }
}
