import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

enum AppThemeMode { light, dark, system }

class ThemeController extends GetxController with WidgetsBindingObserver {
  final GetStorage _storage = GetStorage();

  static const _themeModeMap = {
    AppThemeMode.light: ThemeMode.light,
    AppThemeMode.dark: ThemeMode.dark,
    AppThemeMode.system: ThemeMode.system,
  };

  static const _themeNameMap = {
    AppThemeMode.light: 'Light',
    AppThemeMode.dark: 'Dark',
    AppThemeMode.system: 'System',
  };

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
        _themeMode.value = AppThemeMode.values.firstWhere(
          (mode) => mode.name == storedThemeMode,
          orElse: () => AppThemeMode.system,
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
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
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
    Get.changeThemeMode(_themeModeMap[_themeMode.value]!);
  }

  void _saveThemeToStorage() {
    _storage.write('themeMode', _themeMode.value.name);
  }

  // Sync with preferences controller
  void syncWithPreferences(bool darkThemeFromPreferences) {
    final newMode = darkThemeFromPreferences ? AppThemeMode.dark : AppThemeMode.light;
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

  ThemeMode get themeMode => _themeModeMap[_themeMode.value]!;

  String get currentThemeName => _themeNameMap[_themeMode.value]!;

  bool get isSystemMode => _themeMode.value == AppThemeMode.system;
}
