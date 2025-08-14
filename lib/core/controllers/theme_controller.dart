import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final GetStorage _storage = GetStorage();
  
  final RxBool isDarkMode = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromStorage();
  }
  
  void _loadThemeFromStorage() {
    final storedTheme = _storage.read('darkTheme');
    if (storedTheme != null) {
      isDarkMode.value = storedTheme;
      _updateAppTheme();
    } else {
      // If no preference stored, follow system theme
      isDarkMode.value = Get.isDarkMode;
    }
  }
  
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _updateAppTheme();
    _saveThemeToStorage();
  }
  
  void setTheme(bool darkMode) {
    isDarkMode.value = darkMode;
    _updateAppTheme();
    _saveThemeToStorage();
  }
  
  void _updateAppTheme() {
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }
  
  void _saveThemeToStorage() {
    _storage.write('darkTheme', isDarkMode.value);
  }
  
  // Sync with preferences controller
  void syncWithPreferences(bool darkThemeFromPreferences) {
    if (isDarkMode.value != darkThemeFromPreferences) {
      setTheme(darkThemeFromPreferences);
    }
  }
  
  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  String get currentThemeName => isDarkMode.value ? 'Dark' : 'Light';
}