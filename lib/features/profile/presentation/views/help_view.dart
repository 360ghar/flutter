import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/mixins/theme_mixin.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_toast.dart';

class HelpView extends StatelessWidget with ThemeMixin {
  const HelpView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'help'.tr,
      body: Semantics(
        label: 'qa.profile.help.screen',
        identifier: 'qa.profile.help.screen',
        child: SingleChildScrollView(
          key: const ValueKey('qa.profile.help.screen'),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Actions
              buildThemeAwareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle('help_quick_actions'.tr),
                    const SizedBox(height: 16),
                    _buildQuickAction(
                      icon: Icons.chat_bubble_outline,
                      title: 'help_chat_with_support_title'.tr,
                      description: 'help_chat_with_support_desc'.tr,
                      onTap: () => _startLiveChat(),
                    ),
                    _buildQuickAction(
                      icon: Icons.call,
                      title: 'help_request_callback_title'.tr,
                      description: 'help_request_callback_desc'.tr,
                      onTap: () => _requestCallback(),
                    ),
                    _buildQuickAction(
                      icon: Icons.email_outlined,
                      title: 'help_email_support_title'.tr,
                      description: 'help_email_support_desc'.tr,
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
                    buildSectionTitle('help_faq_title'.tr),
                    const SizedBox(height: 16),
                    _buildFAQItem(question: 'help_faq_q1'.tr, answer: 'help_faq_a1'.tr),
                    _buildFAQItem(question: 'help_faq_q2'.tr, answer: 'help_faq_a2'.tr),
                    _buildFAQItem(question: 'help_faq_q3'.tr, answer: 'help_faq_a3'.tr),
                    _buildFAQItem(question: 'help_faq_q4'.tr, answer: 'help_faq_a4'.tr),
                    _buildFAQItem(question: 'help_faq_q5'.tr, answer: 'help_faq_a5'.tr),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Troubleshooting
              buildThemeAwareCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSectionTitle('help_troubleshooting_title'.tr),
                    const SizedBox(height: 16),
                    _buildTroubleshootItem(
                      title: 'help_troubleshoot_slow_title'.tr,
                      solutions: [
                        'help_troubleshoot_slow_s1'.tr,
                        'help_troubleshoot_slow_s2'.tr,
                        'help_troubleshoot_slow_s3'.tr,
                        'help_troubleshoot_slow_s4'.tr,
                      ],
                    ),
                    _buildTroubleshootItem(
                      title: 'help_troubleshoot_cards_title'.tr,
                      solutions: [
                        'help_troubleshoot_cards_s1'.tr,
                        'help_troubleshoot_cards_s2'.tr,
                        'help_troubleshoot_cards_s3'.tr,
                        'help_troubleshoot_cards_s4'.tr,
                      ],
                    ),
                    _buildTroubleshootItem(
                      title: 'help_troubleshoot_notifications_title'.tr,
                      solutions: [
                        'help_troubleshoot_notifications_s1'.tr,
                        'help_troubleshoot_notifications_s2'.tr,
                        'help_troubleshoot_notifications_s3'.tr,
                        'help_troubleshoot_notifications_s4'.tr,
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
                    buildSectionTitle('help_guides_title'.tr),
                    const SizedBox(height: 16),
                    _buildGuideItem(
                      icon: Icons.play_circle_outline,
                      title: 'help_guide_get_started_title'.tr,
                      description: 'help_guide_get_started_desc'.tr,
                      onTap: () => _openGuide('getting-started'),
                    ),
                    _buildGuideItem(
                      icon: Icons.map_outlined,
                      title: 'help_guide_search_title'.tr,
                      description: 'help_guide_search_desc'.tr,
                      onTap: () => _openGuide('advanced-search'),
                    ),
                    _buildGuideItem(
                      icon: Icons.tune,
                      title: 'help_guide_preferences_title'.tr,
                      description: 'help_guide_preferences_desc'.tr,
                      onTap: () => _openGuide('preferences'),
                    ),
                    _buildGuideItem(
                      icon: Icons.event_available,
                      title: 'help_guide_visits_title'.tr,
                      description: 'help_guide_visits_desc'.tr,
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
                    buildSectionTitle('help_contact_info_title'.tr),
                    const SizedBox(height: 16),
                    _buildContactInfo(
                      icon: Icons.access_time,
                      title: 'help_contact_support_hours_title'.tr,
                      details: 'help_contact_support_hours_details'.tr,
                    ),
                    _buildContactInfo(
                      icon: Icons.location_on,
                      title: 'help_contact_office_title'.tr,
                      details: 'help_contact_office_details'.tr,
                    ),
                    _buildContactInfo(
                      icon: Icons.language,
                      title: 'help_contact_languages_title'.tr,
                      details: 'help_contact_languages_details'.tr,
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
                    buildSectionTitle('help_feedback_title'.tr),
                    const SizedBox(height: 16),
                    Text(
                      'help_feedback_body'.tr,
                      style: TextStyle(fontSize: 16, color: AppDesign.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        label: 'qa.profile.help.send_feedback',
                        identifier: 'qa.profile.help.send_feedback',
                        child: ElevatedButton(
                          key: const ValueKey('qa.profile.help.send_feedback'),
                          onPressed: () => _sendFeedback(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesign.buttonBackground,
                            foregroundColor: AppDesign.buttonText,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'send_feedback'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          color: AppDesign.primaryYellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppDesign.primaryYellow, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppDesign.textPrimary),
      ),
      subtitle: Text(description, style: TextStyle(fontSize: 14, color: AppDesign.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: AppDesign.iconColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppDesign.textPrimary),
      ),
      iconColor: AppDesign.iconColor,
      collapsedIconColor: AppDesign.iconColor,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(fontSize: 14, color: AppDesign.textSecondary, height: 1.5),
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
              color: AppDesign.textPrimary,
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
                    decoration: const BoxDecoration(
                      color: AppDesign.primaryYellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      solution,
                      style: TextStyle(fontSize: 14, color: AppDesign.textSecondary, height: 1.4),
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
      leading: Icon(icon, color: AppDesign.iconColor),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppDesign.textPrimary),
      ),
      subtitle: Text(description, style: TextStyle(fontSize: 14, color: AppDesign.textSecondary)),
      trailing: Icon(Icons.chevron_right, color: AppDesign.iconColor),
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
          Icon(icon, color: AppDesign.iconColor),
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
                  details,
                  style: TextStyle(fontSize: 14, color: AppDesign.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startLiveChat() {
    AppToast.info('help_live_chat_title'.tr, 'help_live_chat_message'.tr);
  }

  void _requestCallback() {
    AppToast.info('help_callback_title'.tr, 'help_callback_message'.tr);
  }

  // void _callSupport() {
  //   Get.snackbar(
  //     'Call Support',
  //     'Would launch phone dialer for support',
  //     backgroundColor: AppDesign.snackbarBackground,
  //     colorText: AppDesign.snackbarText,
  //   );
  // }

  void _emailSupport() {
    AppToast.info('help_email_title'.tr, 'help_email_message'.tr);
  }

  void _openGuide(String guideId) {
    AppToast.info('help_guide_title'.tr, 'help_guide_message'.trParams({'guideId': guideId}));
  }

  Future<void> _sendFeedback() async {
    await Get.toNamed(AppRoutes.feedback);
  }
}
