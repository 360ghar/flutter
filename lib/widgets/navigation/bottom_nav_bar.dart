import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/app_colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;
  
  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.navigationBackground,
      selectedItemColor: AppColors.navigationSelected,
      unselectedItemColor: AppColors.navigationUnselected,
      currentIndex: currentIndex,
      onTap: _onItemTapped,
      elevation: 8,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: 'profile'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.explore),
          label: 'discover'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: 'properties'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite),
          label: 'liked'.tr,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_today),
          label: 'visits'.tr,
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
      // Fallback to old navigation for backward compatibility
      switch (index) {
        case 0:
          Get.offNamed('/profile');
          break;
        case 1:
          Get.offNamed('/explore');
          break;
        case 2:
          Get.offNamed('/home');
          break;
        case 3:
          Get.offNamed('/favourites');
          break;
        case 4:
          Get.offNamed('/visits');
          break;
      }
    }
  }
} 