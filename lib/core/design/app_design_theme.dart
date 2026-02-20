import 'package:flutter/material.dart';

import 'package:ghar360/core/design/app_design_components.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
import 'package:ghar360/core/utils/app_spacing.dart';

class AppDesignTheme {
  AppDesignTheme._();

  static const Duration defaultTransitionDuration = AppDurations.normal;
  static const Curve defaultTransitionCurve = AppCurves.standard;

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: AppDesignTokens.brandGold,
      onPrimary: AppDesignTokens.neutral900,
      secondary: AppDesignTokens.accentOrange,
      onSecondary: AppDesignTokens.neutralWhite,
      surface: AppDesignTokens.neutralWhite,
      onSurface: AppDesignTokens.neutral900,
      error: AppDesignTokens.error,
      onError: AppDesignTokens.neutralWhite,
      outline: AppDesignTokens.neutral300,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppDesignTokens.neutral50,
      colorScheme: colorScheme,
      textTheme: AppDesignComponents.textTheme(Brightness.light),
      appBarTheme: AppDesignComponents.appBarTheme(Brightness.light),
      elevatedButtonTheme: AppDesignComponents.elevatedButtonTheme(Brightness.light),
      filledButtonTheme: AppDesignComponents.filledButtonTheme(Brightness.light),
      outlinedButtonTheme: AppDesignComponents.outlinedButtonTheme(Brightness.light),
      textButtonTheme: AppDesignComponents.textButtonTheme(Brightness.light),
      inputDecorationTheme: AppDesignComponents.inputDecorationTheme(Brightness.light),
      cardTheme: AppDesignComponents.cardTheme(Brightness.light),
      switchTheme: AppDesignComponents.switchTheme(Brightness.light),
      dividerTheme: const DividerThemeData(color: AppDesignTokens.neutral300, thickness: 1),
    );
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppDesignTokens.brandGold,
      onPrimary: AppDesignTokens.neutral900,
      secondary: AppDesignTokens.accentOrange,
      onSecondary: AppDesignTokens.darkTextPrimary,
      surface: AppDesignTokens.darkSurface,
      onSurface: AppDesignTokens.darkTextPrimary,
      error: AppDesignTokens.error,
      onError: AppDesignTokens.darkTextPrimary,
      outline: AppDesignTokens.darkTextTertiary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppDesignTokens.neutral900,
      colorScheme: colorScheme,
      textTheme: AppDesignComponents.textTheme(Brightness.dark),
      appBarTheme: AppDesignComponents.appBarTheme(Brightness.dark),
      elevatedButtonTheme: AppDesignComponents.elevatedButtonTheme(Brightness.dark),
      filledButtonTheme: AppDesignComponents.filledButtonTheme(Brightness.dark),
      outlinedButtonTheme: AppDesignComponents.outlinedButtonTheme(Brightness.dark),
      textButtonTheme: AppDesignComponents.textButtonTheme(Brightness.dark),
      inputDecorationTheme: AppDesignComponents.inputDecorationTheme(Brightness.dark),
      cardTheme: AppDesignComponents.cardTheme(Brightness.dark),
      switchTheme: AppDesignComponents.switchTheme(Brightness.dark),
      dividerTheme: const DividerThemeData(color: AppDesignTokens.darkBorder, thickness: 1),
    );
  }
}
