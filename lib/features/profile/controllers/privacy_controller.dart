import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class PrivacyController extends GetxController {
  final GetStorage _storage = GetStorage();

  // Privacy Settings
  final RxBool profileVisible = true.obs;
  final RxBool showOnlineStatus = true.obs;
  final RxBool allowContact = true.obs;
  final RxBool locationSharing = true.obs;

  // Security Settings
  final RxBool twoFactorEnabled = false.obs;

  // Data & Analytics
  final RxBool dataCollection = true.obs;
  final RxBool personalizedAds = false.obs;
  final RxBool crashReports = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadPrivacySettings();
  }

  void _loadPrivacySettings() {
    // Privacy Settings
    profileVisible.value = _storage.read('profileVisible') ?? true;
    showOnlineStatus.value = _storage.read('showOnlineStatus') ?? true;
    allowContact.value = _storage.read('allowContact') ?? true;
    locationSharing.value = _storage.read('locationSharing') ?? true;

    // Security Settings
    twoFactorEnabled.value = _storage.read('twoFactorEnabled') ?? false;

    // Data & Analytics
    dataCollection.value = _storage.read('dataCollection') ?? true;
    personalizedAds.value = _storage.read('personalizedAds') ?? false;
    crashReports.value = _storage.read('crashReports') ?? true;
  }

  void savePrivacySettings() {
    try {
      // Privacy Settings
      _storage.write('profileVisible', profileVisible.value);
      _storage.write('showOnlineStatus', showOnlineStatus.value);
      _storage.write('allowContact', allowContact.value);
      _storage.write('locationSharing', locationSharing.value);

      // Security Settings
      _storage.write('twoFactorEnabled', twoFactorEnabled.value);

      // Data & Analytics
      _storage.write('dataCollection', dataCollection.value);
      _storage.write('personalizedAds', personalizedAds.value);
      _storage.write('crashReports', crashReports.value);

      Get.snackbar(
        'Success',
        'Privacy settings saved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save privacy settings',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  // Account Security Actions
  void changePassword() {
    Get.dialog(
      AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'Password changed successfully');
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void toggleTwoFactor(bool enabled) {
    if (enabled) {
      Get.dialog(
        AlertDialog(
          title: const Text('Enable Two-Factor Authentication'),
          content: const Text(
            'Two-factor authentication adds an extra layer of security to your account. '
            'You will need to enter a verification code from your authenticator app each time you log in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                twoFactorEnabled.value = true;
                Get.back();
                Get.snackbar('Success', 'Two-factor authentication enabled');
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    } else {
      Get.dialog(
        AlertDialog(
          title: const Text('Disable Two-Factor Authentication'),
          content: const Text(
            'Are you sure you want to disable two-factor authentication? '
            'This will make your account less secure.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                twoFactorEnabled.value = false;
                Get.back();
                Get.snackbar('Success', 'Two-factor authentication disabled');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
    }
  }

  void viewLoginActivity() {
    Get.dialog(
      AlertDialog(
        title: const Text('Login Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoginActivityItem('iPhone 13', 'Current session', 'Now'),
            _buildLoginActivityItem(
              'MacBook Pro',
              'Mumbai, India',
              '2 hours ago',
            ),
            _buildLoginActivityItem('iPad', 'Delhi, India', '1 day ago'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildLoginActivityItem(String device, String location, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.devices, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  location,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  void setupAccountRecovery() {
    Get.snackbar('Info', 'Account recovery setup will be available soon');
  }

  // Data Management Actions
  void downloadData() {
    Get.dialog(
      AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We will prepare a file containing all your data and send it to your registered email address. '
          'This may take up to 24 hours.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Success', 'Data download request submitted');
            },
            child: const Text('Request Download'),
          ),
        ],
      ),
    );
  }

  void manageBlockList() {
    Get.snackbar('Info', 'Block list management will be available soon');
  }

  void resetPreferences() {
    Get.dialog(
      AlertDialog(
        title: const Text('Reset Preferences'),
        content: const Text(
          'Are you sure you want to reset all app preferences to default values? '
          'This will not affect your account data.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Reset preferences to default
              profileVisible.value = true;
              showOnlineStatus.value = true;
              allowContact.value = true;
              locationSharing.value = true;
              dataCollection.value = true;
              personalizedAds.value = false;
              crashReports.value = true;

              savePrivacySettings();
              Get.back();
              Get.snackbar('Success', 'Preferences reset to default');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void deleteAccount() {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? '
          'This action cannot be undone and all your data will be lost.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.dialog(
                AlertDialog(
                  title: const Text('Final Confirmation'),
                  content: const Text(
                    'Type "DELETE" to confirm account deletion:',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.snackbar(
                          'Info',
                          'Account deletion process initiated',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('DELETE ACCOUNT'),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // Legal Actions
  void viewPrivacyPolicy() {
    Get.snackbar(
      'Privacy Policy',
      'Opening privacy policy in browser',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void viewTermsOfService() {
    Get.snackbar(
      'Terms of Service',
      'Opening terms of service in browser',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void viewDataProcessingAgreement() {
    Get.snackbar(
      'Data Processing Agreement',
      'Opening data processing agreement in browser',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
