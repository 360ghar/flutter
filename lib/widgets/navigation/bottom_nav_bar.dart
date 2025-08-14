import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/app_colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  
  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.navigationBackground,
      selectedItemColor: AppColors.primaryYellow,
      unselectedItemColor: AppColors.navigationUnselected,
      currentIndex: currentIndex,
      onTap: _onItemTapped,
      elevation: 8,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Discover',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Likes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Visits',
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    // Prevent unnecessary navigation if already on the same page
    if (index == currentIndex) return;
    
    // Use custom onTap if provided, otherwise use default navigation
    if (onTap != null) {
      onTap!(index);
    } else {
      // Updated navigation with new routes
      switch (index) {
        case 0:
          Get.offNamed('/profile');
          break;
        case 1:
          Get.offNamed('/explore'); // Map interface
          break;
        case 2:
          Get.offNamed('/discover'); // Swipe interface (was /home)
          break;
        case 3:
          Get.offNamed('/likes'); // Updated from /favourites
          break;
        case 4:
          Get.offNamed('/visits');
          break;
      }
    }
  }
}