import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/app_update_controller.dart';
import 'package:ghar360/core/data/models/app_update_models.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/mixins/theme_mixin.dart';

class AboutView extends StatelessWidget with ThemeMixin {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final appUpdateController = Get.find<AppUpdateController>();
    final platformLabel = _platformLabel();
    final versionInfoFuture = appUpdateController.getVersionInfo();

    return buildThemeAwareScaffold(
      title: 'about_360ghar'.tr,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name Section
            buildThemeAwareCard(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppDesign.primaryYellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.home, size: 40, color: AppDesign.buttonText),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '360ghar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppDesign.textPrimary,
                    ),
                  ),
                  Text(
                    'about_tagline'.tr,
                    style: TextStyle(fontSize: 16, color: AppDesign.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Description
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('about_app_section_title'.tr),
                  const SizedBox(height: 16),
                  Text(
                    'about_app_section_body'.tr,
                    style: TextStyle(fontSize: 16, color: AppDesign.textPrimary, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Features Section
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('about_key_features_title'.tr),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.swipe,
                    title: 'about_feature_swipe_title'.tr,
                    description: 'about_feature_swipe_desc'.tr,
                  ),
                  _buildFeatureItem(
                    icon: Icons.threesixty,
                    title: 'about_feature_tours_title'.tr,
                    description: 'about_feature_tours_desc'.tr,
                  ),
                  _buildFeatureItem(
                    icon: Icons.favorite,
                    title: 'about_feature_favorites_title'.tr,
                    description: 'about_feature_favorites_desc'.tr,
                  ),
                  _buildFeatureItem(
                    icon: Icons.location_on,
                    title: 'about_feature_location_title'.tr,
                    description: 'about_feature_location_desc'.tr,
                  ),
                  _buildFeatureItem(
                    icon: Icons.person,
                    title: 'about_feature_agent_title'.tr,
                    description: 'about_feature_agent_desc'.tr,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // App Information
            buildThemeAwareCard(
              child: FutureBuilder<AppVersionInfo?>(
                future: versionInfoFuture,
                builder: (context, snapshot) {
                  final version = snapshot.data?.version;
                  final buildNumber = snapshot.data?.buildNumber;

                  return Column(
                    children: [
                      _buildInfoRow('about_version_label'.tr, version ?? '—'),
                      _buildInfoRow(
                        'about_build_label'.tr,
                        buildNumber != null ? buildNumber.toString() : '—',
                      ),
                      _buildInfoRow('about_platform_label'.tr, platformLabel),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 30),

            // Copyright
            Center(
              child: Column(
                children: [
                  Text(
                    'about_copyright'.tr,
                    style: TextStyle(fontSize: 14, color: AppDesign.textTertiary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'about_made_with_love'.tr,
                    style: TextStyle(fontSize: 12, color: AppDesign.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppDesign.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppDesign.primaryYellow, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppDesign.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: AppDesign.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: AppDesign.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppDesign.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _platformLabel() {
    if (GetPlatform.isIOS) return 'iOS';
    if (GetPlatform.isAndroid) return 'Android';
    if (GetPlatform.isWeb) return 'Web';
    return 'Flutter';
  }
}
