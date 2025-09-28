import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/widgets/navigation/bottom_nav_bar.dart';
import 'package:ghar360/features/dashboard/controllers/dashboard_controller.dart';
import 'package:ghar360/features/discover/views/discover_view.dart';
import 'package:ghar360/features/explore/views/explore_view.dart';
import 'package:ghar360/features/likes/views/likes_view.dart';
import 'package:ghar360/features/profile/views/profile_view.dart';
import 'package:ghar360/features/visits/views/visits_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ObxValue<RxInt>(
        (idx) => IndexedStack(
          index: idx.value,
          children: const [
            ProfileView(), // 0 - Profile
            ExploreView(), // 1 - Explore (Map)
            DiscoverView(), // 2 - Discover (Swipe)
            LikesView(), // 3 - Likes
            VisitsView(), // 4 - Visits
          ],
        ),
        controller.currentIndex,
      ),
      bottomNavigationBar: ObxValue<RxInt>(
        (idx) => CustomBottomNavigationBar(currentIndex: idx.value, onTap: controller.changeTab),
        controller.currentIndex,
      ),
    );
  }
}
