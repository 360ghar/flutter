import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/theme_controller.dart';
import 'package:ghar360/core/design/app_design_theme.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';

class AppPalette {
  const AppPalette({required this.isDark});

  final bool isDark;

  Color get background => isDark ? AppDesignTokens.neutral900 : AppDesignTokens.neutral50;
  Color get surface => isDark ? AppDesignTokens.darkSurface : AppDesignTokens.neutralWhite;
  Color get cardBackground => surface;

  Color get textPrimary => isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.neutral900;
  Color get textSecondary =>
      isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.neutral500;
  Color get textTertiary => isDark ? AppDesignTokens.darkTextTertiary : AppDesignTokens.neutral500;

  Color get border => isDark ? AppDesignTokens.darkBorder : AppDesignTokens.neutral300;
  Color get divider => border.withValues(alpha: isDark ? 0.9 : 0.7);
  Color get inputBackground => isDark ? AppDesignTokens.darkSurfaceAlt : AppDesignTokens.neutral50;

  Color get shadow => isDark ? AppDesignTokens.darkShadow : AppDesignTokens.lightShadow;

  Color get appBarBackground => surface;
  Color get appBarText => textPrimary;
  Color get appBarIcon => textPrimary;

  Color get navigationBackground => surface;
  Color get navigationUnselected => textSecondary;

  Color get buttonPrimary => AppDesignTokens.brandGold;
  Color get buttonPrimaryText => AppDesignTokens.neutral900;
  Color get buttonSecondaryBackground => inputBackground;
  Color get buttonSecondaryText => textPrimary;

  Color get success => AppDesignTokens.success;
  Color get warning => AppDesignTokens.warning;
  Color get error => AppDesignTokens.error;

  Color get accentBlue => AppDesignTokens.accentBlue;
  Color get accentOrange => AppDesignTokens.accentOrange;
  Color get accentGreen => AppDesignTokens.accentGreen;

  Color get favoriteActive => AppDesignTokens.error;
  Color get favoriteInactive => textTertiary;
}

extension AppDesignContext on BuildContext {
  AppPalette get design => AppPalette(isDark: Theme.of(this).brightness == Brightness.dark);
}

class AppDesign {
  AppDesign._();

  // Brand aliases
  static const Color primaryYellow = AppDesignTokens.brandGold;
  static const Color primaryYellowDark = AppDesignTokens.brandGoldDark;
  static const Color primaryYellowLight = AppDesignTokens.brandGoldLight;
  static const Color accentOrange = AppDesignTokens.accentOrange;
  static const Color accentBlue = AppDesignTokens.accentBlue;
  static const Color accentGreen = AppDesignTokens.accentGreen;

  // Light aliases
  static const Color backgroundWhite = AppDesignTokens.neutralWhite;
  static const Color backgroundGray = AppDesignTokens.neutral50;
  static const Color textDark = AppDesignTokens.neutral900;
  static const Color textGray = AppDesignTokens.neutral500;
  static const Color textLight = AppDesignTokens.neutral300;
  static const Color cardShadow = AppDesignTokens.lightShadow;

  // Dark aliases
  static const Color darkBackground = AppDesignTokens.neutral900;
  static const Color darkSurface = AppDesignTokens.darkSurface;
  static const Color darkCard = AppDesignTokens.darkSurfaceAlt;
  static const Color darkTextPrimary = AppDesignTokens.darkTextPrimary;
  static const Color darkTextSecondary = AppDesignTokens.darkTextSecondary;
  static const Color darkTextTertiary = AppDesignTokens.darkTextTertiary;
  static const Color darkBorder = AppDesignTokens.darkBorder;
  static const Color darkShadow = AppDesignTokens.darkShadow;

  // Status aliases
  static const Color successGreen = AppDesignTokens.success;
  static const Color warningAmber = AppDesignTokens.warning;
  static const Color errorRed = AppDesignTokens.error;

