import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';

import '../../../widgets/navigation/bottom_nav_bar.dart';
import '../../profile/views/profile_view.dart';
import '../../explore/views/explore_view.dart';
import '../../discover/views/discover_view.dart';
import '../../likes/views/likes_view.dart';
import '../../visits/views/visits_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Use PageController for lazy loading
    final PageController pageController = PageController(
      initialPage: controller.currentIndex.value,
    );

    // Sync page changes with controller
    ever(controller.currentIndex, (index) {
      if (pageController.hasClients) {
        pageController.jumpToPage(index);
      }
    });

    return Scaffold(
      body: PageView(
        controller: pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe navigation
        onPageChanged: (index) {
          // Update index when page changes (shouldn't happen with disabled physics)
          controller.currentIndex.value = index;
        },
        children: [
          ProfileView(), // 0 - Profile
          ExploreView(), // 1 - Explore (Map)
          DiscoverView(), // 2 - Discover (Swipe)
          LikesView(), // 3 - Likes
          const VisitsView(), // 4 - Visits
        ],
      ),
      bottomNavigationBar: Obx(
        () => CustomBottomNavigationBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }
}
