import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/theme.dart';
import '../../../mixins/theme_mixin.dart';
import '../controllers/preferences_controller.dart';

class PreferencesView extends GetView<PreferencesController> with ThemeMixin {
  const PreferencesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'My Preferences',
      body: Obx(() {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Property Preferences',
                [
                  _buildSwitchTile(
                    'Push Notifications',
                    'Receive notifications for new properties',
                    controller.pushNotifications.value,
                    (value) => controller.pushNotifications.value = value,
                  ),
                  _buildSwitchTile(
                    'Email Notifications',
                    'Get property updates via email',
                    controller.emailNotifications.value,
                    (value) => controller.emailNotifications.value = value,
                  ),
                  _buildSwitchTile(
                    'Price Drop Alerts',
                    'Notify when saved properties drop in price',
                    controller.priceDropAlerts.value,
                    (value) => controller.priceDropAlerts.value = value,
                  ),
                  _buildSwitchTile(
                    'Similar Properties',
                    'Show similar properties in recommendations',
                    controller.similarProperties.value,
                    (value) => controller.similarProperties.value = value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Search Preferences',
                [
                  _buildSwitchTile(
                    'Save Search History',
                    'Keep track of your property searches',
                    controller.saveSearchHistory.value,
                    (value) => controller.saveSearchHistory.value = value,
                  ),
                  _buildSwitchTile(
                    'Location Services',
                    'Use location for nearby properties',
                    controller.locationServices.value,
                    (value) => controller.locationServices.value = value,
                  ),
                  _buildSwitchTile(
                    'Auto-complete Search',
                    'Show search suggestions while typing',
                    controller.autoCompleteSearch.value,
                    (value) => controller.autoCompleteSearch.value = value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Display Preferences',
                [
                  _buildSwitchTile(
                    'Dark Theme',
                    'Use dark theme for the app',
                    controller.darkTheme.value,
                    (value) {
                      controller.darkTheme.value = value;
                      controller.updateTheme(value);
                    },
                  ),
                  _buildSwitchTile(
                    'Show Property Tour',
                    'Display 360° tour button on property cards',
                    controller.showPropertyTour.value,
                    (value) => controller.showPropertyTour.value = value,
                  ),
                  _buildSwitchTile(
                    'Compact View',
                    'Show more properties in compact layout',
                    controller.compactView.value,
                    (value) => controller.compactView.value = value,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSection(
                'Privacy Preferences',
                [
                  _buildSwitchTile(
                    'Share Analytics',
                    'Help improve the app by sharing usage data',
                    controller.shareAnalytics.value,
                    (value) => controller.shareAnalytics.value = value,
                  ),
                  _buildSwitchTile(
                    'Personalized Ads',
                    'Show personalized advertisements',
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
                  child: const Text(
                    'Save Preferences',
                    style: TextStyle(
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
                    color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
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
}