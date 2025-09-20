import 'dart:ui';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocalizationController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Supported languages
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('hi', 'IN'), // Hindi
  ];

  // Current locale
  final Rx<Locale> _currentLocale = const Locale('en', 'US').obs;
  Locale get currentLocale => _currentLocale.value;

  // Language names for display
  final Map<String, String> languageNames = {
    'en_US': 'English',
    'hi_IN': 'हिंदी',
  };

  @override
  void onInit() {
    super.onInit();
    _loadLocale();
  }

  void _loadLocale() {
    String? languageCode = _storage.read('language_code');
    String? countryCode = _storage.read('country_code');

    if (languageCode != null && countryCode != null) {
      _currentLocale.value = Locale(languageCode, countryCode);
      Get.updateLocale(_currentLocale.value);
    } else {
      // No saved preference: normalize device locale to a supported one
      final device = Get.deviceLocale;
      final normalized = _normalizeToSupported(device);
      _currentLocale.value = normalized;
      Get.updateLocale(normalized);
    }
  }

  // Map arbitrary device locales to the closest supported locale
  Locale _normalizeToSupported(Locale? device) {
    if (device == null) return const Locale('en', 'US');

    switch (device.languageCode) {
      case 'hi':
        return const Locale('hi', 'IN');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('en', 'US');
    }
  }

  void changeLanguage(String languageCode, String countryCode) {
    Locale newLocale = Locale(languageCode, countryCode);
    _currentLocale.value = newLocale;

    // Save to storage
    _storage.write('language_code', languageCode);
    _storage.write('country_code', countryCode);

    // Update GetX locale
    Get.updateLocale(newLocale);

    Get.snackbar(
      'language_changed'.tr,
      'language_changed_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  String getCurrentLanguageName() {
    String localeKey =
        '${_currentLocale.value.languageCode}_${_currentLocale.value.countryCode}';
    return languageNames[localeKey] ?? 'English';
  }

  bool get isEnglish => _currentLocale.value.languageCode == 'en';
  bool get isHindi => _currentLocale.value.languageCode == 'hi';
}
