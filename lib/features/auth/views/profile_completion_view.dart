import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_completion_controller.dart';
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
                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us personalize your property search experience',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.grey,
                            ),
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Step Content
                      _buildStepContent(controller),
                      
                      const SizedBox(height: 32),
                      
                      // Navigation Buttons
                      _buildNavigationButtons(controller),
                      
                      const SizedBox(height: 16),
                      
                      // Skip Button
                      TextButton(
                        onPressed: controller.skipToHome,
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(color: Colors.grey),
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
    switch (controller.currentStep.value) {
      case 0:
        return _buildPersonalInfoStep(controller);
      case 1:
        return _buildPurposeStep(controller);
      default:
        return _buildPersonalInfoStep(controller);
    }
  }

  Widget _buildNavigationButtons(ProfileCompletionController controller) {
    return Row(
      children: [
        if (controller.currentStep.value > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: controller.previousStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Back'),
            ),
          ),
        if (controller.currentStep.value > 0) const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: controller.isLoading.value 
                ? null 
                : (controller.currentStep.value < 1 
                    ? controller.nextStep 
                    : controller.completeProfile),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    controller.currentStep.value < 1 ? 'Next' : 'Complete',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Full Name
        TextFormField(
          controller: controller.fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // Email (for profile, not for auth)
        TextFormField(
          controller: controller.emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        // Gender
        DropdownButtonFormField<String>(
          value: controller.selectedGender.value.isEmpty
              ? null
              : controller.selectedGender.value,
          decoration: const InputDecoration(
            labelText: 'Gender',
            prefixIcon: Icon(Icons.wc_outlined),
            border: OutlineInputBorder(),
          ),
          items: controller.genders
              .map((g) => DropdownMenuItem<String>(
                    value: g,
                    child: Text(g.capitalize ?? g),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              controller.selectedGender.value = val;
              controller.update();
            }
          },
        ),
        const SizedBox(height: 16),
        // Date of Birth
        TextFormField(
          controller: controller.dateOfBirthController,
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Icon(Icons.cake_outlined),
            border: OutlineInputBorder(),
            hintText: 'DD/MM/YYYY',
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
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final selectedBg = AppTheme.primaryColor;
    final selectedFg = AppTheme.textDark;

    Widget buildOption({
      required String purpose,
      required IconData icon,
      required String label,
    }) {
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
              color: isSelected
                  ? selectedBg
                  : (isDark ? AppTheme.darkCard : AppTheme.backgroundWhite),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryYellowDark
                    : (isDark ? AppTheme.darkBorder : AppTheme.cardShadow),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppTheme.darkShadow
                      : AppTheme.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 28,
                  color: isSelected ? selectedFg : onSurface,
                ),
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
        Text(
          'What are you looking for?',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            buildOption(
              purpose: 'rent',
              icon: Icons.key_outlined,
              label: 'Rent',
            ),
            buildOption(
              purpose: 'buy',
              icon: Icons.home_outlined,
              label: 'Buy',
            ),
          ],
        ),
      ],
    );
  }
}
