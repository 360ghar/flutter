import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/controllers/localization_controller.dart';

class PreferencesController extends GetxController {
  final GetStorage _storage = GetStorage();
  late final ThemeController _themeController;
  late final LocalizationController _localizationController;

  // Property Preferences
  final RxBool pushNotifications = true.obs;
  final RxBool emailNotifications = true.obs;
  final RxBool priceDropAlerts = true.obs;
  final RxBool similarProperties = true.obs;

  // Search Preferences
  final RxBool saveSearchHistory = true.obs;
  final RxBool locationServices = true.obs;
  final RxBool autoCompleteSearch = true.obs;

  // Display Preferences
  final RxBool darkTheme = false.obs;
  final RxBool showPropertyTour = true.obs;
  final RxBool compactView = false.obs;

  // Privacy Preferences
  final RxBool shareAnalytics = false.obs;
  final RxBool personalizedAds = false.obs;

  @override
  void onInit() {
    super.onInit();
    _themeController = Get.find<ThemeController>();
    _localizationController = Get.find<LocalizationController>();
    _loadPreferences();
  }

  void _loadPreferences() {
    // Property Preferences
    pushNotifications.value = _storage.read('pushNotifications') ?? true;
    emailNotifications.value = _storage.read('emailNotifications') ?? true;
    priceDropAlerts.value = _storage.read('priceDropAlerts') ?? true;
    similarProperties.value = _storage.read('similarProperties') ?? true;

    // Search Preferences
    saveSearchHistory.value = _storage.read('saveSearchHistory') ?? true;
    locationServices.value = _storage.read('locationServices') ?? true;
    autoCompleteSearch.value = _storage.read('autoCompleteSearch') ?? true;

    // Display Preferences
    darkTheme.value = _themeController.isDarkMode.value;
    showPropertyTour.value = _storage.read('showPropertyTour') ?? true;
    compactView.value = _storage.read('compactView') ?? false;

    // Privacy Preferences
    shareAnalytics.value = _storage.read('shareAnalytics') ?? false;
    personalizedAds.value = _storage.read('personalizedAds') ?? false;
  }

  void updateTheme(bool isDark) {
    _themeController.setTheme(isDark);
  }

  void changeLanguage(String languageCode, String countryCode) {
    _localizationController.changeLanguage(languageCode, countryCode);
  }

  String getCurrentLanguage() {
    return _localizationController.getCurrentLanguageName();
  }

  void savePreferences() {
    try {
      // Property Preferences
      _storage.write('pushNotifications', pushNotifications.value);
      _storage.write('emailNotifications', emailNotifications.value);
      _storage.write('priceDropAlerts', priceDropAlerts.value);
      _storage.write('similarProperties', similarProperties.value);

      // Search Preferences
      _storage.write('saveSearchHistory', saveSearchHistory.value);
      _storage.write('locationServices', locationServices.value);
      _storage.write('autoCompleteSearch', autoCompleteSearch.value);

      // Display Preferences
      _themeController.setTheme(darkTheme.value);
      _storage.write('showPropertyTour', showPropertyTour.value);
      _storage.write('compactView', compactView.value);

      // Privacy Preferences
      _storage.write('shareAnalytics', shareAnalytics.value);
      _storage.write('personalizedAds', personalizedAds.value);

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

  // Getter methods for easy access from other controllers
  bool get isPushNotificationsEnabled => pushNotifications.value;
  bool get isEmailNotificationsEnabled => emailNotifications.value;
  bool get isPriceDropAlertsEnabled => priceDropAlerts.value;
  bool get isSimilarPropertiesEnabled => similarProperties.value;
  bool get isSaveSearchHistoryEnabled => saveSearchHistory.value;
  bool get isLocationServicesEnabled => locationServices.value;
  bool get isAutoCompleteSearchEnabled => autoCompleteSearch.value;
  bool get isDarkThemeEnabled => darkTheme.value;
  bool get isShowPropertyTourEnabled => showPropertyTour.value;
  bool get isCompactViewEnabled => compactView.value;
  bool get isShareAnalyticsEnabled => shareAnalytics.value;
  bool get isPersonalizedAdsEnabled => personalizedAds.value;
}