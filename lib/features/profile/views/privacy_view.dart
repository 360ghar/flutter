import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/mixins/theme_mixin.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/features/profile/views/policy_page_view.dart';

class PrivacyView extends StatelessWidget with ThemeMixin {
  const PrivacyView({super.key});

  static final List<_PolicyItem> _policyItems = const [
    _PolicyItem(
      title: 'Terms of Service',
      subtitle: 'Understand the conditions of using 360ghar',
      uniqueName: 'terms-of-service',
      icon: Icons.description_outlined,
    ),
    _PolicyItem(
      title: 'Privacy Policy',
      subtitle: 'How we collect, use, and safeguard your data',
      uniqueName: 'privacy-policy',
      icon: Icons.privacy_tip_outlined,
    ),
    _PolicyItem(
      title: 'Content Guidelines',
      subtitle: 'Learn what content is permitted on the platform',
      uniqueName: 'content-guidelines',
      icon: Icons.rule_folder_outlined,
    ),
    _PolicyItem(
      title: 'Content Takedown Policy',
      subtitle: 'Report or remove listings that violate our standards',
      uniqueName: 'content-takedown-policy',
      icon: Icons.remove_circle_outline,
    ),
    _PolicyItem(
      title: 'Grievance Redressal',
      subtitle: 'Reach our grievance officer for escalations',
      uniqueName: 'grievance-redressal-mechanism',
      icon: Icons.support_agent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'privacy_security'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('account_security'.tr),
                  const SizedBox(height: 16),
                  _buildSecurityItem(
                    icon: Icons.lock_outline,
                    title: 'change_password'.tr,
                    subtitle: 'update_account_password'.tr,
                    onTap: _changePassword,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('policies_legal'.tr),
                  const SizedBox(height: 16),
                  ..._policyItems.map(
                    (item) => _buildPolicyItem(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      uniqueName: item.uniqueName,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('account_management'.tr),
                  const SizedBox(height: 12),
                  Text(
                    'delete_account_description'.tr,
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showDeleteAccountDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'delete_account'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
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
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
      onTap: onTap,
    );
  }

  Widget _buildPolicyItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String uniqueName,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      trailing: Icon(Icons.arrow_forward_ios, color: AppColors.iconColor, size: 16),
      onTap: () => _openPolicy(uniqueName, title),
    );
  }

  void _changePassword() {
    Get.snackbar(
      'change_password_snackbar_title'.tr,
      'change_password_snackbar_message'.tr,
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'delete_account_dialog_title'.tr,
          style: const TextStyle(color: AppColors.errorRed),
        ),
        content: Text(
          'delete_account_dialog_content'.tr,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'account_deletion_snackbar_title'.tr,
                'account_deletion_snackbar_message'.tr,
                backgroundColor: AppColors.snackbarBackground,
                colorText: AppColors.snackbarText,
              );
            },
            child: Text('delete'.tr, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }

  void _openPolicy(String uniqueName, String title) {
    Get.to(() => PolicyPageView(uniqueName: uniqueName, titleText: title));
  }
}

class _PolicyItem {
  final String title;
  final String subtitle;
  final String uniqueName;
  final IconData icon;

  const _PolicyItem({
    required this.title,
    required this.subtitle,
    required this.uniqueName,
    required this.icon,
  });
}
