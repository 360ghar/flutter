// lib/features/auth/views/signup_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/theme.dart';
import 'package:ghar360/features/auth/controllers/signup_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpView extends GetView<SignUpController> {
  const SignUpView({super.key});

  static final Uri _termsUri = Uri.parse('https://360ghar.com/policies');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Obx(() {
              final step = controller.currentStep.value;
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: step < 2 ? (step + 1) / 3 : 1.0,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
                    minHeight: 4,
                  ),
                  if (step < 2)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            step == 0 ? 'personal_info_step'.tr : 'security_step'.tr,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'step_of'.tr
                                .replaceAll('@step', '${step + 1}')
                                .replaceAll('@total', '3'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Obx(() {
                  final step = controller.currentStep.value;
                  if (step == 0) {
                    return _buildPersonalInfoStep(context);
                  } else if (step == 1) {
                    return _buildSecurityStep(context);
                  } else {
                    return _buildOtpStep(context);
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTerms() async {
    try {
      final launched = await launchUrl(_termsUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        Get.snackbar('error'.tr, 'unable_to_open_link'.tr);
      }
    } catch (_) {
      Get.snackbar('error'.tr, 'unable_to_open_link'.tr);
    }
  }

  Widget _buildPersonalInfoStep(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Form(
      key: controller.personalInfoFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // Header
            Text(
              'create_account'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'tell_us_about_yourself'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Phone Display (Read-only)
            Obx(() {
              final hasPrefilledPhone = controller.prefilledPhone.value.isNotEmpty;
              if (hasPrefilledPhone) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          color: AppTheme.primaryYellow,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'phone_number'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.prefilledPhone.value,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.offNamed(AppRoutes.phoneEntry),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            color: AppTheme.primaryYellow,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Full Name
            TextFormField(
              controller: controller.fullNameController,
              decoration: InputDecoration(
                labelText: 'full_name'.tr,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'full_name_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: controller.emailController,
              decoration: InputDecoration(
                labelText: 'email_address'.tr,
                prefixIcon: const Icon(Icons.email_outlined),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'email_required'.tr;
                }
                if (!GetUtils.isEmail(value.trim())) {
                  return 'email_invalid'.tr;
                }
                return null;
              },
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
              onTap: controller.selectDateOfBirth,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'dob_required'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Error Message
            Obx(() {
              if (controller.errorMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Next Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: controller.nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: AppTheme.textDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'next'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Back to Login
            Center(
              child: TextButton(
                onPressed: () => Get.offNamed(AppRoutes.phoneEntry),
                child: Text('already_have_account'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStep(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: controller.securityFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // Header
            Text(
              'create_password'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'secure_your_account'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Password Field
            Obx(
              () => TextFormField(
                controller: controller.passwordController,
                decoration: InputDecoration(
                  labelText: 'password'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: controller.togglePasswordVisibility,
                    icon: Icon(
                      controller.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !controller.isPasswordVisible.value,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'password_required'.tr;
                  }
                  if (value.length < 6) {
                    return 'password_min_length'.tr;
                  }
                  return null;
                },
              ),
            ),

            // Password Strength Indicator
            const SizedBox(height: 8),
            Obx(() {
              final strength = controller.passwordStrength.value;
              if (strength == 0) return const SizedBox(height: 8);

              Color strengthColor;
              String strengthText;
              double strengthValue;

              switch (strength) {
                case 1:
                  strengthColor = AppTheme.errorRed;
                  strengthText = 'password_strength_weak'.tr;
                  strengthValue = 0.33;
                  break;
                case 2:
                  strengthColor = AppTheme.warningAmber;
                  strengthText = 'password_strength_medium'.tr;
                  strengthValue = 0.66;
                  break;
                case 3:
                  strengthColor = AppTheme.successGreen;
                  strengthText = 'password_strength_strong'.tr;
                  strengthValue = 1.0;
                  break;
                default:
                  return const SizedBox(height: 8);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: strengthValue,
                          backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        strengthText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: strengthColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),

            const SizedBox(height: 16),

            // Confirm Password Field
            Obx(
              () => TextFormField(
                controller: controller.confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'confirm_password'.tr,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: controller.toggleConfirmPasswordVisibility,
                    icon: Icon(
                      controller.isConfirmPasswordVisible.value
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !controller.isConfirmPasswordVisible.value,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'confirm_password_required'.tr;
                  }
                  if (value != controller.passwordController.text) {
                    return 'passwords_dont_match'.tr;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),

            // Terms and Conditions Checkbox
            Obx(
              () => CheckboxListTile(
                value: controller.isTermsAccepted.value,
                onChanged: (value) {
                  controller.isTermsAccepted.value = value ?? false;
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text('agree_terms_prefix'.tr, style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: _openTerms,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'terms_and_conditions'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryYellow,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Error Message
            Obx(() {
              if (controller.errorMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.errorMessage.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.previousStep,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('back'.tr),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value ? null : controller.nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryYellow,
                        foregroundColor: AppTheme.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: AppTheme.textDark,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'create_account'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpStep(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Header
          Text(
            'verify_phone_number'.tr,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'otp_verification_subtitle'.tr,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // OTP Field
          TextFormField(
            controller: controller.otpController,
            decoration: InputDecoration(
              labelText: 'enter_otp'.tr,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.security),
              hintText: '000000',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, letterSpacing: 2),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          // Error Message
          Obx(() {
            if (controller.errorMessage.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    controller.errorMessage.value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Verify Button
          SizedBox(
            height: 56,
            child: Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: AppTheme.textDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: AppTheme.textDark,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'verify_otp'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Resend OTP Button
          Obx(
            () => TextButton(
              onPressed: controller.canResendOtp.value ? controller.resendOtp : null,
              child: Text(
                controller.canResendOtp.value
                    ? 'resend_code'.tr
                    : '${'resend_in'.tr} ${controller.otpCountdown.value}s',
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Back Button
          OutlinedButton(
            onPressed: controller.goBackToForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('back'.tr),
          ),
        ],
      ),
    );
  }
}
