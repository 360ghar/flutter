import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/features/auth/presentation/controllers/signup_controller.dart';
import 'package:ghar360/features/auth/presentation/widgets/auth_premium_shell.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpView extends GetView<SignUpController> {
  const SignUpView({super.key});

  static final Uri _termsUri = Uri.parse('https://360ghar.com/policies');

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppDesign.background,
      body: Stack(
        children: [
          Obx(() {
            final step = controller.currentStep.value;
            final title = step == 0
                ? 'create_account'.tr
                : step == 1
                ? 'auth_signup_security_title'.tr
                : 'verify_phone_number'.tr;
            final subtitle = step == 0
                ? 'auth_signup_personal_subtitle'.tr
                : step == 1
                ? 'auth_signup_security_subtitle'.tr
                : 'otp_verification_subtitle'.tr;

            return AuthPremiumShell(
              title: title,
              subtitle: subtitle,
              chips: const [],
              onBack: step == 0
                  ? () => Get.offNamed(AppRoutes.phoneEntry)
                  : controller.previousStep,
              footer: step == 0
                  ? TextButton(
                      onPressed: () => Get.offNamed(AppRoutes.phoneEntry),
                      child: Text('already_have_account'.tr),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProgress(theme),
                  const SizedBox(height: 16),
                  if (step == 0) _buildPersonalStep(theme),
                  if (step == 1) _buildSecurityStep(theme),
                  if (step == 2) _buildOtpStep(theme),
                ],
              ),
            );
          }),
          Obx(() {
            if (!authController.isAuthResolving.value) {
              return const SizedBox.shrink();
            }
            return Positioned.fill(
              child: Stack(
                children: [
                  ModalBarrier(
                    dismissible: false,
                    color: AppDesign.surface.withValues(alpha: 0.66),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: BoxDecoration(
                        color: AppDesign.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppDesign.border),
                        boxShadow: AppDesign.getCardShadow(),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const SizedBox(height: 10),
                          Text('loading'.tr, style: theme.textTheme.titleSmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgress(ThemeData theme) {
    return Obx(() {
      final step = controller.currentStep.value;
      final progress = (step + 1) / 3;

      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppDesign.border.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(AppDesign.primaryYellow),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                step == 0
                    ? 'personal_info_step'.tr
                    : step == 1
                    ? 'security_step'.tr
                    : 'verify_step'.tr,
                style: theme.textTheme.labelLarge?.copyWith(color: AppDesign.textSecondary),
              ),
              Text(
                'step_of'.tr.replaceAll('@step', '${step + 1}').replaceAll('@total', '3'),
                style: theme.textTheme.bodySmall?.copyWith(color: AppDesign.textTertiary),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildPersonalStep(ThemeData theme) {
    return Form(
      key: controller.personalInfoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final hasPrefilledPhone = controller.prefilledPhone.value.isNotEmpty;
            if (!hasPrefilledPhone) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppDesign.inputBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppDesign.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppDesign.primaryYellow.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_outlined, color: AppDesign.primaryYellow),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      controller.prefilledPhone.value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppDesign.textPrimary,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.offNamed(AppRoutes.phoneEntry),
                    child: Text('change'.tr),
                  ),
                ],
              ),
            );
          }),
          TextFormField(
            controller: controller.fullNameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'full_name'.tr,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'full_name_required'.tr;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'email_address'.tr,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
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
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.dateOfBirthController,
            readOnly: true,
            onTap: controller.selectDateOfBirth,
            decoration: InputDecoration(
              labelText: 'date_of_birth'.tr,
              hintText: 'dob_format_hint'.tr,
              prefixIcon: const Icon(Icons.cake_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'dob_required'.tr;
              }
              return null;
            },
          ),
          Obx(() => AuthInlineError(message: controller.errorMessage.value)),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: controller.nextStep,
              child: Text(
                'next'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppDesign.buttonText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep(ThemeData theme) {
    return Form(
      key: controller.securityFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(
            () => TextFormField(
              controller: controller.passwordController,
              obscureText: !controller.isPasswordVisible.value,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'password'.tr,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: controller.togglePasswordVisibility,
                  icon: Icon(
                    controller.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
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
          const SizedBox(height: 8),
          Obx(() => _PasswordStrengthBar(strength: controller.passwordStrength.value)),
          const SizedBox(height: 12),
          Obx(
            () => TextFormField(
              controller: controller.confirmPasswordController,
              obscureText: !controller.isConfirmPasswordVisible.value,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'confirm_password'.tr,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: controller.toggleConfirmPasswordVisibility,
                  icon: Icon(
                    controller.isConfirmPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),
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
          const SizedBox(height: 10),
          Obx(
            () => CheckboxListTile(
              value: controller.isTermsAccepted.value,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) => controller.isTermsAccepted.value = value ?? false,
              title: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Text('agree_terms_prefix'.tr),
                  GestureDetector(
                    onTap: _openTerms,
                    child: Text(
                      'terms_and_conditions'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppDesign.primaryYellow,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  if ('agree_terms_suffix'.tr.isNotEmpty) Text('agree_terms_suffix'.tr),
                ],
              ),
            ),
          ),
          Obx(() => AuthInlineError(message: controller.errorMessage.value)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: controller.previousStep, child: Text('back'.tr)),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Obx(
                  () => FilledButton(
                    onPressed: controller.isLoading.value ? null : controller.nextStep,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : Text(
                            'create_account'.tr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppDesign.buttonText,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller.otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'enter_otp'.tr,
            hintText: '000000',
            prefixIcon: const Icon(Icons.security),
          ),
        ),
        Obx(() => AuthInlineError(message: controller.errorMessage.value)),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: Obx(
            () => FilledButton(
              onPressed: controller.isLoading.value ? null : controller.verifyOtp,
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Text(
                      'verify_otp'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppDesign.buttonText,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
        OutlinedButton(onPressed: controller.goBackToForm, child: Text('back'.tr)),
      ],
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
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    if (strength == 0) {
      return const SizedBox.shrink();
    }

    late Color color;
    late String text;
    late double value;

    switch (strength) {
      case 1:
        color = AppDesign.errorRed;
        text = 'password_strength_weak'.tr;
        value = 0.33;
        break;
      case 2:
        color = AppDesign.warningAmber;
        text = 'password_strength_medium'.tr;
        value = 0.66;
        break;
      default:
        color = AppDesign.successGreen;
        text = 'password_strength_strong'.tr;
        value = 1.0;
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppDesign.border.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}
