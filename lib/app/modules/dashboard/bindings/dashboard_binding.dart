import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../explore/bindings/explore_binding.dart';
import '../../../bindings/discover_binding.dart';
import '../../../bindings/likes_binding.dart';
import '../../visits/bindings/visits_binding.dart';
import '../../../bindings/filters_binding.dart';

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
    FiltersBinding().dependencies();
  }
}