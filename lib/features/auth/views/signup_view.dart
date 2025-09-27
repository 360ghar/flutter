// lib/features/auth/views/signup_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/signup_controller.dart';
import '../../../core/routes/app_routes.dart';

class SignUpView extends GetView<SignUpController> {
  const SignUpView({super.key});

  static final Uri _termsUri = Uri.parse('https://360ghar.com/policies');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            return controller.currentStep.value == 0
                ? _buildSignUpForm(context)
                : _buildOtpForm(context);
          }),
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

  Widget _buildSignUpForm(BuildContext context) {
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
              'create_account'.tr,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'signup_subtitle'.tr,
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
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            // Terms and Conditions Checkbox
            Obx(
              () => FormField<bool>(
                initialValue: controller.isTermsAccepted.value,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value != true) {
                    return 'terms_consent_required'.tr;
                  }
                  return null;
                },
                builder: (state) {
                  final isChecked = controller.isTermsAccepted.value;
                  final prefixText = 'agree_terms_prefix'.tr;
                  final suffixText = 'agree_terms_suffix'.tr;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTileTheme(
                        data: const ListTileThemeData(horizontalTitleGap: 12),
                        child: CheckboxListTile(
                          value: isChecked,
                          onChanged: (value) {
                            final accepted = value ?? false;
                            controller.isTermsAccepted.value = accepted;
                            state.didChange(accepted);
                            state.validate();
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runAlignment: WrapAlignment.center,
                            spacing: 4,
                            runSpacing: 2,
                            children: [
                              Text(prefixText, style: theme.textTheme.bodyMedium),
                              TextButton(
                                onPressed: () => _openTerms(),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'terms_and_conditions'.tr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              if (suffixText.isNotEmpty)
                                Text(suffixText, style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text(
                            state.errorText ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                          ),
                        ),
                    ],
                  );
                },
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

            // Sign Up Button
            Obx(
              () => ElevatedButton(
                onPressed: controller.isLoading.value ? null : controller.signUp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child:
                    controller.isLoading.value
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                        : Text(
                          'create_account'.tr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),

            // Login Link
            TextButton(
              onPressed: () => Get.offNamed(AppRoutes.login),
              child: Text('already_have_account'.tr),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpForm(BuildContext context) {
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
              IconButton(onPressed: controller.goBackToForm, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  'verify_phone_number'.tr,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
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

          // Verify Button
          Obx(
            () => ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.verifyOtp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child:
                  controller.isLoading.value
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
}
