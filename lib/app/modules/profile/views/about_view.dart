import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/app_colors.dart';
import '../../../mixins/theme_mixin.dart';

class AboutView extends StatelessWidget with ThemeMixin {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
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
                    child: Icon(
                      Icons.home,
                      size: 40,
                      color: AppColors.buttonText,
                    ),
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
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
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
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
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
              child: Column(
                children: [
                  _buildInfoRow('Version', '1.0.0'),
                  _buildInfoRow('Build', '100'),
                  _buildInfoRow('Platform', 'Flutter'),
                  _buildInfoRow('License', 'MIT License'),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Contact Information
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Contact & Support'),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'support@360ghar.com',
                    onTap: () => _launchEmail('support@360ghar.com'),
                  ),
                  _buildContactItem(
                    icon: Icons.phone,
                    title: 'Phone Support',
                    subtitle: '+1 (555) 123-4567',
                    onTap: () => _launchPhone('+15551234567'),
                  ),
                  _buildContactItem(
                    icon: Icons.web,
                    title: 'Website',
                    subtitle: 'www.360ghar.com',
                    onTap: () => _launchWebsite('https://www.360ghar.com'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Legal Section
            buildThemeAwareCard(
              child: Column(  
                children: [
                  ListTile(
                    leading: Icon(Icons.description, color: AppColors.iconColor),
                    title: Text(
                      'Terms of Service',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
                    onTap: () => _openTermsOfService(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(color: AppColors.border, height: 1),
                  ListTile(
                    leading: Icon(Icons.privacy_tip, color: AppColors.iconColor),
                    title: Text(
                      'Privacy Policy',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
                    onTap: () => _openPrivacyPolicy(),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(color: AppColors.border, height: 1),
                  ListTile(
                    leading: Icon(Icons.gavel, color: AppColors.iconColor),
                    title: Text(
                      'End User License Agreement',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
                    onTap: () => _openEULA(),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Copyright
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2024 360ghar. All rights reserved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made with ❤️ for property seekers everywhere',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
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
              color: AppColors.primaryYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryYellow,
              size: 20,
            ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
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

  Widget _buildContactItem({
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
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(Icons.launch, color: AppColors.iconColor, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _launchEmail(String email) {
    // In a real app, launch email client
    Get.snackbar(
      'Email',
      'Would launch email client to: $email',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _launchPhone(String phone) {
    // In a real app, launch phone dialer
    Get.snackbar(
      'Phone',
      'Would launch dialer for: $phone',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _launchWebsite(String url) {
    // In a real app, launch web browser
    Get.snackbar(
      'Website',
      'Would launch browser to: $url',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _openTermsOfService() {
    Get.snackbar(
      'Terms of Service',
      'Terms of Service would be displayed here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _openPrivacyPolicy() {
    Get.snackbar(
      'Privacy Policy',
      'Privacy Policy would be displayed here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _openEULA() {
    Get.snackbar(
      'EULA',
      'End User License Agreement would be displayed here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }
}