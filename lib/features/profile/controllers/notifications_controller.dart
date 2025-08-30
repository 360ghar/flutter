import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class NotificationsController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Push Notifications
  final RxBool pushNotificationsMaster = true.obs;
  final RxBool newPropertiesNotifications = true.obs;
  final RxBool priceDropNotifications = true.obs;
  final RxBool favoritesNotifications = true.obs;
  final RxBool tourReminders = true.obs;

  // Email Notifications
  final RxBool weeklyDigest = true.obs;
  final RxBool marketingEmails = false.obs;
  final RxBool accountUpdates = true.obs;

  // Quiet Hours
  final RxBool quietHoursEnabled = false.obs;
  final Rx<TimeOfDay> quietHoursStart = const TimeOfDay(
    hour: 22,
    minute: 0,
  ).obs;
  final Rx<TimeOfDay> quietHoursEnd = const TimeOfDay(hour: 7, minute: 0).obs;

  // Notification Frequency
  final RxString newPropertiesFrequency = 'Daily'.obs;
  final RxString priceAlertsFrequency = 'Instant'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotificationSettings();
  }

  void _loadNotificationSettings() {
    // Push Notifications
    pushNotificationsMaster.value =
        _storage.read('pushNotificationsMaster') ?? true;
    newPropertiesNotifications.value =
        _storage.read('newPropertiesNotifications') ?? true;
    priceDropNotifications.value =
        _storage.read('priceDropNotifications') ?? true;
    favoritesNotifications.value =
        _storage.read('favoritesNotifications') ?? true;
    tourReminders.value = _storage.read('tourReminders') ?? true;

    // Email Notifications
    weeklyDigest.value = _storage.read('weeklyDigest') ?? true;
    marketingEmails.value = _storage.read('marketingEmails') ?? false;
    accountUpdates.value = _storage.read('accountUpdates') ?? true;

    // Quiet Hours
    quietHoursEnabled.value = _storage.read('quietHoursEnabled') ?? false;

    // Load quiet hours times
    final quietStartData = _storage.read('quietHoursStart');
    if (quietStartData != null) {
      quietHoursStart.value = TimeOfDay(
        hour: quietStartData['hour'] ?? 22,
        minute: quietStartData['minute'] ?? 0,
      );
    }

    final quietEndData = _storage.read('quietHoursEnd');
    if (quietEndData != null) {
      quietHoursEnd.value = TimeOfDay(
        hour: quietEndData['hour'] ?? 7,
        minute: quietEndData['minute'] ?? 0,
      );
    }

    // Notification Frequency
    newPropertiesFrequency.value =
        _storage.read('newPropertiesFrequency') ?? 'Daily';
    priceAlertsFrequency.value =
        _storage.read('priceAlertsFrequency') ?? 'Instant';
  }

  void saveNotificationSettings() {
    try {
      // Push Notifications
      _storage.write('pushNotificationsMaster', pushNotificationsMaster.value);
      _storage.write(
        'newPropertiesNotifications',
        newPropertiesNotifications.value,
      );
      _storage.write('priceDropNotifications', priceDropNotifications.value);
      _storage.write('favoritesNotifications', favoritesNotifications.value);
      _storage.write('tourReminders', tourReminders.value);

      // Email Notifications
      _storage.write('weeklyDigest', weeklyDigest.value);
      _storage.write('marketingEmails', marketingEmails.value);
      _storage.write('accountUpdates', accountUpdates.value);

      // Quiet Hours
      _storage.write('quietHoursEnabled', quietHoursEnabled.value);
      _storage.write('quietHoursStart', {
        'hour': quietHoursStart.value.hour,
        'minute': quietHoursStart.value.minute,
      });
      _storage.write('quietHoursEnd', {
        'hour': quietHoursEnd.value.hour,
        'minute': quietHoursEnd.value.minute,
      });

      // Notification Frequency
      _storage.write('newPropertiesFrequency', newPropertiesFrequency.value);
      _storage.write('priceAlertsFrequency', priceAlertsFrequency.value);

      Get.snackbar(
        'Success',
        'Notification settings saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save notification settings',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  // Helper methods to check if notifications are enabled
  bool get arePushNotificationsEnabled => pushNotificationsMaster.value;
  bool get areNewPropertiesNotificationsEnabled =>
      pushNotificationsMaster.value && newPropertiesNotifications.value;
  bool get arePriceDropNotificationsEnabled =>
      pushNotificationsMaster.value && priceDropNotifications.value;
  bool get areFavoritesNotificationsEnabled =>
      pushNotificationsMaster.value && favoritesNotifications.value;
  bool get areTourRemindersEnabled =>
      pushNotificationsMaster.value && tourReminders.value;

  bool isInQuietHours() {
    if (!quietHoursEnabled.value) return false;

    final now = TimeOfDay.now();
    final startMinutes =
        quietHoursStart.value.hour * 60 + quietHoursStart.value.minute;
    final endMinutes =
        quietHoursEnd.value.hour * 60 + quietHoursEnd.value.minute;
    final nowMinutes = now.hour * 60 + now.minute;

    if (startMinutes <= endMinutes) {
      // Same day range (e.g., 9:00 AM to 6:00 PM)
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Overnight range (e.g., 10:00 PM to 7:00 AM)
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  String getNotificationFrequencyDescription(String frequency) {
    switch (frequency) {
      case 'Instant':
        return 'Immediately when available';
      case 'Hourly':
        return 'Once every hour';
      case 'Daily':
        return 'Once per day';
      case 'Weekly':
        return 'Once per week';
      case 'Never':
        return 'Disabled';
      default:
        return frequency;
    }
  }
}
