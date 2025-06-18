import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryYellow = Color(0xFFFFBC05);    // Bumble's signature yellow
  static const Color primaryYellowDark = Color(0xFFE3AA04); // Darker yellow variant
  static const Color primaryYellowLight = Color(0xFFFCC937); // Lighter yellow variant

  // Secondary Colors
  static const Color accentOrange = Color(0xFFFF6B35);     // Real estate accent
  static const Color accentBlue = Color(0xFF4A90E2);       // Trust and reliability
  static const Color accentGreen = Color(0xFF50C878);      // Success/available properties

  // Neutral Colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF2C2C2C);
  static const Color textGray = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color cardShadow = Color(0x1A000000);

  // Status Colors
  static const Color successGreen = Color(0xFF28A745);
  static const Color warningAmber = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFDC3545);

  // Alias for backward compatibility
  static const Color primaryColor = primaryYellow;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryYellow,
        secondary: accentOrange,
        surface: backgroundWhite,
        background: backgroundGray,
        error: errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textDark,
            letterSpacing: -0.5,
          ),
          displayMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textDark,
            letterSpacing: -0.25,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textDark,
            height: 1.5,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: textGray,
            height: 1.4,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(
          color: textDark,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: backgroundWhite,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryYellow,
        secondary: accentOrange,
        surface: const Color(0xFF1C1C1E),
        background: const Color(0xFF000000),
        error: errorRed,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: backgroundWhite,
            letterSpacing: -0.5,
          ),
          displayMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: backgroundWhite,
            letterSpacing: -0.25,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: backgroundWhite,
          ),
          bodyLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: backgroundWhite,
            height: 1.5,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: textLight,
            height: 1.4,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: backgroundWhite),
        titleTextStyle: TextStyle(
          color: backgroundWhite,
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF1C1C1E),
      ),
    );
  }
} 