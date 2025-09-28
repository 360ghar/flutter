import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/app_update_controller.dart';
import 'package:ghar360/core/data/models/app_update_models.dart';
import 'package:ghar360/core/mixins/theme_mixin.dart';
import 'package:ghar360/core/utils/app_colors.dart';

class AboutView extends StatelessWidget with ThemeMixin {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final appUpdateController = Get.find<AppUpdateController>();
    final platformLabel = _platformLabel();
    final versionInfoFuture = appUpdateController.getVersionInfo();

    return buildThemeAwareScaffold(
      title: 'About 360ghar',
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
                      color: AppColors.primaryYellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.home, size: 40, color: AppColors.buttonText),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '360ghar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Your Real Estate Companion',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
                  buildSectionTitle('About the App'),
                  const SizedBox(height: 16),
                  Text(
                    '360ghar is a modern real estate application that transforms property browsing into an engaging, swipe-based experience. Discover your dream home with our intuitive interface, 360° virtual tours, and comprehensive property details.',
                    style: TextStyle(fontSize: 16, color: AppColors.textPrimary, height: 1.5),
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
                  buildSectionTitle('Key Features'),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.swipe,
                    title: 'Swipe to Discover',
                    description: 'Dating-app style interface for property browsing',
                  ),
                  _buildFeatureItem(
                    icon: Icons.threesixty,
                    title: '360° Virtual Tours',
                    description: 'Immersive property exploration from anywhere',
                  ),
                  _buildFeatureItem(
                    icon: Icons.favorite,
                    title: 'Smart Favorites',
                    description: 'Save and organize your preferred properties',
                  ),
                  _buildFeatureItem(
                    icon: Icons.location_on,
                    title: 'Location Intelligence',
                    description: 'Detailed neighborhood information and mapping',
                  ),
                  _buildFeatureItem(
                    icon: Icons.person,
                    title: 'Agent Connect',
                    description: 'Direct communication with verified agents',
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
                      _buildInfoRow('Version', version ?? '—'),
                      _buildInfoRow('Build', buildNumber != null ? buildNumber.toString() : '—'),
                      _buildInfoRow('Platform', platformLabel),
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
                    '© 2025 360ghar. All rights reserved.',
                    style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made with ❤️ for property seekers everywhere',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
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
              color: AppColors.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryYellow, size: 20),
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
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
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
          Text(label, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
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
