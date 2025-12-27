import 'package:flutter/material.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryYellow = Color(0xFFFFBC05); // Bumble's signature yellow
  static const Color primaryYellowDark = Color(0xFFE3AA04); // Darker yellow variant
  static const Color primaryYellowLight = Color(0xFFFCC937); // Lighter yellow variant

  // Secondary Colors
  static const Color accentOrange = Color(0xFFFF6B35); // Real estate accent
  static const Color accentBlue = Color(0xFF4A90E2); // Trust and reliability
  static const Color accentGreen = Color(0xFF50C878); // Success/available properties

  // Light Theme Colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color textGray = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color cardShadow = Color(0x1A000000);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1C1C1E);
  static const Color darkCard = Color(0xFF2C2C2E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFE5E5E7);
  static const Color darkTextTertiary = Color(0xFF8E8E93);
  static const Color darkBorder = Color(0xFF38383A);
  static const Color darkShadow = Color(0x40000000);

  // Status Colors
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFDC3545);

  // Alias for backward compatibility
  static const Color primaryColor = primaryYellow;

  // Standard transitions
  static const Duration defaultTransitionDuration = Duration(milliseconds: 300);
  static const Curve defaultTransitionCurve = Curves.easeOutCubic;

  static TextTheme _buildTextTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? darkTextPrimary : textDark;
    final secondary = isDark ? darkTextSecondary : textGray;
    final tertiary = isDark ? darkTextTertiary : textLight;

    final base = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

    return GoogleFonts.interTextTheme(
      base.copyWith(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: primary,
          height: 1.12,
          letterSpacing: -0.75,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: primary,
          height: 1.16,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: primary,
          height: 1.2,
          letterSpacing: -0.25,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primary,
          height: 1.25,
          letterSpacing: -0.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: primary,
          height: 1.3,
          letterSpacing: -0.15,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primary,
          height: 1.3,
          letterSpacing: -0.1,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.35,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.35,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.35,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: primary,
          height: 1.65,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: secondary,
          height: 1.6,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: tertiary,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.2,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.2,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primary,
          height: 1.2,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundGray,
      colorScheme: const ColorScheme.light(
        primary: primaryYellow,
        onPrimary: textDark,
        secondary: accentOrange,
        onSecondary: backgroundWhite,
        surface: backgroundWhite,
        onSurface: textDark,
        error: errorRed,
        onError: backgroundWhite,
        outline: textLight,
      ),
      textTheme: _buildTextTheme(brightness: Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: primaryYellow, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryYellow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: textDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: backgroundWhite,
        shadowColor: cardShadow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryYellow;
          }
          return textLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryYellow.withValues(alpha: 0.3);
          }
          return textLight.withValues(alpha: 0.3);
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        onPrimary: textDark,
        secondary: accentOrange,
        onSecondary: darkTextPrimary,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: errorRed,
        onError: darkTextPrimary,
        outline: darkTextTertiary,
      ),
      textTheme: _buildTextTheme(brightness: Brightness.dark),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextPrimary,
          side: const BorderSide(color: primaryYellow, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryYellow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryYellow,
          foregroundColor: textDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: darkSurface,
        shadowColor: darkShadow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryYellow, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryYellow;
          }
          return darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryYellow.withValues(alpha: 0.3);
          }
          return darkTextTertiary.withValues(alpha: 0.3);
        }),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
    );
  }
}
