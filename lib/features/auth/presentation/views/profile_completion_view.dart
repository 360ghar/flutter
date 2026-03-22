import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/features/auth/presentation/controllers/profile_completion_controller.dart';
import 'package:ghar360/features/auth/presentation/widgets/auth_premium_shell.dart';

class ProfileCompletionView extends StatelessWidget {
  const ProfileCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<ProfileCompletionController>(
      builder: (controller) {
        return Semantics(
          label: 'qa.auth.profile_completion.screen',
          identifier: 'qa.auth.profile_completion.screen',
          child: AuthPremiumShell(
            title: 'complete_your_profile'.tr,
            subtitle: '',
            chips: const [],
            footer: Semantics(
              label: 'qa.auth.profile_completion.skip',
              identifier: 'qa.auth.profile_completion.skip',
              child: TextButton(
                key: const ValueKey('qa.auth.profile_completion.skip'),
                onPressed: controller.skipToHome,
                child: Text(
                  'skip_for_now'.tr,
                  style: const TextStyle(
                    color: AppDesign.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgress(theme, controller),
                  const SizedBox(height: 24),
                  _buildStepContent(context, theme, controller),
                  const SizedBox(height: 24),
                  _buildNavigationButtons(context, controller),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgress(ThemeData theme, ProfileCompletionController controller) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (controller.currentStep.value + 1) / 2,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppDesign.primaryYellow),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              controller.currentStep.value == 0 ? 'personal_info_step'.tr : 'property_purpose'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'step_of'.trParams({'step': '${controller.currentStep.value + 1}', 'total': '2'}),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    ThemeData theme,
    ProfileCompletionController controller,
  ) {
    return Column(
      children: [
        Offstage(
          offstage: controller.currentStep.value != 0,
          child: _buildPersonalInfoStep(theme, controller),
        ),
        Offstage(
          offstage: controller.currentStep.value != 1,
          child: _buildPurposeStep(theme, controller),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(BuildContext context, ProfileCompletionController controller) {
    return Obx(() {
      return Row(
        children: [
          if (controller.currentStep.value > 0) ...[
            Expanded(
              child: OutlinedButton(onPressed: controller.previousStep, child: Text('back'.tr)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              key: const ValueKey('qa.auth.profile_completion.next_or_complete'),
              onPressed: controller.isLoading.value
                  ? null
                  : (controller.currentStep.value < 1
                        ? controller.nextStep
                        : controller.completeProfile),
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppDesignTokens.neutral900,
                      ),
                    )
                  : Text(
                      controller.currentStep.value < 1 ? 'next'.tr : 'complete'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppDesignTokens.neutral900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPersonalInfoStep(ThemeData theme, ProfileCompletionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'personal_information'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const ValueKey('qa.auth.profile_completion.full_name_input'),
          controller: controller.fullNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'full_name'.tr,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'full_name_required'.tr;
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('qa.auth.profile_completion.email_input'),
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'email_address'.tr,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
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
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('qa.auth.profile_completion.dob_input'),
          controller: controller.dateOfBirthController,
          readOnly: true,
          onTap: () => controller.selectDateOfBirth(),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'date_of_birth'.tr,
            hintText: 'dob_format_hint'.tr,
            prefixIcon: const Icon(Icons.cake_outlined),
          ),
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

  Widget _buildPurposeStep(ThemeData theme, ProfileCompletionController controller) {
    Widget buildOption({required String purpose, required IconData icon, required String label}) {
      final isSelected = controller.selectedPropertyPurpose.value == purpose;
      return Expanded(
        child: InkWell(
          key: ValueKey('qa.auth.profile_completion.purpose.$purpose'),
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
              color: isSelected ? AppDesign.primaryYellow : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppDesign.primaryYellow : Colors.white.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: isSelected ? AppDesign.textDark : Colors.white70),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppDesign.textDark : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'what_are_you_looking_for'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        const SizedBox(height: 16),
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
