import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/theme.dart';
import '../../../core/mixins/theme_mixin.dart';
import '../../../core/controllers/theme_controller.dart';
import '../controllers/preferences_controller.dart';

class PreferencesView extends GetView<PreferencesController> with ThemeMixin {
  const PreferencesView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'my_preferences'.tr,
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'property_preferences'.tr,
                [
                  _buildSwitchTile(
                    'push_notifications'.tr,
                    'push_notifications_desc'.tr,
                    controller.pushNotifications.value,
                    (value) => controller.pushNotifications.value = value,
                  ),
                  _buildSwitchTile(
                    'email_notifications'.tr,
                    'email_notifications_desc'.tr,
                    controller.emailNotifications.value,
                    (value) => controller.emailNotifications.value = value,
                  ),
                  _buildSwitchTile(
                    'price_drop_alerts'.tr,
                    'price_drop_alerts_desc'.tr,
                    controller.priceDropAlerts.value,
                    (value) => controller.priceDropAlerts.value = value,
                  ),
                  _buildSwitchTile(
                    'similar_properties'.tr,
                    'similar_properties_desc'.tr,
                    controller.similarProperties.value,
                    (value) => controller.similarProperties.value = value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'search_preferences'.tr,
                [
                  _buildSwitchTile(
                    'save_search_history'.tr,
                    'save_search_history_desc'.tr,
                    controller.saveSearchHistory.value,
                    (value) => controller.saveSearchHistory.value = value,
                  ),
                  _buildSwitchTile(
                    'location_services'.tr,
                    'location_services_desc'.tr,
                    controller.locationServices.value,
                    (value) => controller.locationServices.value = value,
                  ),
                  _buildSwitchTile(
                    'auto_complete_search'.tr,
                    'auto_complete_search_desc'.tr,
                    controller.autoCompleteSearch.value,
                    (value) => controller.autoCompleteSearch.value = value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'display_preferences'.tr,
                [
                  _buildThemeSelector(),
                  _buildSwitchTile(
                    'show_property_tour'.tr,
                    'show_property_tour_desc'.tr,
                    controller.showPropertyTour.value,
                    (value) => controller.showPropertyTour.value = value,
                  ),
                  _buildSwitchTile(
                    'compact_view'.tr,
                    'compact_view_desc'.tr,
                    controller.compactView.value,
                    (value) => controller.compactView.value = value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'language_preferences'.tr,
                [
                  _buildLanguageSelector(),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'privacy_preferences'.tr,
                [
                  _buildSwitchTile(
                    'share_analytics'.tr,
                    'share_analytics_desc'.tr,
                    controller.shareAnalytics.value,
                    (value) => controller.shareAnalytics.value = value,
                  ),
                  _buildSwitchTile(
                    'personalized_ads'.tr,
                    'personalized_ads_desc'.tr,
                    controller.personalizedAds.value,
                    (value) => controller.personalizedAds.value = value,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.savePreferences,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'save_preferences'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(Get.context!).colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(Get.context!).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'select_language'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'select_language_desc'.tr,
                  style: TextStyle(
                    color: Theme.of(Get.context!).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showLanguageDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.getCurrentLanguage(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('select_language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English', 'en', 'US'),
            const SizedBox(height: 8),
            _buildLanguageOption('हिंदी', 'hi', 'IN'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String languageName, String langCode, String countryCode) {
    return ListTile(
      title: Text(languageName),
      onTap: () {
        controller.changeLanguage(langCode, countryCode);
        Get.back();
      },
      trailing: controller.getCurrentLanguage() == languageName
          ? Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'app_theme'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'app_theme_desc'.tr,
                  style: TextStyle(
                    color: Theme.of(Get.context!).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showThemeDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.currentThemeName,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('app_theme'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Light', AppThemeMode.light, Icons.light_mode),
            const SizedBox(height: 8),
            _buildThemeOption('Dark', AppThemeMode.dark, Icons.dark_mode),
            const SizedBox(height: 8),
            _buildThemeOption('System', AppThemeMode.system, Icons.settings_system_daydream),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String themeName, AppThemeMode mode, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(themeName),
      onTap: () {
        controller.updateTheme(mode);
        Get.back();
      },
      trailing: controller.currentThemeMode == mode
          ? Icon(Icons.check, color: AppTheme.primaryColor)
          : null,
    );
  }
}