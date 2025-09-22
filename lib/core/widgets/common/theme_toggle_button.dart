import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/controllers/theme_controller.dart';
import 'package:ghar360/core/utils/app_colors.dart';

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

      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      Color iconColorFor(AppThemeMode mode) {
        switch (mode) {
          case AppThemeMode.light:
            return colorScheme.primary;
          case AppThemeMode.dark:
            return colorScheme.onPrimary;
          case AppThemeMode.system:
            return colorScheme.secondary;
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
                Icon(getThemeIcon(), size: iconSize ?? 20, color: iconColorFor(currentMode)),
                const SizedBox(width: 8),
                Text(
                  getThemeLabel(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.labelLarge?.color ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return IconButton(
        onPressed: () => themeController.toggleTheme(),
        icon: Icon(getThemeIcon(), size: iconSize ?? 24, color: iconColorFor(currentMode)),
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
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      final isDark = theme.brightness == Brightness.dark;

      // Get appropriate colors and icons based on current theme mode
      Color getBackgroundColor() {
        switch (currentMode) {
          case AppThemeMode.light:
            return isDark
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceTint.withValues(alpha: 0.25);
          case AppThemeMode.dark:
            return colorScheme.primary;
          case AppThemeMode.system:
            return colorScheme.secondaryContainer;
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
            return colorScheme.primary;
          case AppThemeMode.dark:
            return colorScheme.onPrimary;
          case AppThemeMode.system:
            return colorScheme.onSecondaryContainer;
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
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(getIcon(), size: (size ?? 60) / 4, color: getIconColor()),
            ),
          ),
        ),
      );
    });
  }
}
