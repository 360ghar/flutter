import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:ghar360/features/auth/presentation/widgets/auth_premium_shell.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final step = controller.currentStep.value;
      final title = step == 0
          ? 'reset_password'.tr
          : step == 1
          ? 'verify_otp'.tr
          : 'set_new_password'.tr;

      return Semantics(
        label: 'qa.auth.forgot_password.screen',
        identifier: 'qa.auth.forgot_password.screen',
        child: AuthPremiumShell(
          key: const ValueKey('qa.auth.forgot_password.screen'),
          title: title,
          subtitle: '',
          onBack: step == 0
              ? () => Get.offNamed(AppRoutes.login)
              : () => controller.goBackToStep(step - 1),
          chips: ['auth_chip_private'.tr, 'auth_chip_secure'.tr],
          footer: step == 0
              ? TextButton(
                  onPressed: () => Get.offNamed(AppRoutes.login),
                  child: Text(
                    'back_to_login'.tr,
                    style: const TextStyle(
                      color: AppDesign.primaryYellow,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (step == 0) _buildPhoneStep(theme),
              if (step == 1) _buildOtpStep(theme),
              if (step == 2) _buildPasswordStep(theme),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPhoneStep(ThemeData theme) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'reset_password_subtitle'.tr,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Semantics(
            label: 'qa.auth.forgot_password.phone_input',
            identifier: 'qa.auth.forgot_password.phone_input',
            child: TextFormField(
              key: const ValueKey('qa.auth.forgot_password.phone_input'),
              controller: controller.phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]'))],
              decoration: InputDecoration(
                labelText: 'phone_number'.tr,
                hintText: 'phone_hint'.tr,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                final raw = (value ?? '').trim();
                if (raw.isEmpty) {
                  return 'phone_required'.tr;
                }
                final cleaned = raw.replaceAll(RegExp(r'\s+'), '');
                final tenDigits = RegExp(r'^[0-9]{10}$');
                final e164IN = RegExp(r'^\+91[0-9]{10}$');
                if (!(tenDigits.hasMatch(cleaned) || e164IN.hasMatch(cleaned))) {
                  return 'phone_invalid'.tr;
                }
                return null;
              },
            ),
          ),
          Obx(() => AuthInlineError(message: controller.errorMessage.value)),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: Obx(
              () => Semantics(
                label: 'qa.auth.forgot_password.send_otp',
                identifier: 'qa.auth.forgot_password.send_otp',
                child: FilledButton(
                  key: const ValueKey('qa.auth.forgot_password.send_otp'),
                  onPressed: controller.isLoading.value ? null : controller.sendResetOtp,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF8C6B52),
                          ),
                        )
                      : const Text(
                          'Send OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8C6B52),
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'enter_otp_subtitle'.tr,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Semantics(
          label: 'qa.auth.forgot_password.otp_input',
          identifier: 'qa.auth.forgot_password.otp_input',
          child: TextFormField(
            key: const ValueKey('qa.auth.forgot_password.otp_input'),
            controller: controller.otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'enter_otp'.tr,
              hintText: '000000',
              counterText: '',
              prefixIcon: const Icon(Icons.security),
            ),
          ),
        ),
        Obx(() => AuthInlineError(message: controller.errorMessage.value)),
        const SizedBox(height: 18),
        SizedBox(
          height: 56,
          child: Obx(
            () => Semantics(
              label: 'qa.auth.forgot_password.verify_otp',
              identifier: 'qa.auth.forgot_password.verify_otp',
              child: FilledButton(
                key: const ValueKey('qa.auth.forgot_password.verify_otp'),
                onPressed: controller.isLoading.value ? null : controller.verifyResetOtp,
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF8C6B52),
                        ),
                      )
                    : Text(
                        'verify_otp'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8C6B52),
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => TextButton(
            onPressed: controller.canResendOtp.value ? controller.resendOtp : null,
            style: TextButton.styleFrom(
              foregroundColor: controller.canResendOtp.value
                  ? AppDesign.primaryYellow
                  : Colors.white38,
            ),
            child: Text(
              controller.canResendOtp.value
                  ? 'resend_code'.tr
                  : '${'resend_in'.tr} ${controller.otpCountdown.value}s',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'choose_new_password'.tr,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Obx(
          () => Semantics(
            label: 'qa.auth.forgot_password.new_password_input',
            identifier: 'qa.auth.forgot_password.new_password_input',
            child: TextFormField(
              key: const ValueKey('qa.auth.forgot_password.new_password_input'),
              controller: controller.newPasswordController,
              obscureText: !controller.isPasswordVisible.value,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'new_password'.tr,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: controller.togglePasswordVisibility,
                  icon: Icon(
                    controller.isPasswordVisible.value ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Obx(
          () => Semantics(
            label: 'qa.auth.forgot_password.confirm_password_input',
            identifier: 'qa.auth.forgot_password.confirm_password_input',
            child: TextFormField(
              key: const ValueKey('qa.auth.forgot_password.confirm_password_input'),
              controller: controller.confirmPasswordController,
              obscureText: !controller.isConfirmPasswordVisible.value,
              style: const TextStyle(color: Colors.white),
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
            ),
          ),
        ),
        Obx(() => AuthInlineError(message: controller.errorMessage.value)),
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: Obx(
            () => Semantics(
              label: 'qa.auth.forgot_password.update_password',
              identifier: 'qa.auth.forgot_password.update_password',
              child: FilledButton(
                key: const ValueKey('qa.auth.forgot_password.update_password'),
                onPressed: controller.isLoading.value ? null : controller.updatePassword,
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF8C6B52),
                        ),
                      )
                    : Text(
                        'update_password'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF8C6B52),
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
