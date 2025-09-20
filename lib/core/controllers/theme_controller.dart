import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

enum AppThemeMode { light, dark, system }

class ThemeController extends GetxController with WidgetsBindingObserver {
  final GetStorage _storage = GetStorage();

  final Rx<AppThemeMode> _themeMode = AppThemeMode.system.obs;
  final RxBool isDarkMode = false.obs;

  AppThemeMode get currentThemeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeFromStorage();
    _updateThemeBasedOnMode();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void _loadThemeFromStorage() {
    final storedThemeMode = _storage.read('themeMode');
    if (storedThemeMode != null) {
      try {
        // Try to parse as .name first (preferred format)
        _themeMode.value = AppThemeMode.values.firstWhere(
          (mode) => mode.name == storedThemeMode,
          orElse: () {
            // Fallback: try legacy .toString() format
            return AppThemeMode.values.firstWhere(
              (mode) => mode.toString() == storedThemeMode,
              orElse: () => AppThemeMode.system,
            );
          },
        );
      } catch (e) {
        _themeMode.value = AppThemeMode.system;
      }
    } else {
      _themeMode.value = AppThemeMode.system;
      _storage.write('themeMode', _themeMode.value.name);
    }
  }

  void _updateThemeBasedOnMode() {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        isDarkMode.value = false;
        break;
      case AppThemeMode.dark:
        isDarkMode.value = true;
        break;
      case AppThemeMode.system:
        isDarkMode.value =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
        break;
    }
    _updateAppTheme();
  }

  void toggleTheme() {
    // Cycle through: light -> dark -> system -> light...
    switch (_themeMode.value) {
      case AppThemeMode.light:
        setThemeMode(AppThemeMode.dark);
        break;
      case AppThemeMode.dark:
        setThemeMode(AppThemeMode.system);
        break;
      case AppThemeMode.system:
        setThemeMode(AppThemeMode.light);
        break;
    }
  }

  void setThemeMode(AppThemeMode mode) {
    _themeMode.value = mode;
    _updateThemeBasedOnMode();
    _saveThemeToStorage();
    // Force app update to ensure immediate rebuilds
    Get.forceAppUpdate();
  }

  void setTheme(bool darkMode) {
    setThemeMode(darkMode ? AppThemeMode.dark : AppThemeMode.light);
  }

  void _updateAppTheme() {
    ThemeMode flutterThemeMode;
    switch (_themeMode.value) {
      case AppThemeMode.light:
        flutterThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        flutterThemeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        flutterThemeMode = ThemeMode.system;
        break;
    }
    Get.changeThemeMode(flutterThemeMode);
  }

  void _saveThemeToStorage() {
    _storage.write('themeMode', _themeMode.value.name);
  }

  // Sync with preferences controller
  void syncWithPreferences(bool darkThemeFromPreferences) {
    final newMode = darkThemeFromPreferences
        ? AppThemeMode.dark
        : AppThemeMode.light;
    if (_themeMode.value != newMode) {
      setThemeMode(newMode);
    }
  }

  // Listen to system theme changes when in system mode
  void handleSystemThemeChange() {
    if (_themeMode.value == AppThemeMode.system) {
      _updateThemeBasedOnMode();
    }
  }

  @override
  void didChangePlatformBrightness() {
    handleSystemThemeChange();
  }

  ThemeMode get themeMode {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  String get currentThemeName {
    switch (_themeMode.value) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  bool get isSystemMode => _themeMode.value == AppThemeMode.system;
}
