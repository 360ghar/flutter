import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/models/bug_report_model.dart';
import '../../../core/mixins/theme_mixin.dart';
import '../../../core/utils/app_colors.dart';
import '../../profile/controllers/feedback_controller.dart';

class FeedbackView extends GetView<FeedbackController> with ThemeMixin {
  const FeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'send_feedback'.tr,
      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help our team fix issues faster by sharing a few details.',
                style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Issue type'),
              const SizedBox(height: 8),
              Obx(
                () => _buildDropdownField<BugType>(
                  value: controller.selectedBugType.value,
                  items: BugType.values,
                  onChanged: controller.setBugType,
                  itemLabel: _bugTypeLabel,
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Severity'),
              const SizedBox(height: 8),
              Obx(
                () => _buildDropdownField<BugSeverity>(
                  value: controller.selectedSeverity.value,
                  items: BugSeverity.values,
                  onChanged: controller.setSeverity,
                  itemLabel: _severityLabel,
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Title'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.titleController,
                hintText: 'Give a short summary (e.g. Search filters not working)',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe the issue in a short title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('What happened?'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.descriptionController,
                hintText: 'Share what you expected and what you saw',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a short description of the problem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Steps to reproduce (optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.stepsController,
                hintText: '1. Open the app\n2. Tap on ...',
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Expected behaviour (optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.expectedController,
                hintText: 'Tell us what you expected to happen',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Actual behaviour (optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.actualController,
                hintText: 'Tell us what actually happened',
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Tags (optional)'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.tagsController,
                hintText: 'login, search, ios',
                helperText: 'Separate tags using commas or new lines',
              ),
              const SizedBox(height: 28),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value ? null : controller.submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: controller.isSubmitting.value
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.buttonText,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'sending_feedback'.tr,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        : Text(
                            'send_feedback'.tr,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? helperText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 3 : 1,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        helperText: helperText,
        helperStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryYellow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.iconColor),
      dropdownColor: AppColors.cardBackground,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
      items: items
          .map((item) => DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))))
          .toList(),
    );
  }

  String _bugTypeLabel(BugType type) {
    switch (type) {
      case BugType.uiBug:
        return 'UI bug';
      case BugType.functionalityBug:
        return 'Functionality bug';
      case BugType.performanceIssue:
        return 'Performance issue';
      case BugType.crash:
        return 'App crash';
      case BugType.featureRequest:
        return 'Feature request';
      case BugType.other:
        return 'Other';
    }
  }

  String _severityLabel(BugSeverity severity) {
    switch (severity) {
      case BugSeverity.low:
        return 'Low - minor inconvenience';
      case BugSeverity.medium:
        return 'Medium - impacts experience';
      case BugSeverity.high:
        return 'High - major issue';
      case BugSeverity.critical:
        return 'Critical - blocking issue';
    }
  }
}
