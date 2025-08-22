import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/mixins/theme_mixin.dart';
import '../controllers/notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> with ThemeMixin {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'Notifications',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Push Notifications
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Push Notifications'),
                  const SizedBox(height: 16),
                  _buildNotificationTile(
                    title: 'Master Switch',
                    subtitle: 'Enable/disable all push notifications',
                    value: controller.pushNotificationsMaster,
                    onChanged: () => controller.pushNotificationsMaster.toggle(),
                  ),
                  _buildNotificationTile(
                    title: 'New Properties',
                    subtitle: 'Get notified when new properties match your preferences',
                    value: controller.newPropertiesNotifications,
                    onChanged: () => controller.newPropertiesNotifications.toggle(),
                  ),
                  _buildNotificationTile(
                    title: 'Price Drops',
                    subtitle: 'Receive alerts when property prices are reduced',
                    value: controller.priceDropNotifications,
                    onChanged: () => controller.priceDropNotifications.toggle(),
                  ),
                  _buildNotificationTile(
                    title: 'Favorites Updates',
                    subtitle: 'Changes to properties in your favorites',
                    value: controller.favoritesNotifications,
                    onChanged: () => controller.favoritesNotifications.toggle(),
                  ),
                  _buildNotificationTile(
                    title: 'Tour Reminders',
                    subtitle: 'Reminders for scheduled property tours',
                    value: controller.tourReminders,
                    onChanged: () => controller.tourReminders.toggle(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Email Notifications
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Email Notifications'),
                  const SizedBox(height: 16),
                  _buildNotificationTile(
                    title: 'Weekly Digest',
                    subtitle: 'Weekly summary of new properties and updates',
                    value: controller.weeklyDigest,
                    onChanged: () => controller.weeklyDigest.toggle(),
                  ),
                  _buildNotificationTile(
                    title: 'Marketing Emails',
                    subtitle: 'Property deals and promotional offers',
                    value: controller.marketingEmails,
                    onChanged: () => controller.marketingEmails.toggle(),
                  ),
                  _buildNotificationTile(
                    title: 'Account Updates',
                    subtitle: 'Important account and security updates',
                    value: controller.accountUpdates,
                    onChanged: () => controller.accountUpdates.toggle(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Notification Timing
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Notification Timing'),
                  const SizedBox(height: 16),
                  _buildTimingTile(
                    title: 'Quiet Hours',
                    subtitle: 'Don\'t send notifications during these hours',
                    startTime: controller.quietHoursStart,
                    endTime: controller.quietHoursEnd,
                    isEnabled: controller.quietHoursEnabled,
                    onToggle: () => controller.quietHoursEnabled.toggle(),
                    onStartTimeChanged: (time) => controller.quietHoursStart.value = time,
                    onEndTimeChanged: (time) => controller.quietHoursEnd.value = time,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownTile(
                    title: 'New Properties Frequency',
                    subtitle: 'How often you want to receive new property notifications',
                    value: controller.newPropertiesFrequency,
                    options: const [
                      'Instant',
                      'Hourly',
                      'Daily',
                      'Weekly',
                      'Never',
                    ],
                    onChanged: (value) => controller.newPropertiesFrequency.value = value,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownTile(
                    title: 'Price Alerts Frequency',  
                    subtitle: 'Frequency of price drop notifications',
                    value: controller.priceAlertsFrequency,
                    options: const [
                      'Instant',
                      'Daily',
                      'Weekly',
                      'Never',
                    ],
                    onChanged: (value) => controller.priceAlertsFrequency.value = value,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.saveNotificationSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: AppColors.buttonText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required RxBool value,
    required VoidCallback onChanged,
  }) {
    return Obx(() => ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value.value,
        onChanged: (_) => onChanged(),
        activeThumbColor: AppColors.switchActive,
        activeTrackColor: AppColors.switchTrackActive,
        inactiveThumbColor: AppColors.switchInactive,
        inactiveTrackColor: AppColors.switchTrackInactive,
      ),
      contentPadding: EdgeInsets.zero,
    ));
  }

  Widget _buildTimingTile({
    required String title,
    required String subtitle,
    required Rx<TimeOfDay> startTime,
    required Rx<TimeOfDay> endTime,
    required RxBool isEnabled,
    required VoidCallback onToggle,
    required Function(TimeOfDay) onStartTimeChanged,
    required Function(TimeOfDay) onEndTimeChanged,
  }) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Switch(
            value: isEnabled.value,
            onChanged: (_) => onToggle(),
            activeThumbColor: AppColors.switchActive,
            activeTrackColor: AppColors.switchTrackActive,
            inactiveThumbColor: AppColors.switchInactive,
            inactiveTrackColor: AppColors.switchTrackInactive,
          ),
          contentPadding: EdgeInsets.zero,
        ),
        if (isEnabled.value) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(startTime, onStartTimeChanged),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          startTime.value.format(Get.context!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(endTime, onEndTimeChanged),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          endTime.value.format(Get.context!),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ));
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required RxString value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Obx(() => ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: value.value,
            onChanged: (newValue) => onChanged(newValue!),
            style: TextStyle(color: AppColors.textPrimary),
            dropdownColor: AppColors.surface,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    ));
  }

  Future<void> _selectTime(Rx<TimeOfDay> currentTime, Function(TimeOfDay) onChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: Get.context!,
      initialTime: currentTime.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryYellow,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      onChanged(picked);
    }
  }
}