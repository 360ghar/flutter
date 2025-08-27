import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../explore/bindings/explore_binding.dart';
import '../../discover/bindings/discover_binding.dart';
import '../../likes/bindings/likes_binding.dart';
import '../../visits/bindings/visits_binding.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    
    // Initialize all tab controllers
    ProfileBinding().dependencies();
    ExploreBinding().dependencies();
    DiscoverBinding().dependencies();
    LikesBinding().dependencies();
    VisitsBinding().dependencies();
    // Filters binding removed; FilterService is globally available
  }
}
