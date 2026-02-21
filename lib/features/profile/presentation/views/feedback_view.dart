import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/bug_report_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/mixins/theme_mixin.dart';
import 'package:ghar360/features/profile/presentation/controllers/feedback_controller.dart';

class FeedbackView extends GetView<FeedbackController> with ThemeMixin {
  const FeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    return buildThemeAwareScaffold(
      title: 'send_feedback'.tr,
      body: Semantics(
        label: 'qa.profile.feedback.screen',
        identifier: 'qa.profile.feedback.screen',
        child: KeyedSubtree(
          key: const ValueKey('qa.profile.feedback.screen'),
          child: Form(
            key: controller.formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'feedback_subtitle'.tr,
                    style: TextStyle(fontSize: 16, height: 1.5, color: AppDesign.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('issue_type'.tr),
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
                  _buildSectionTitle('severity_label'.tr),
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
                  _buildSectionTitle('title_label'.tr),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controller.titleController,
                    hintText: 'title_hint'.tr,
                    qaKey: 'qa.profile.feedback.title_input',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'title_validation'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('what_happened'.tr),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controller.descriptionController,
                    hintText: 'description_hint'.tr,
                    qaKey: 'qa.profile.feedback.description_input',
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'description_validation'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('steps_to_reproduce'.tr),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controller.stepsController,
                    hintText: 'steps_hint'.tr,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('expected_behaviour'.tr),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controller.expectedController,
                    hintText: 'expected_hint'.tr,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('actual_behaviour'.tr),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controller.actualController,
                    hintText: 'actual_hint'.tr,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('tags_optional'.tr),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: controller.tagsController,
                    hintText: 'tags_hint'.tr,
                    helperText: 'tags_helper'.tr,
                  ),
                  const SizedBox(height: 28),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: Semantics(
                        label: 'qa.profile.feedback.submit',
                        identifier: 'qa.profile.feedback.submit',
                        child: ElevatedButton(
                          key: const ValueKey('qa.profile.feedback.submit'),
                          onPressed: controller.isSubmitting.value
                              ? null
                              : controller.submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppDesign.buttonBackground,
                            foregroundColor: AppDesign.buttonText,
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
                                        color: AppDesign.buttonText,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'sending_feedback'.tr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppDesign.textPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? qaKey,
    String? helperText,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Semantics(
      label: qaKey,
      identifier: qaKey,
      child: TextFormField(
        key: qaKey != null ? ValueKey(qaKey) : null,
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        minLines: maxLines > 1 ? 3 : 1,
        style: TextStyle(color: AppDesign.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          helperText: helperText,
          helperStyle: TextStyle(color: AppDesign.textSecondary),
          hintStyle: TextStyle(color: AppDesign.textSecondary),
          filled: true,
          fillColor: AppDesign.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppDesign.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppDesign.primaryYellow, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppDesign.errorRed),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppDesign.errorRed, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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
        fillColor: AppDesign.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppDesign.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppDesign.primaryYellow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppDesign.iconColor),
      dropdownColor: AppDesign.cardBackground,
      style: TextStyle(color: AppDesign.textPrimary, fontSize: 15),
      items: items
          .map((item) => DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))))
          .toList(),
    );
  }

  String _bugTypeLabel(BugType type) {
    switch (type) {
      case BugType.uiBug:
        return 'bug_type_ui'.tr;
      case BugType.functionalityBug:
        return 'bug_type_functionality'.tr;
      case BugType.performanceIssue:
        return 'bug_type_performance'.tr;
      case BugType.crash:
        return 'bug_type_crash'.tr;
      case BugType.featureRequest:
        return 'bug_type_feature'.tr;
      case BugType.other:
        return 'bug_type_other'.tr;
    }
  }

  String _severityLabel(BugSeverity severity) {
    switch (severity) {
      case BugSeverity.low:
        return 'severity_low'.tr;
      case BugSeverity.medium:
        return 'severity_medium'.tr;
      case BugSeverity.high:
        return 'severity_high'.tr;
      case BugSeverity.critical:
        return 'severity_critical'.tr;
    }
  }
}
