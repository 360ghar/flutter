import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widgets/navigation/bottom_nav_bar.dart';
import '../../profile/views/profile_view.dart';
import '../../explore/views/explore_view.dart';
import '../../home/views/home_view.dart';
import '../../favourites/views/favourites_view.dart';
import '../../visits/views/visits_view.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.tabIndex.value,
        children: const [
          ProfileView(),
          ExploreView(),
          HomeView(),
          FavouritesView(),
          VisitsView(),
        ],
      )),
      bottomNavigationBar: Obx(() => CustomBottomNavigationBar(
        currentIndex: controller.tabIndex.value,
        onTap: controller.changeTabIndex,
      )),
    );
  }
}