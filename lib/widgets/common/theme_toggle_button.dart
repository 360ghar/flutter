import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/theme_controller.dart';
import '../../core/utils/theme.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double? iconSize;

  const ThemeToggleButton({super.key, this.showLabel = false, this.iconSize});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      final currentMode = themeController.currentThemeMode;

      // Get appropriate icon based on current theme mode
      IconData getThemeIcon() {
        switch (currentMode) {
          case AppThemeMode.light:
            return Icons.light_mode;
          case AppThemeMode.dark:
            return Icons.dark_mode;
          case AppThemeMode.system:
            return Icons.settings_system_daydream;
        }
      }

      // Get appropriate label based on current theme mode
      String getThemeLabel() {
        switch (currentMode) {
          case AppThemeMode.light:
            return 'Light Mode';
          case AppThemeMode.dark:
            return 'Dark Mode';
          case AppThemeMode.system:
            return 'System Mode';
        }
      }

      // Get tooltip for next theme mode
      String getTooltip() {
        switch (currentMode) {
          case AppThemeMode.light:
            return 'Switch to Dark Mode';
          case AppThemeMode.dark:
            return 'Switch to System Mode';
          case AppThemeMode.system:
            return 'Switch to Light Mode';
        }
      }

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
                  getThemeIcon(),
                  size: iconSize ?? 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  getThemeLabel(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      }

      return IconButton(
        onPressed: () => themeController.toggleTheme(),
        icon: Icon(getThemeIcon(), size: iconSize ?? 24),
        tooltip: getTooltip(),
      );
    });
  }
}

class AnimatedThemeToggle extends StatelessWidget {
  final double? size;

  const AnimatedThemeToggle({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();

    return Obx(() {
      final currentMode = themeController.currentThemeMode;

      // Get appropriate colors and icons based on current theme mode
      Color getBackgroundColor() {
        switch (currentMode) {
          case AppThemeMode.light:
            return Colors.grey[300]!;
          case AppThemeMode.dark:
            return AppTheme.primaryColor;
          case AppThemeMode.system:
            return Colors.blue[300]!;
        }
      }

      IconData getIcon() {
        switch (currentMode) {
          case AppThemeMode.light:
            return Icons.light_mode;
          case AppThemeMode.dark:
            return Icons.dark_mode;
          case AppThemeMode.system:
            return Icons.settings_system_daydream;
        }
      }

      Color getIconColor() {
        switch (currentMode) {
          case AppThemeMode.light:
            return Colors.amber;
          case AppThemeMode.dark:
            return AppTheme.primaryColor;
          case AppThemeMode.system:
            return Colors.blue[600]!;
        }
      }

      return GestureDetector(
        onTap: () => themeController.toggleTheme(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size ?? 60,
          height: (size ?? 60) / 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular((size ?? 60) / 4),
            color: getBackgroundColor(),
          ),
          child: Center(
            child: Container(
              width: (size ?? 60) / 2 - 4,
              height: (size ?? 60) / 2 - 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                getIcon(),
                size: (size ?? 60) / 4,
                color: getIconColor(),
              ),
            ),
          ),
        ),
      );
    });
  }
}
