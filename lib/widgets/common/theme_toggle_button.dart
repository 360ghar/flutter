import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/controllers/theme_controller.dart';
import '../../app/utils/theme.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double? iconSize;

  const ThemeToggleButton({
    Key? key,
    this.showLabel = false,
    this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      
      if (showLabel) {
        return InkWell(
          onTap: () => themeController.toggleTheme(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  size: iconSize ?? 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isDark ? 'Light Mode' : 'Dark Mode',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      return IconButton(
        onPressed: () => themeController.toggleTheme(),
        icon: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          size: iconSize ?? 24,
        ),
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      );
    });
  }
}

class AnimatedThemeToggle extends StatelessWidget {
  final double? size;

  const AnimatedThemeToggle({
    Key? key,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      
      return GestureDetector(
        onTap: () => themeController.toggleTheme(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size ?? 60,
          height: (size ?? 60) / 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular((size ?? 60) / 4),
            color: isDark ? AppTheme.primaryColor : Colors.grey[300],
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isDark ? (size ?? 60) / 2 - 2 : 2,
                top: 2,
                child: Container(
                  width: (size ?? 60) / 2 - 4,
                  height: (size ?? 60) / 2 - 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    size: (size ?? 60) / 4,
                    color: isDark ? AppTheme.primaryColor : Colors.amber,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}