import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme.dart';

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

  // Basic theme-aware colors
  static Color get background {
    return Get.isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundGray;
  }

  static Color get surface {
    return Get.isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get cardBackground {
    return Get.isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get textPrimary {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get textSecondary {
    return Get.isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  static Color get textTertiary {
    return Get.isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  static Color get iconColor {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get divider {
    return Get.isDarkMode ? AppTheme.darkBorder : AppTheme.textLight.withOpacity(0.3);
  }

  static Color get border {
    return Get.isDarkMode ? AppTheme.darkBorder : AppTheme.textLight.withOpacity(0.2);
  }

  static Color get inputBackground {
    return Get.isDarkMode ? AppTheme.darkCard : AppTheme.backgroundGray;
  }

  static Color get shadowColor {
    return Get.isDarkMode ? AppTheme.darkShadow : AppTheme.cardShadow;
  }

  // Navigation specific colors
  static Color get navigationBackground {
    return Get.isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get navigationSelected {
    return primaryYellow;
  }

  static Color get navigationUnselected {
    return Get.isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  // App bar colors
  static Color get appBarBackground {
    return Get.isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get appBarText {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get appBarIcon {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  // Scaffold colors
  static Color get scaffoldBackground {
    return Get.isDarkMode ? AppTheme.darkBackground : AppTheme.backgroundGray;
  }

  // Property card specific colors
  static Color get propertyCardBackground {
    return Get.isDarkMode ? AppTheme.darkSurface : AppTheme.backgroundWhite;
  }

  static Color get propertyCardText {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get propertyCardSubtext {
    return Get.isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
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
    return Get.isDarkMode ? AppTheme.darkCard : AppTheme.backgroundGray;
  }

  static Color get buttonSecondaryText {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  // Loading and state colors
  static Color get loadingIndicator {
    return primaryYellow;
  }

  static Color get placeholderText {
    return Get.isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  static Color get disabledColor {
    return Get.isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  // Snackbar colors
  static Color get snackbarBackground {
    return Get.isDarkMode ? AppTheme.darkCard : AppTheme.backgroundWhite;
  }

  static Color get snackbarText {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  // Property feature colors
  static Color get propertyFeatureIcon {
    return Get.isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  static Color get propertyFeatureText {
    return Get.isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  // Favorite colors
  static Color get favoriteActive {
    return errorRed;
  }

  static Color get favoriteInactive {
    return Get.isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  // Filter colors
  static Color get filterBackground {
    return Get.isDarkMode ? AppTheme.darkCard : AppTheme.backgroundGray;
  }

  static Color get filterText {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get filterBorder {
    return Get.isDarkMode ? AppTheme.darkBorder : AppTheme.textLight.withOpacity(0.3);
  }

  // Tab colors
  static Color get tabSelected {
    return primaryYellow;
  }

  static Color get tabUnselected {
    return Get.isDarkMode ? AppTheme.darkTextSecondary : AppTheme.textGray;
  }

  static Color get tabIndicator {
    return primaryYellow;
  }

  // Search colors
  static Color get searchBackground {
    return Get.isDarkMode ? AppTheme.darkCard : AppTheme.backgroundGray;
  }

  static Color get searchText {
    return Get.isDarkMode ? AppTheme.darkTextPrimary : AppTheme.textDark;
  }

  static Color get searchHint {
    return Get.isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  // Switch colors
  static Color get switchActive {
    return primaryYellow;
  }

  static Color get switchInactive {
    return Get.isDarkMode ? AppTheme.darkTextTertiary : AppTheme.textLight;
  }

  static Color get switchTrackActive {
    return primaryYellow.withOpacity(0.3);
  }

  static Color get switchTrackInactive {
    return Get.isDarkMode ? AppTheme.darkTextTertiary.withOpacity(0.3) : AppTheme.textLight.withOpacity(0.3);
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
        blurRadius: Get.isDarkMode ? 8 : 10,
        offset: const Offset(0, 4),
        spreadRadius: Get.isDarkMode ? 0 : 1,
      ),
    ];
  }

  // Method to get theme-aware elevation color
  static Color getElevationColor(int level) {
    if (Get.isDarkMode) {
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
}