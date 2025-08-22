import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme.dart';
import '../controllers/theme_controller.dart';

class AppColors {
  // Primary colors (consistent across themes)
  static const Color primaryYellow = AppTheme.primaryYellow;
  static const Color accentOrange = AppTheme.accentOrange;
  static const Color accentBlue = AppTheme.accentBlue;
  static const Color accentGreen = AppTheme.accentGreen;
  
  // Status colors (consistent across themes)
  static const Color successGreen = AppTheme.successGreen;
  static const Color warningAmber = AppTheme.warningAmber;
  static const Color errorRed = AppTheme.errorRed;

  // Helper to get theme controller safely
  static ThemeController? get _themeController {
    try {
      return Get.find<ThemeController>();
    } catch (e) {
      return null;
    }
  }

  // Helper to check if dark mode is enabled
  static bool get _isDarkMode {
    final controller = _themeController;
    return controller?.isDarkMode.value ?? Get.isDarkMode;
  }

  // Basic theme-aware colors
  static Color get background {
    return _isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundGray;
  }

  static Color get surface {
    return _isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get cardBackground {
    return _isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get textPrimary {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get textSecondary {
    return _isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  static Color get textTertiary {
    return _isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  static Color get iconColor {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get divider {
    return _isDarkMode ? AppTheme.darkBorder : AppTheme.textLight.withValues(alpha: 0.3);
  }

  static Color get border {
    return _isDarkMode ? AppTheme.darkBorder : AppTheme.textLight.withValues(alpha: 0.2);
  }

  static Color get inputBackground {
    return _isDarkMode ? AppTheme.darkCard : AppTheme.backgroundGray;
  }

  static Color get shadowColor {
    return _isDarkMode ? AppTheme.darkShadow : AppTheme.cardShadow;
  }

  // Navigation specific colors
  static Color get navigationBackground {
    return _isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get navigationSelected {
    return primaryYellow;
  }

  static Color get navigationUnselected {
    return _isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  // App bar colors
  static Color get appBarBackground {
    return _isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get appBarText {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get appBarIcon {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  // Scaffold colors
  static Color get scaffoldBackground {
    return _isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundGray;
  }

  // Property card specific colors
  static Color get propertyCardBackground {
    return _isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get propertyCardText {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get propertyCardSubtext {
    return _isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  static Color get propertyCardPrice {
    return primaryYellow;
  }

  // Button colors
  static Color get buttonBackground {
    return primaryYellow;
  }

  static Color get buttonText {
    return AppTheme.textDark; // Always dark text on yellow background
  }

  static Color get buttonSecondaryBackground {
    return _isDarkMode ? AppTheme.darkCard : AppTheme.backgroundGray;
  }

  static Color get buttonSecondaryText {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  // Loading and state colors
  static Color get loadingIndicator {
    return primaryYellow;
  }

  static Color get placeholderText {
    return _isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  static Color get disabledColor {
    return _isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  // Snackbar colors
  static Color get snackbarBackground {
    return _isDarkMode ? AppTheme.darkCard : AppTheme.backgroundWhite;
  }

  static Color get snackbarText {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  // Property feature colors
  static Color get propertyFeatureIcon {
    return _isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  static Color get propertyFeatureText {
    return _isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  // Favorite colors
  static Color get favoriteActive {
    return errorRed;
  }

  static Color get favoriteInactive {
    return _isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  // Filter colors
  static Color get filterBackground {
    return _isDarkMode ? AppTheme.darkCard : AppTheme.backgroundGray;
  }

  static Color get filterText {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get filterBorder {
    return _isDarkMode ? AppTheme.darkBorder : AppTheme.textLight.withValues(alpha: 0.3);
  }

  // Tab colors
  static Color get tabSelected {
    return primaryYellow;
  }

  static Color get tabUnselected {
    return _isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  static Color get tabIndicator {
    return primaryYellow;
  }

  // Search colors
  static Color get searchBackground {
    return _isDarkMode ? AppTheme.darkCard : AppTheme.backgroundGray;
  }

  static Color get searchText {
    return _isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get searchHint {
    return _isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  // Switch colors
  static Color get switchActive {
    return primaryYellow;
  }

  static Color get switchInactive {
    return _isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  static Color get switchTrackActive {
    return primaryYellow.withValues(alpha: 0.3);
  }

  static Color get switchTrackInactive {
    return _isDarkMode ? AppTheme.darkTextTertiary.withValues(alpha: 0.3) : AppTheme.textLight.withValues(alpha: 0.3);
  }

  // Method to get appropriate text color for given background
  static Color getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? AppTheme.textDark : AppTheme.darkTextPrimary;
  }

  // Method to get contrast color
  static Color getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  // Method to get theme-aware shadow
  static List<BoxShadow> getCardShadow() {
    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: _isDarkMode ? 8 : 10,
        offset: const Offset(0, 4),
        spreadRadius: _isDarkMode ? 0 : 1,
      ),
    ];
  }

  // Method to get theme-aware elevation color
  static Color getElevationColor(int level) {
    if (_isDarkMode) {
      switch (level) {
        case 1:
          return AppTheme.darkSurface;
        case 2:
          return AppTheme.darkCard;
        case 3:
          return const Color(0xFF3C3C3E);
        default:
          return AppTheme.darkSurface;
      }
    } else {
      return AppTheme.backgroundWhite;
    }
  }

  // Map-specific color overlays
  static Color get mapDarkOverlay {
    return Colors.black.withValues(alpha: 0.2);
  }

  static Color get mapLightOverlay {
    return Colors.white.withValues(alpha: 0.1);
  }

  static Color get loadingOverlay {
    return shadowColor.withValues(alpha: 0.3);
  }
}