import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/utils/theme.dart';
import 'package:ghar360/core/widgets/common/app_text_field.dart';
import 'package:ghar360/features/auth/controllers/profile_completion_controller.dart';

class ProfileCompletionView extends StatelessWidget {
  const ProfileCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GetBuilder<ProfileCompletionController>(
      builder: (controller) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: controller.formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),

                      // Header
                      Text(
                        'complete_your_profile'.tr,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'personalize_experience_subtitle'.tr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Progress Indicator (2 steps)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppBorderRadius.round),
                        child: LinearProgressIndicator(
                          value: (controller.currentStep.value + 1) / 2,
                          backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'step_of'.trParams({
                          'step': '${controller.currentStep.value + 1}',
                          'total': '2',
                        }),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Step Content
                      _buildStepContent(controller),

                      const SizedBox(height: AppSpacing.xl),

                      // Navigation Buttons
                      _buildNavigationButtons(context, controller),

                      const SizedBox(height: AppSpacing.md),

                      // Skip Button
                      TextButton(
                        onPressed: controller.skipToHome,
                        child: Text(
                          'skip_for_now'.tr,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
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
      },
    );
  }

  Widget _buildStepContent(ProfileCompletionController controller) {
    return Column(
      children: [
        Offstage(
          offstage: controller.currentStep.value != 0,
          child: _buildPersonalInfoStep(controller),
        ),
        Offstage(offstage: controller.currentStep.value != 1, child: _buildPurposeStep(controller)),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, ProfileCompletionController controller) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (controller.currentStep.value > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: controller.previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.button),
                ),
              ),
              child: Text('back'.tr),
            ),
          ),
        if (controller.currentStep.value > 0) const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: controller.isLoading.value
                ? null
                : (controller.currentStep.value < 1
                      ? controller.nextStep
                      : controller.completeProfile),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.buttonText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.button),
              ),
            ),
            child: controller.isLoading.value
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    controller.currentStep.value < 1 ? 'next'.tr : 'complete'.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep(ProfileCompletionController controller) {
    final theme = Get.context!.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'personal_information'.tr,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.md),
        // Full Name
        AppTextField(
          controller: controller.fullNameController,
          labelText: 'full_name'.tr,
          prefixIcon: const Icon(Icons.person_outline),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'full_name_required'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Email (for profile, not for auth)
        AppTextField(
          controller: controller.emailController,
          labelText: 'email_address'.tr,
          prefixIcon: const Icon(Icons.email_outlined),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            final email = (value ?? '').trim();
            if (email.isEmpty) {
              return 'email_required'.tr;
            }
            if (!GetUtils.isEmail(email)) {
              return 'email_invalid'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        // Date of Birth
        AppTextField(
          controller: controller.dateOfBirthController,
          labelText: 'date_of_birth'.tr,
          prefixIcon: const Icon(Icons.cake_outlined),
          hintText: 'dob_format_hint'.tr,
          readOnly: true,
          onTap: () => controller.selectDateOfBirth(),
          validator: (_) {
            if (controller.selectedDateOfBirth == null) {
              return 'dob_required'.tr;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPurposeStep(ProfileCompletionController controller) {
    final theme = Get.context!.theme;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final selectedBg = theme.colorScheme.primary;
    final selectedFg = theme.colorScheme.onPrimary;

    Widget buildOption({required String purpose, required IconData icon, required String label}) {
      final isSelected = controller.selectedPropertyPurpose.value == purpose;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            controller.selectedPropertyPurpose.value = purpose;
            controller.update();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            height: 110,
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedBg
                  : (isDark ? AppTheme.darkCard : AppTheme.backgroundWhite),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primaryYellowDark : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: AppColors.shadowColor, blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: isSelected ? selectedFg : onSurface),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? selectedFg : onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('what_are_you_looking_for'.tr, style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            buildOption(purpose: 'rent', icon: Icons.key_outlined, label: 'rent'.tr),
            buildOption(purpose: 'buy', icon: Icons.home_outlined, label: 'buy'.tr),
          ],
        ),
      ],
    );
  }
}
