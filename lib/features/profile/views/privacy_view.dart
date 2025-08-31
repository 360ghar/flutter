import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/mixins/theme_mixin.dart';
import '../../../core/utils/app_colors.dart';

class PrivacyView extends StatelessWidget with ThemeMixin {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'Privacy & Security',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Security
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Account Security'),
                  const SizedBox(height: 16),
                  _buildSecurityItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => _changePassword(),
                  ),
                  _buildSecurityItem(
                    icon: Icons.security,
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security',
                    trailing: Text(
                      'Disabled',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => _setupTwoFactor(),
                  ),
                  _buildSecurityItem(
                    icon: Icons.fingerprint,
                    title: 'Biometric Login',
                    subtitle: 'Use fingerprint or face ID',
                    trailing: Text(
                      'Enabled',
                      style: TextStyle(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => _toggleBiometric(),
                  ),
                  _buildSecurityItem(
                    icon: Icons.devices,
                    title: 'Active Sessions',
                    subtitle: 'Manage your logged-in devices',
                    onTap: () => _viewActiveSessions(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Data Privacy
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Data Privacy'),
                  const SizedBox(height: 16),
                  _buildPrivacyItem(
                    icon: Icons.visibility_off,
                    title: 'Profile Visibility',
                    subtitle: 'Control who can see your profile',
                    value: 'Friends Only',
                    onTap: () => _changeProfileVisibility(),
                  ),
                  _buildPrivacyItem(
                    icon: Icons.location_off,
                    title: 'Location Sharing',
                    subtitle: 'Share location for better recommendations',
                    value: 'Enabled',
                    onTap: () => _toggleLocationSharing(),
                  ),
                  _buildPrivacyItem(
                    icon: Icons.analytics,
                    title: 'Data Analytics',
                    subtitle: 'Help improve our services',
                    value: 'Enabled',
                    onTap: () => _toggleDataAnalytics(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Communication Privacy
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Communication Privacy'),
                  const SizedBox(height: 16),
                  _buildPrivacyItem(
                    icon: Icons.email,
                    title: 'Email Visibility',
                    subtitle: 'Who can see your email address',
                    value: 'Agents Only',
                    onTap: () => _changeEmailVisibility(),
                  ),
                  _buildPrivacyItem(
                    icon: Icons.phone,
                    title: 'Phone Visibility',
                    subtitle: 'Who can see your phone number',
                    value: 'Verified Agents',
                    onTap: () => _changePhoneVisibility(),
                  ),
                  _buildPrivacyItem(
                    icon: Icons.message,
                    title: 'Message Requests',
                    subtitle: 'Who can send you messages',
                    value: 'Anyone',
                    onTap: () => _changeMessageSettings(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Data Management
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Data Management'),
                  const SizedBox(height: 16),
                  _buildDataItem(
                    icon: Icons.download,
                    title: 'Download Your Data',
                    subtitle: 'Get a copy of your data',
                    onTap: () => _downloadData(),
                  ),
                  _buildDataItem(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    textColor: AppColors.errorRed,
                    onTap: () => _showDeleteAccountDialog(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Legal & Compliance
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Legal & Compliance'),
                  const SizedBox(height: 16),
                  _buildLegalItem(
                    icon: Icons.policy,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => _viewPrivacyPolicy(),
                  ),
                  _buildLegalItem(
                    icon: Icons.description,
                    title: 'Terms of Service',
                    subtitle: 'View terms and conditions',
                    onTap: () => _viewTermsOfService(),
                  ),
                  _buildLegalItem(
                    icon: Icons.cookie,
                    title: 'Cookie Settings',
                    subtitle: 'Manage cookie preferences',
                    onTap: () => _manageCookies(),
                  ),
                  _buildLegalItem(
                    icon: Icons.shield,
                    title: 'Data Protection',
                    subtitle: 'Learn about data protection',
                    onTap: () => _viewDataProtection(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Contact Support
            Center(
              child: TextButton(
                onPressed: () => _contactSupport(),
                child: Text(
                  'Need help with privacy settings?',
                  style: TextStyle(
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryYellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryYellow, size: 20),
      ),
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
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing:
          trailing ?? Icon(Icons.chevron_right, color: AppColors.iconColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPrivacyItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.iconColor),
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
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDataItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLegalItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.iconColor),
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
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      trailing: Icon(Icons.launch, color: AppColors.iconColor, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  // Action methods
  void _changePassword() {
    Get.snackbar(
      'Change Password',
      'Password change functionality would be implemented here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _setupTwoFactor() {
    Get.snackbar(
      'Two-Factor Authentication',
      '2FA setup would be implemented here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _toggleBiometric() {
    Get.snackbar(
      'Biometric Login',
      'Biometric settings would be configured here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _viewActiveSessions() {
    Get.snackbar(
      'Active Sessions',
      'Active sessions management would be displayed here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _changeProfileVisibility() {
    Get.snackbar(
      'Profile Visibility',
      'Profile visibility settings would be shown here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _toggleLocationSharing() {
    Get.snackbar(
      'Location Sharing',
      'Location sharing preferences would be configured here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _toggleDataAnalytics() {
    Get.snackbar(
      'Data Analytics',
      'Analytics preferences would be managed here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _changeEmailVisibility() {
    Get.snackbar(
      'Email Visibility',
      'Email visibility settings would be shown here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _changePhoneVisibility() {
    Get.snackbar(
      'Phone Visibility',
      'Phone visibility settings would be shown here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _changeMessageSettings() {
    Get.snackbar(
      'Message Settings',
      'Message request settings would be configured here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _downloadData() {
    Get.snackbar(
      'Download Data',
      'Data download process would be initiated here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Account',
          style: TextStyle(color: AppColors.errorRed),
        ),
        content: Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be lost.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Account Deletion',
                'Account deletion process would be initiated here',
                backgroundColor: AppColors.snackbarBackground,
                colorText: AppColors.snackbarText,
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  void _viewPrivacyPolicy() {
    Get.snackbar(
      'Privacy Policy',
      'Privacy policy would be displayed here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _viewTermsOfService() {
    Get.snackbar(
      'Terms of Service',
      'Terms of service would be displayed here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _manageCookies() {
    Get.snackbar(
      'Cookie Settings',
      'Cookie management would be implemented here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _viewDataProtection() {
    Get.snackbar(
      'Data Protection',
      'Data protection information would be displayed here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _contactSupport() {
    Get.snackbar(
      'Contact Support',
      'Support contact functionality would be implemented here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }
}
