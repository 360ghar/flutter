/// Standardized spacing constants for consistent UI
class AppSpacing {
  AppSpacing._();

  // Spacing scale
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Common padding values
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
  static const double listItemSpacing = 12.0;
  static const double sectionSpacing = 24.0;
}

/// Standardized border radius constants
class AppBorderRadius {
  AppBorderRadius._();

  // Border radius scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double round = 999.0;

  // Semantic border radius
  static const double chip = 8.0;
  static const double badge = 8.0;
  static const double button = 12.0;
  static const double card = 16.0;
  static const double input = 12.0;
  static const double dialog = 16.0;
  static const double bottomSheet = 24.0;
  static const double modal = 24.0;
}

/// Standard durations for animations
class AppDurations {
  AppDurations._();

  static const Duration fastest = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 300);
}

/// Standard curves for animations
class AppCurves {
  AppCurves._();

  // ignore: library_private_types_in_public_api
  static const _CurvesClass curves = _CurvesClass();
}

class _CurvesClass {
  const _CurvesClass();
}
