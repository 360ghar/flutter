import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/mixins/theme_mixin.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';

class ProfileView extends GetView<AuthController> with ThemeMixin {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'profile'.tr,
      body: Semantics(
        label: 'qa.profile.screen',
        identifier: 'qa.profile.screen',
        child: Obx(() {
          final Widget child;
          final Key key;

          if (controller.isLoading.value) {
            key = const ValueKey('loading');
            child = Center(child: CircularProgressIndicator(color: AppDesign.loadingIndicator));
          } else {
            final user = controller.currentUser.value;
            if (user == null) {
              key = const ValueKey('empty');
              child = Center(
                child: Text(
                  'no_user_data_available'.tr,
                  style: TextStyle(color: AppDesign.textSecondary),
                ),
              );
            } else {
              key = const ValueKey('content');
              child = SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context, user),
                    const SizedBox(height: 32),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, 'account_section'.tr),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.favorite_outline,
                                title: 'my_preferences'.tr,
                                subtitle: 'property_preferences_filters'.tr,
                                qaKey: 'qa.profile.menu.preferences',
                                onTap: () => Get.toNamed(AppRoutes.preferences),
                                showDivider: true,
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.calculate_outlined,
                                title: 'tools_calculators'.tr,
                                subtitle: 'tools_calculators_subtitle'.tr,
                                qaKey: 'qa.profile.menu.tools',
                                onTap: () => Get.toNamed(AppRoutes.tools),
                                showDivider: false,
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          _buildSectionHeader(context, 'support_section'.tr),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              _buildMenuItem(
                                context: context,
                                icon: Icons.security,
                                title: 'privacy_security'.tr,
                                subtitle: 'account_security_settings'.tr,
                                qaKey: 'qa.profile.menu.privacy',
                                onTap: () => Get.toNamed(AppRoutes.privacy),
                                showDivider: true,
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.help_outline,
                                title: 'help'.tr,
                                subtitle: 'get_help_contact_support'.tr,
                                qaKey: 'qa.profile.menu.help',
                                onTap: () => Get.toNamed(AppRoutes.help),
                                showDivider: true,
                              ),
                              _buildMenuItem(
                                context: context,
                                icon: Icons.info_outline,
                                title: 'about'.tr,
                                subtitle: 'app_version_information'.tr,
                                qaKey: 'qa.profile.menu.about',
                                onTap: () => Get.toNamed(AppRoutes.about),
                                showDivider: false,
                              ),
                            ],
                          ),

                          const SizedBox(height: 48),

                          _buildLogoutButton(context),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
          }

          return AnimatedSwitcher(
            duration: AppDurations.contentFade,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(key: key, child: child),
          );
        }),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, dynamic user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'qa.profile.menu.edit_profile',
      identifier: 'qa.profile.menu.edit_profile',
      child: GestureDetector(
        key: const ValueKey('qa.profile.menu.edit_profile'),
        onTap: () => Get.toNamed(AppRoutes.editProfile),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 32, bottom: 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.primary.withValues(alpha: 0.05),
                      theme.scaffoldBackgroundColor,
                    ]
                  : [
                      AppDesign.editorialWarm.withValues(alpha: 0.12),
                      AppDesign.editorialWarm.withValues(alpha: 0.05),
                      colorScheme.surface,
                    ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? colorScheme.primary.withValues(alpha: 0.25)
                          : AppDesign.editorialWarm.withValues(alpha: 0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: isDark ? colorScheme.surface : AppDesign.backgroundWhite,
                  child: user.profileImage != null && user.profileImage!.isNotEmpty
                      ? ClipOval(
                          child: RobustNetworkImage(
                            imageUrl: user.profileImage!,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        )
                      : CircleAvatar(
                          radius: 52,
                          backgroundColor: AppDesign.primaryYellow.withValues(alpha: 0.2),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: AppDesign.primaryYellowDark,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                user.name.isNotEmpty ? user.name : 'user_name'.tr,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 26,
                ),
                textAlign: TextAlign.center,
              ),

              if (user.email.isNotEmpty || user.phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    if (user.email.isNotEmpty) user.email,
                    if (user.phone.isNotEmpty) user.phone,
                  ].join('  ·  '),
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 0.3,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String qaKey,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: qaKey,
      identifier: qaKey,
      child: Column(
        children: [
          ListTile(
            key: ValueKey(qaKey),
            onTap: onTap,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppDesign.primaryYellow.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppDesign.primaryYellowDark, size: 22),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          if (showDivider)
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 64,
              endIndent: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: TextButton(
        key: const ValueKey('qa.profile.logout'),
        onPressed: () => _showLogoutDialog(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          splashFactory: NoSplash.splashFactory,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        child: Text(
          'sign_out'.tr,
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final theme = Get.theme;
    Get.dialog(
      AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: Text('logout'.tr, style: TextStyle(color: theme.colorScheme.onSurface)),
        content: Text(
          'logout_confirm_message'.tr,
          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.signOut();
            },
            child: Text('logout'.tr, style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
