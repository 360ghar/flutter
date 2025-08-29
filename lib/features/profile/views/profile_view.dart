import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/utils/app_colors.dart';
import '../../../widgets/common/theme_toggle_button.dart';
import '../../../widgets/common/robust_network_image.dart';

class ProfileView extends GetView<AuthController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'profile'.tr,
          style: TextStyle(
            color: AppColors.appBarText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.appBarIcon),
            onPressed: () => Get.toNamed('/preferences'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.loadingIndicator,
            ),
          );
        }

        final user = controller.currentUser.value;
        if (user == null) {
          return Center(
            child: Text(
              'No user data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(user),
              const SizedBox(height: 30),
              
              // Profile Completion
              _buildProfileCompletion(),
              const SizedBox(height: 30),
              
              // Menu Items
              _buildMenuItem(
                icon: Icons.person_outline,
                title: 'edit_profile'.tr,
                subtitle: 'Update your personal information',
                onTap: () => Get.toNamed('/edit-profile'),
              ),
              _buildMenuItem(
                icon: Icons.favorite_outline,
                title: 'my_preferences'.tr,
                subtitle: 'Property preferences and filters',
                onTap: () => Get.toNamed('/preferences'),
              ),
              _buildMenuItem(
                icon: Icons.history,
                title: 'Search History',
                subtitle: 'Your recent property searches',
                onTap: () => Get.toNamed('/search-history'),
              ),
              _buildMenuItem(
                icon: Icons.notifications,
                title: 'notifications'.tr,
                subtitle: 'Manage notification settings',
                onTap: () => Get.toNamed('/notifications'),
              ),
              _buildMenuItem(
                icon: Icons.security,
                title: 'Privacy & Security',
                subtitle: 'Account security settings',
                onTap: () => Get.toNamed('/privacy'),
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'help'.tr,
                subtitle: 'Get help and contact support',
                onTap: () => Get.toNamed('/help'),
              ),
              _buildMenuItem(
                icon: Icons.info_outline,
                title: 'about'.tr,
                subtitle: 'App version and information',
                onTap: () => Get.toNamed('/about'),
              ),
              const SizedBox(height: 20),
              
              // Logout Button
              _buildLogoutButton(),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    ));
  }

  Widget _buildProfileHeader(dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              user.profileImage != null && user.profileImage!.isNotEmpty
                  ? RobustNetworkImageExtension.circular(
                      imageUrl: user.profileImage!,
                      radius: 50,
                      errorWidget: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryYellow,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryYellow,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonText,
                        ),
                      ),
                    ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: AppColors.buttonText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            user.name.isNotEmpty ? user.name : 'User Name',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          
          // Email
          Text(
            user.email.isNotEmpty ? user.email : '',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Phone
          if (user.phone.isNotEmpty)
            Text(
              user.phone,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile Completion',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Obx(() => Text(
                '${controller.profileCompletionPercentage.value}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryYellow,
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() => LinearProgressIndicator(
            value: controller.profileCompletionPercentage.value / 100,
            backgroundColor: AppColors.inputBackground,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
          )),
          const SizedBox(height: 8),
          Text(
            'Complete your profile to get better property recommendations',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
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
          child: Icon(
            icon,
            color: AppColors.primaryYellow,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
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
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.iconColor,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
          side: BorderSide(color: AppColors.errorRed),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Logout',
          style: TextStyle(
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
        title: Text(
          'Logout',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to logout?',
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
              controller.signOut();
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }


} 
