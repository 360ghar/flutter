import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

          // Delegate tab change to the provided callback (controller updates PageStateService)
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