  static const Color transparent = Colors.transparent;
  static const Color primaryColor = primaryYellow;

  // Motion aliases
  static const Duration defaultTransitionDuration = AppDesignTheme.defaultTransitionDuration;
  static const Curve defaultTransitionCurve = AppDesignTheme.defaultTransitionCurve;

  // Theme aliases
  static ThemeData get lightTheme => AppDesignTheme.light();
  static ThemeData get darkTheme => AppDesignTheme.dark();

  static ThemeController? get _themeController {
    try {
      return Get.find<ThemeController>();
    } catch (_) {
      return null;
    }
  }

  static bool get _isDarkMode {
    final controller = _themeController;
    return controller?.isDarkMode.value ?? Get.isDarkMode;
  }

  static AppPalette get _palette => AppPalette(isDark: _isDarkMode);

  static Color get background => _palette.background;
  static Color get surface => _palette.surface;
  static Color get cardBackground => _palette.cardBackground;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get textTertiary => _palette.textTertiary;
  static Color get iconColor => _palette.textPrimary;
  static Color get divider => _palette.divider;
  static Color get border => _palette.border;
  static Color get inputBackground => _palette.inputBackground;
  static Color get shadowColor => _palette.shadow;

  static Color get navigationBackground => _palette.navigationBackground;
  static Color get navigationSelected => primaryYellow;
  static Color get navigationUnselected => _palette.navigationUnselected;

  static Color get appBarBackground => _palette.appBarBackground;
  static Color get appBarText => _palette.appBarText;
  static Color get appBarIcon => _palette.appBarIcon;
  static Color get scaffoldBackground => _palette.background;

  static Color get propertyCardBackground => _palette.cardBackground;
  static Color get propertyCardText => _palette.textPrimary;
  static Color get propertyCardSubtext => _palette.textSecondary;
  static Color get propertyCardPrice => primaryYellow;

  static Color get buttonBackground => _palette.buttonPrimary;
  static Color get buttonText => _palette.buttonPrimaryText;
  static Color get buttonSecondaryBackground => _palette.buttonSecondaryBackground;
  static Color get buttonSecondaryText => _palette.buttonSecondaryText;

  static Color get loadingIndicator => primaryYellow;
  static Color get placeholderText => _palette.textTertiary;
  static Color get disabledColor => _palette.textTertiary;

  static Color get snackbarBackground => _palette.surface;
  static Color get snackbarText => _palette.textPrimary;

  static Color get propertyFeatureIcon => _palette.textSecondary;
  static Color get propertyFeatureText => _palette.textSecondary;

  static Color get favoriteActive => _palette.favoriteActive;
  static Color get favoriteInactive => _palette.favoriteInactive;

  static Color get filterBackground => _palette.inputBackground;
  static Color get filterText => _palette.textPrimary;
  static Color get filterBorder => _palette.border;

  static Color get tabSelected => primaryYellow;
  static Color get tabUnselected => _palette.textSecondary;
  static Color get tabIndicator => primaryYellow;

  static Color get searchBackground => _palette.inputBackground;
  static Color get searchText => _palette.textPrimary;
  static Color get searchHint => _palette.textTertiary;

  static Color get switchActive => primaryYellow;
  static Color get switchInactive => _palette.textTertiary;
  static Color get switchTrackActive => primaryYellow.withValues(alpha: 0.3);
  static Color get switchTrackInactive => _palette.textTertiary.withValues(alpha: 0.3);

  static List<BoxShadow> getCardShadow() {
    return [
      BoxShadow(color: shadowColor, blurRadius: 14, spreadRadius: 0, offset: const Offset(0, 6)),
    ];
  }

  static Color getTextColorForBackground(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5 ? textDark : darkTextPrimary;
  }

  static Color getContrastColor(Color color) {
    return color.computeLuminance() > 0.5
        ? AppDesignTokens.neutral900
        : AppDesignTokens.neutralWhite;
  }
}
