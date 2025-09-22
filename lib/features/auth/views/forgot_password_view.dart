// lib/features/auth/views/forgot_password_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/forgot_password_controller.dart';
import '../../../core/routes/app_routes.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            switch (controller.currentStep.value) {
              case 0:
                return _buildPhoneStep(context);
              case 1:
                return _buildOtpStep(context);
              case 2:
                return _buildNewPasswordStep(context);
              default:
                return _buildPhoneStep(context);
            }
          }),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: controller.formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),

            // Header
            Text(
              'reset_password'.tr,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'reset_password_subtitle'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Phone Field
            TextFormField(
              controller: controller.phoneController,
              decoration: InputDecoration(
                labelText: 'phone_number'.tr,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
                hintText: 'phone_hint'.tr,
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[0-9+\s]"))],
              validator: (value) {
                final raw = (value ?? '').trim();
                if (raw.isEmpty) {
                  return 'phone_required'.tr;
                }
                final cleaned = raw.replaceAll(RegExp(r"\s+"), "");
                final tenDigits = RegExp(r"^[0-9]{10}$");
                final e164IN = RegExp(r"^\+91[0-9]{10}$");
                if (!(tenDigits.hasMatch(cleaned) || e164IN.hasMatch(cleaned))) {
                  return 'phone_invalid'.tr;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Error Message
            Obx(() {
              if (controller.errorMessage.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  controller.errorMessage.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }),

            // Send OTP Button
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.sendResetOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: controller.isLoading.value
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'send_otp'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Back to Login Link
            TextButton(
              onPressed: () => Get.offNamed(AppRoutes.login),
              child: Text('back_to_login'.tr),
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

          // Back Button and Header
          Row(
            children: [
              IconButton(
                onPressed: () => controller.goBackToStep(0),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  'verify_otp'.tr,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'enter_otp_subtitle'.tr,
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
          ),
          const SizedBox(height: 16),

          // Error Message
          Obx(() {
            if (controller.errorMessage.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                controller.errorMessage.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),

          // Verify OTP Button
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.verifyResetOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: controller.isLoading.value
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'verify_otp'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
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
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // Back Button and Header
          Row(
            children: [
              IconButton(
                onPressed: () => controller.goBackToStep(1),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  'set_new_password'.tr,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'choose_new_password'.tr,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // New Password Field
          Obx(
            () => TextFormField(
              controller: controller.newPasswordController,
              decoration: InputDecoration(
                labelText: 'new_password'.tr,
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
            ),
          ),
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
            ),
          ),
          const SizedBox(height: 24),

          // Error Message
          Obx(() {
            if (controller.errorMessage.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                controller.errorMessage.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),

          // Update Password Button
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.updatePassword,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: controller.isLoading.value
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'update_password'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
