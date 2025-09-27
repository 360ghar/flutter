import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_completion_controller.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/theme.dart';

class ProfileCompletionView extends StatelessWidget {
  const ProfileCompletionView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileCompletionController>(
      builder: (controller) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: controller.formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),

                      // Header
                      Text(
                        'complete_your_profile'.tr,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'personalize_experience_subtitle'.tr,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Progress Indicator (2 steps)
                      LinearProgressIndicator(
                        value: (controller.currentStep.value + 1) / 2,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Step ${controller.currentStep.value + 1} of 2',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Step Content
                      _buildStepContent(controller),

                      const SizedBox(height: 32),

                      // Navigation Buttons
                      _buildNavigationButtons(context, controller),

                      const SizedBox(height: 16),

                      // Skip Button
                      TextButton(
                        onPressed: controller.skipToHome,
                        child: Text('skip_for_now'.tr, style: const TextStyle(color: Colors.grey)),
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
    switch (controller.currentStep.value) {
      case 0:
        return _buildPersonalInfoStep(controller);
      case 1:
        return _buildPurposeStep(controller);
      default:
        return _buildPersonalInfoStep(controller);
    }
  }

  Widget _buildNavigationButtons(BuildContext context, ProfileCompletionController controller) {
    return Row(
      children: [
        if (controller.currentStep.value > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: controller.previousStep,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text('back'.tr),
            ),
          ),
        if (controller.currentStep.value > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed:
                controller.isLoading.value
                    ? null
                    : (controller.currentStep.value < 1
                        ? controller.nextStep
                        : controller.completeProfile),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primaryYellow,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child:
                controller.isLoading.value
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoStep(ProfileCompletionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'personal_information'.tr,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Full Name
        TextFormField(
          controller: controller.fullNameController,
          decoration: InputDecoration(
            labelText: 'full_name'.tr,
            prefixIcon: const Icon(Icons.person_outline),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // Email (for profile, not for auth)
        TextFormField(
          controller: controller.emailController,
          decoration: InputDecoration(
            labelText: 'email_address'.tr,
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        // Date of Birth
        TextFormField(
          controller: controller.dateOfBirthController,
          decoration: InputDecoration(
            labelText: 'date_of_birth'.tr,
            prefixIcon: const Icon(Icons.cake_outlined),
            border: const OutlineInputBorder(),
            hintText: 'dob_format_hint'.tr,
          ),
          readOnly: true,
          onTap: () => controller.selectDateOfBirth(),
        ),
      ],
    );
  }

  Widget _buildPurposeStep(ProfileCompletionController controller) {
    final theme = Get.context!.theme;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final selectedBg = AppTheme.primaryColor;
    final selectedFg = AppTheme.textDark;

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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            height: 110,
            decoration: BoxDecoration(
              color:
                  isSelected ? selectedBg : (isDark ? AppTheme.darkCard : AppTheme.backgroundWhite),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isSelected
                        ? AppTheme.primaryYellowDark
                        : (isDark ? AppTheme.darkBorder : AppTheme.cardShadow),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? AppTheme.darkShadow : AppTheme.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
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
