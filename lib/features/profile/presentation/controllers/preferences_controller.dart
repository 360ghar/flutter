import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:ghar360/core/controllers/localization_controller.dart';
import 'package:ghar360/core/controllers/theme_controller.dart';

class PreferencesController extends GetxController {
  final GetStorage _storage = GetStorage();
  late final ThemeController _themeController;
  late final LocalizationController _localizationController;

  final RxBool pushNotifications = true.obs;
  final RxBool emailNotifications = true.obs;
  final RxBool similarProperties = true.obs;

  final Rx<AppThemeMode> themeMode = AppThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _themeController = Get.find<ThemeController>();
    _localizationController = Get.find<LocalizationController>();
    _loadPreferences();
  }

  void _loadPreferences() {
    pushNotifications.value = _storage.read('pushNotifications') ?? true;
    emailNotifications.value = _storage.read('emailNotifications') ?? true;
    similarProperties.value = _storage.read('similarProperties') ?? true;
    themeMode.value = _themeController.currentThemeMode;
  }

  void updateTheme(AppThemeMode mode) {
    _themeController.setThemeMode(mode);
    themeMode.value = mode;
  }

  void updateThemeFromBoolean(bool isDark) {
    updateTheme(isDark ? AppThemeMode.dark : AppThemeMode.light);
  }

  void changeLanguage(String languageCode, String countryCode) {
    _localizationController.changeLanguage(languageCode, countryCode);
  }

  String getCurrentLanguage() {
    return _localizationController.getCurrentLanguageName();
  }

  void savePreferences() {
    try {
      _storage.write('pushNotifications', pushNotifications.value);
      _storage.write('emailNotifications', emailNotifications.value);
      _storage.write('similarProperties', similarProperties.value);

      _themeController.setThemeMode(themeMode.value);

      Get.snackbar(
        'success'.tr,
        'preferences_saved'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'preferences_save_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  bool get isPushNotificationsEnabled => pushNotifications.value;
  bool get isEmailNotificationsEnabled => emailNotifications.value;
  bool get isSimilarPropertiesEnabled => similarProperties.value;
  AppThemeMode get currentThemeMode => themeMode.value;

  String get currentThemeName {
    switch (themeMode.value) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}
