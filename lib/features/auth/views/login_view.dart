// lib/features/auth/views/login_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../../core/routes/app_routes.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  const SizedBox(height: 60),

                  // Header
                  Text(
                    'welcome_back'.tr,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'sign_in_subtitle'.tr,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

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
                            controller.isPasswordVisible.value
                                ? Icons.visibility_off
                                : Icons.visibility,
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
                  const SizedBox(height: 8),

                  // Remember Me and Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(
                        () => Row(
                          children: [
                            Checkbox(
                              value: controller.rememberMe.value,
                              onChanged: (_) => controller.toggleRememberMe(),
                            ),
                            Text('remember_me'.tr),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                        child: Text('forgot_password'.tr),
                      ),
                    ],
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

                  // Sign In Button
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.isLoading.value ? null : controller.signIn,
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
                                'sign_in'.tr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Link
                  Center(
                    child: TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.signup),
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(text: 'dont_have_account'.tr),
                            TextSpan(
                              text: ' ${'sign_up'.tr}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
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
  }
}
