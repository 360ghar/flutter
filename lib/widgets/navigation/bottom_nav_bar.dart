import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/app_colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  
  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
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
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Discover',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Properties',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Liked',
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