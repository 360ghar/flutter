import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';

class ProfileView extends GetView<AuthController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'profile'.tr,
          style: TextStyle(color: AppColors.appBarText, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Removed gear/theme toggle icon per updated design direction
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.loadingIndicator));
        }

        final user = controller.currentUser.value;
        if (user == null) {
          return Center(
            child: Text(
              'no_user_data_available'.tr,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(context, user),
              const SizedBox(height: 30),

              // Menu Items
              _buildMenuItem(
                icon: Icons.favorite_outline,
                title: 'my_preferences'.tr,
                subtitle: 'property_preferences_filters'.tr,
                onTap: () => Get.toNamed(AppRoutes.preferences),
              ),
              _buildMenuItem(
                icon: Icons.calculate_outlined,
                title: 'tools_calculators'.tr,
                subtitle: 'tools_calculators_subtitle'.tr,
                onTap: () => Get.toNamed(AppRoutes.tools),
              ),
              _buildMenuItem(
                icon: Icons.security,
                title: 'privacy_security'.tr,
                subtitle: 'account_security_settings'.tr,
                onTap: () => Get.toNamed(AppRoutes.privacy),
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'help'.tr,
                subtitle: 'get_help_contact_support'.tr,
                onTap: () => Get.toNamed(AppRoutes.help),
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'about'.tr,
                subtitle: 'app_version_information'.tr,
                onTap: () => Get.toNamed(AppRoutes.about),
              ),
              const SizedBox(height: 20),

              // Logout Button
              _buildLogoutButton(),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.editProfile),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.getCardShadow(),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture
            user.profileImage != null && user.profileImage!.isNotEmpty
                ? RobustNetworkImageExtension.circular(
                    imageUrl: user.profileImage!,
                    radius: 40,
                    errorWidget: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryYellow,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  )
                : CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryYellow,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonText,
                      ),
                    ),
                  ),
            const SizedBox(width: 16),
            // User Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isNotEmpty ? user.name : 'user_name'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                  if (user.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(user.phone, style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
            // Edit Profile Arrow
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryYellow.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryYellow, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.iconColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: AppColors.surface,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showLogoutDialog(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.errorRed),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          'logout'.tr,
          style: const TextStyle(
            color: AppColors.errorRed,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('logout'.tr, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'logout_confirm_message'.tr,
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
              controller.signOut();
            },
            child: Text('logout'.tr, style: const TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}
