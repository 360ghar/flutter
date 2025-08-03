import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../explore/bindings/explore_binding.dart';
import '../../home/bindings/home_binding.dart';
import '../../favourites/bindings/favourites_binding.dart';
import '../../visits/bindings/visits_binding.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    
    ProfileBinding().dependencies();
    ExploreBinding().dependencies();
    HomeBinding().dependencies();
    FavouritesBinding().dependencies();
    VisitsBinding().dependencies();
  }
}