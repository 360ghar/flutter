import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';

import '../../../../widgets/navigation/bottom_nav_bar.dart';
import '../../profile/views/profile_view.dart';
import '../../explore/views/explore_view.dart';
import '../../discover/views/discover_view.dart';
import '../../likes/views/likes_view.dart';
import '../../visits/views/visits_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: [
          ProfileView(),      // 0 - Profile
          ExploreView(),      // 1 - Explore (Map)
          DiscoverView(),         // 2 - Discover (Swipe)
          LikesView(),   // 3 - Likes
          const VisitsView(), // 4 - Visits
        ],
      )),
      bottomNavigationBar: Obx(() => CustomBottomNavigationBar(
        currentIndex: controller.currentIndex.value,
        onTap: controller.changeTab,
      )),
    );
  }
}