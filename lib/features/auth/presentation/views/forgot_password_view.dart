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
      final subtitle = step == 0
          ? 'reset_password_subtitle'.tr
          : step == 1
          ? 'enter_otp_subtitle'.tr
          : 'choose_new_password'.tr;

      return AuthPremiumShell(
        title: title,
        subtitle: subtitle,
        onBack: step == 0
            ? () => Get.offNamed(AppRoutes.login)
            : () => controller.goBackToStep(step - 1),
        chips: ['auth_chip_private'.tr, 'auth_chip_secure'.tr],
        footer: step == 0
            ? TextButton(
                onPressed: () => Get.offNamed(AppRoutes.login),
                child: Text('back_to_login'.tr),
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
      );
    });
  }

  Widget _buildPhoneStep(ThemeData theme) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
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
          Obx(() => AuthInlineError(message: controller.errorMessage.value)),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: Obx(
              () => FilledButton(
                onPressed: controller.isLoading.value ? null : controller.sendResetOtp,
                child: controller.isLoading.value
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Text(
                        'send_otp'.tr,
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
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: Obx(
            () => FilledButton(
              onPressed: controller.isLoading.value ? null : controller.verifyResetOtp,
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
      ],
    );
  }

  Widget _buildPasswordStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => TextFormField(
            controller: controller.newPasswordController,
            obscureText: !controller.isPasswordVisible.value,
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
        const SizedBox(height: 12),
        Obx(
          () => TextFormField(
            controller: controller.confirmPasswordController,
            obscureText: !controller.isConfirmPasswordVisible.value,
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
        Obx(() => AuthInlineError(message: controller.errorMessage.value)),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: Obx(
            () => FilledButton(
              onPressed: controller.isLoading.value ? null : controller.updatePassword,
              child: controller.isLoading.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : Text(
                      'update_password'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppDesign.buttonText,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
