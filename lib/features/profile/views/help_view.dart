import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/mixins/theme_mixin.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/app_colors.dart';

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
                    title: 'Chat with Support',
                    description: 'Start a live conversation with our help desk',
                    onTap: () => _startLiveChat(),
                  ),
                  _buildQuickAction(
                    icon: Icons.call,
                    title: 'Request a Callback',
                    description: 'Leave your number and we will reach out shortly',
                    onTap: () => _requestCallback(),
                  ),
                  _buildQuickAction(
                    icon: Icons.email_outlined,
                    title: 'Email Support',
                    description: 'support@360ghar.com (24-hour response)',
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
                    question: 'How do I find properties that match my needs?',
                    answer:
                        'Use the Discover tab to swipe through curated listings and apply filters from the Explore tab to narrow down by budget, location, and property type.',
                  ),
                  _buildFAQItem(
                    question: 'How can I tailor my recommendations?',
                    answer:
                        'Open Profile > Preferences to adjust push or email notifications and let us know if you want suggestions for similar properties.',
                  ),
                  _buildFAQItem(
                    question: 'How do I manage alerts and reminders?',
                    answer:
                        'In Profile > Preferences you can toggle push alerts and email updates any time.',
                  ),
                  _buildFAQItem(
                    question: 'How do I schedule a visit or virtual tour?',
                    answer:
                        'Go to the property details page and tap "Schedule Visit" for in-person tours or launch the 360° tour to explore remotely.',
                  ),
                  _buildFAQItem(
                    question: 'How do I change the app language or theme?',
                    answer:
                        'Profile > Preferences lets you switch between light/dark mode and choose your preferred language instantly.',
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
                    title: 'App feels slow or unresponsive',
                    solutions: [
                      'Close background apps that might be consuming memory',
                      'Make sure you are on the latest version of 360ghar',
                      'Restart the app after clearing it from recent apps',
                      'Check your internet connection strength',
                    ],
                  ),
                  _buildTroubleshootItem(
                    title: 'Property cards are not loading',
                    solutions: [
                      'Verify that location access is enabled for 360ghar',
                      'Pull to refresh on the Discover tab',
                      'Try switching between mobile data and Wi-Fi',
                      'Restart the app to trigger a fresh sync',
                    ],
                  ),
                  _buildTroubleshootItem(
                    title: 'Notifications stopped coming through',
                    solutions: [
                      'Ensure push notifications are enabled under Profile > Preferences',
                      'Allow notifications for 360ghar in your device settings',
                      'Disable battery saver or optimization for the app',
                      'Log out and sign back in to refresh your session',
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
                    title: 'Get Started with 360ghar',
                    description: 'Set up your profile and explore key features',
                    onTap: () => _openGuide('getting-started'),
                  ),
                  _buildGuideItem(
                    icon: Icons.map_outlined,
                    title: 'Mastering Property Search',
                    description: 'Use filters, maps, and 360° tours effectively',
                    onTap: () => _openGuide('advanced-search'),
                  ),
                  _buildGuideItem(
                    icon: Icons.tune,
                    title: 'Personalising Preferences',
                    description: 'Adjust language, theme, and notification options',
                    onTap: () => _openGuide('preferences'),
                  ),
                  _buildGuideItem(
                    icon: Icons.event_available,
                    title: 'Scheduling Property Visits',
                    description: 'Book in-person tours and manage appointments',
                    onTap: () => _openGuide('scheduling-visits'),
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
                    details:
                        'Monday - Saturday: 9:00 AM - 8:00 PM IST\nSunday: 10:00 AM - 2:00 PM IST',
                  ),
                  _buildContactInfo(
                    icon: Icons.location_on,
                    title: 'Office Address',
                    details: 'Gurugram, Haryana 122001',
                  ),
                  _buildContactInfo(
                    icon: Icons.language,
                    title: 'Languages Supported',
                    details: 'English, हिंदी (Hindi)',
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
                    'We read every note! Share feature requests, bug reports, or partnership ideas to help us build a better 360ghar.',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Send Feedback',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        child: Icon(icon, color: AppColors.primaryYellow, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      ),
      subtitle: Text(description, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: AppColors.iconColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      ),
      iconColor: AppColors.iconColor,
      collapsedIconColor: AppColors.iconColor,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildTroubleshootItem({required String title, required List<String> solutions}) {
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
          ...solutions.map(
            (solution) => Padding(
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
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      ),
      subtitle: Text(description, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
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
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
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

  void _requestCallback() {
    Get.snackbar(
      'Callback Request',
      'Callback form would be presented here',
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }

  // void _callSupport() {
  //   Get.snackbar(
  //     'Call Support',
  //     'Would launch phone dialer for support',
  //     backgroundColor: AppColors.snackbarBackground,
  //     colorText: AppColors.snackbarText,
  //   );
  // }

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

  Future<void> _sendFeedback() async {
    await Get.toNamed(AppRoutes.feedback);
  }
}
