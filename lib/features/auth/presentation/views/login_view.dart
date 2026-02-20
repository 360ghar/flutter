import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/features/auth/presentation/controllers/login_controller.dart';
import 'package:ghar360/features/auth/presentation/widgets/auth_premium_shell.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppDesign.background,
      body: Stack(
        children: [
          AuthPremiumShell(
            title: 'welcome_back'.tr,
            subtitle: 'auth_login_subtitle'.tr,
            onBack: () => Get.offNamed(AppRoutes.phoneEntry),
            chips: ['auth_chip_verified'.tr, 'auth_chip_private'.tr],
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppDesign.inputBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppDesign.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppDesign.primaryYellow.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone_outlined, color: AppDesign.primaryYellow),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(
                            () => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'phone_number'.tr,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppDesign.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.prefilledPhone.value.isNotEmpty
                                      ? controller.prefilledPhone.value
                                      : '+91 ${controller.phoneController.text}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppDesign.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.offNamed(AppRoutes.phoneEntry),
                          child: Text('change'.tr),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => TextFormField(
                      controller: controller.passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => controller.signIn(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'password_required'.tr;
                        }
                        if (value.length < 6) {
                          return 'password_min_length'.tr;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'password'.tr,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: controller.togglePasswordVisibility,
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                      child: Text('forgot_password'.tr),
                    ),
                  ),
                  Obx(() => AuthInlineError(message: controller.errorMessage.value)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: Obx(
                      () => FilledButton(
                        onPressed: controller.isLoading.value ? null : controller.signIn,
                        child: controller.isLoading.value
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : Text(
                                'sign_in'.tr,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppDesign.buttonText,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Get.offNamed(AppRoutes.phoneEntry),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(text: 'dont_have_account'.tr),
                          TextSpan(
                            text: ' ${'sign_up'.tr}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppDesign.primaryYellow,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                          Text(
                            'loading'.tr,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppDesign.textPrimary,
                            ),
                          ),
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
}
