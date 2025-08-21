import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/mixins/theme_mixin.dart';

class HelpView extends StatelessWidget with ThemeMixin {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'Help & Support',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 16),
                  _buildQuickAction(
                    icon: Icons.chat_bubble_outline,
                    title: 'Live Chat',
                    description: 'Chat with our support team',
                    onTap: () => _startLiveChat(),
                  ),
                  _buildQuickAction(
                    icon: Icons.phone,
                    title: 'Call Support',
                    description: '+1 (555) 123-4567',
                    onTap: () => _callSupport(),
                  ),
                  _buildQuickAction(
                    icon: Icons.email,
                    title: 'Email Support',
                    description: 'support@360ghar.com',
                    onTap: () => _emailSupport(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Frequently Asked Questions
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Frequently Asked Questions'),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    question: 'How do I search for properties?',
                    answer: 'Use the swipe interface on the home screen to browse properties. You can also use the search filters to narrow down your options.',
                  ),
                  _buildFAQItem(
                    question: 'How do I save my favorite properties?',
                    answer: 'Tap the heart icon on any property card or swipe right to add it to your favorites. You can view all saved properties in the Favorites tab.',
                  ),
                  _buildFAQItem(
                    question: 'How do I schedule a property visit?',
                    answer: 'Go to the property details page and tap "Schedule Visit" or contact the agent directly using the provided contact information.',
                  ),
                  _buildFAQItem(
                    question: 'How do I change my location preferences?',
                    answer: 'Go to Profile > Preferences and update your preferred location and search radius.',
                  ),
                  _buildFAQItem(
                    question: 'How do I enable/disable notifications?',
                    answer: 'Go to Profile > Notifications to customize your notification preferences.',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Troubleshooting
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Troubleshooting'),
                  const SizedBox(height: 16),
                  _buildTroubleshootItem(
                    title: 'App is running slowly',
                    solutions: [
                      'Close other apps running in the background',
                      'Restart the app',
                      'Check your internet connection',
                      'Clear app cache in device settings',
                    ],
                  ),
                  _buildTroubleshootItem(
                    title: 'Properties not loading',
                    solutions: [
                      'Check your internet connection',
                      'Try refreshing the page',
                      'Update your location permissions',
                      'Restart the app',
                    ],
                  ),
                  _buildTroubleshootItem(
                    title: 'Can\'t receive notifications',
                    solutions: [
                      'Check notification permissions in device settings',
                      'Verify notification preferences in the app',
                      'Ensure the app is not in battery optimization mode',
                      'Restart your device',
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Guides & Tutorials
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Guides & Tutorials'),
                  const SizedBox(height: 16),
                  _buildGuideItem(
                    icon: Icons.play_circle_outline,
                    title: 'Getting Started Guide',
                    description: 'Learn the basics of using 360ghar',
                    onTap: () => _openGuide('getting-started'),
                  ),
                  _buildGuideItem(
                    icon: Icons.search,
                    title: 'Advanced Search Tips',
                    description: 'Master the search and filter features',
                    onTap: () => _openGuide('advanced-search'),
                  ),
                  _buildGuideItem(
                    icon: Icons.favorite,
                    title: 'Managing Favorites',
                    description: 'Organize your saved properties',
                    onTap: () => _openGuide('favorites'),
                  ),
                  _buildGuideItem(
                    icon: Icons.notifications,
                    title: 'Notification Settings',
                    description: 'Customize your alerts and updates',
                    onTap: () => _openGuide('notifications'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Contact Information
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Contact Information'),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    icon: Icons.access_time,
                    title: 'Support Hours',
                    details: 'Monday - Friday: 9:00 AM - 6:00 PM\nSaturday: 10:00 AM - 4:00 PM\nSunday: Closed',
                  ),
                  _buildContactInfo(
                    icon: Icons.location_on,
                    title: 'Office Address',
                    details: '123 Real Estate Plaza\nDowntown Business District\nNew York, NY 10001',
                  ),
                  _buildContactInfo(
                    icon: Icons.language,
                    title: 'Languages Supported',
                    details: 'English, Spanish, Hindi, Mandarin',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Feedback
            buildThemeAwareCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionTitle('Feedback'),
                  const SizedBox(height: 16),
                  Text(
                    'We value your feedback! Help us improve 360ghar by sharing your thoughts and suggestions.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _sendFeedback(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBackground,
                        foregroundColor: AppColors.buttonText,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Send Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required String description,
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
        child: Icon(
          icon,
          color: AppColors.primaryYellow,
          size: 20,
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
        description,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      iconColor: AppColors.iconColor,
      collapsedIconColor: AppColors.iconColor,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootItem({
    required String title,
    required List<String> solutions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
          const SizedBox(height: 8),
          ...solutions.map((solution) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6, right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    solution,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
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
        description,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String details,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.iconColor),
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
                  details,
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

  void _startLiveChat() {
    Get.snackbar(
      'Live Chat',
      'Live chat feature would be implemented here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _callSupport() {
    Get.snackbar(
      'Call Support',
      'Would launch phone dialer for support',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _emailSupport() {
    Get.snackbar(
      'Email Support',
      'Would launch email client for support',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _openGuide(String guideId) {
    Get.snackbar(
      'Guide',
      'Would open guide: $guideId',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  void _sendFeedback() {
    Get.snackbar(
      'Feedback',
      'Feedback form would be opened here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }
}