import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/controllers/page_state_service.dart';
import '../../core/data/models/page_state_model.dart';
import '../../core/utils/app_colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.navigationBackground,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: AppColors.navigationUnselected,
        currentIndex: currentIndex,
        onTap: (index) {
          // Prevent unnecessary navigation if already on the same page
          if (index == currentIndex) return;

          // Get page state service for activation notification
          final pageStateService = Get.find<PageStateService>();

          // Notify page activation before navigation
          PageType? pageType;
          switch (index) {
            case 1:
              pageType = PageType.explore;
              break;
            case 2:
              pageType = PageType.discover;
              break;
            case 3:
              pageType = PageType.likes;
              break;
          }

          if (pageType != null) {
            pageStateService.notifyPageActivated(pageType);
          }

          // Use the required onTap callback
          onTap(index);
        },
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Likes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Visits',
          ),
        ],
      ),
    );
  }
}
