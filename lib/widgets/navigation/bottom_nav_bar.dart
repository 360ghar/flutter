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
    
    // Use custom onTap if provided, otherwise use default navigation
    if (onTap != null) {
      onTap!(index);
    } else {
      // Navigate to dashboard with proper tab index
      Get.offNamed('/dashboard');
      // Let dashboard controller handle the tab change
      if (Get.isRegistered<dynamic>(tag: 'DashboardController')) {
        try {
          final controller = Get.find<dynamic>(tag: 'DashboardController');
          controller.changeTab(index);
        } catch (e) {
          // Fallback: try finding without tag
          try {
            final controller = Get.find<dynamic>();
            if (controller.runtimeType.toString().contains('DashboardController')) {
              controller.changeTab(index);
            }
          } catch (_) {
            // Silent fail - controller will sync on route change
          }
        }
      }
    }
  }
}