import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/widgets/navigation/bottom_nav_bar.dart';
import 'package:ghar360/features/assistant/presentation/views/assistant_view.dart';
import 'package:ghar360/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:ghar360/features/discover/presentation/views/discover_view.dart';
import 'package:ghar360/features/explore/presentation/views/explore_view.dart';
import 'package:ghar360/features/likes/presentation/views/likes_view.dart';
import 'package:ghar360/features/profile/presentation/views/profile_view.dart';
import 'package:ghar360/features/visits/presentation/views/visits_view.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('qa.dashboard.screen'),
      body: ObxValue<RxInt>(
        (idx) => Semantics(
          label: 'qa.dashboard.indexed_stack',
          identifier: 'qa.dashboard.indexed_stack',
          child: IndexedStack(
            index: idx.value,
            children: const [
              ProfileView(), // 0 - Profile
              ExploreView(), // 1 - Explore (Map)
              DiscoverView(), // 2 - Discover (Swipe)
              LikesView(), // 3 - Likes
              VisitsView(), // 4 - Visits
              AssistantView(), // 5 - AI Assistant
            ],
          ),
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
