import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/theme.dart';

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
    // Use static colors from AppTheme to avoid dependency on theme controller
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent, // Make background transparent since we have Container
        selectedItemColor: AppTheme.primaryYellow,
        unselectedItemColor: isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray,
        currentIndex: currentIndex,
        onTap: _onItemTapped,
        elevation: 0, // Remove elevation since we have our own shadow
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
      ),
    );
  }

  void _onItemTapped(int index) {
    // Prevent unnecessary navigation if already on the same page
    if (index == currentIndex) return;
    
    // Always use the provided onTap callback if available
    if (onTap != null) {
      onTap!(index);
      return;
    }
    
    // Fallback navigation only if no onTap callback is provided
    // This should typically not be needed in the current app structure
    switch (index) {
      case 0:
        Get.offNamed('/profile');
        break;
      case 1:
        Get.offNamed('/explore');
        break;
      case 2:
        Get.offNamed('/discover');
        break;
      case 3:
        Get.offNamed('/likes');
        break;
      case 4:
        Get.offNamed('/visits');
        break;
    }
  }
}