import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/widgets/common/shake_widget.dart';
import 'package:ghar360/features/auth/presentation/controllers/phone_entry_controller.dart';
import 'package:ghar360/features/auth/presentation/widgets/auth_premium_shell.dart';

class PhoneEntryView extends GetView<PhoneEntryController> {
  const PhoneEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthPremiumShell(
      title: 'auth_phone_title'.tr,
      subtitle: 'auth_phone_subtitle'.tr,
      chips: ['auth_chip_verified'.tr, 'auth_chip_transparent'.tr, 'auth_chip_support'.tr],
      footer: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          'terms_footer'.tr,
          style: theme.textTheme.bodySmall?.copyWith(color: AppDesign.textTertiary),
          textAlign: TextAlign.center,
        ),
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              final isFocused = controller.isPhoneFocused.value;
              final shakeTrigger = controller.validationShakeTrigger.value;

              return ShakeWidget(
                trigger: shakeTrigger,
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isFocused
                            ? AppDesign.primaryYellow.withValues(alpha: 0.22)
                            : AppDesign.shadowColor.withValues(alpha: 0.14),
                        blurRadius: isFocused ? 26 : 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: controller.phoneController,
                    focusNode: controller.phoneFocusNode,
                    autofocus: true,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: controller.validatePhone,
                    onFieldSubmitted: (_) => controller.checkAndNavigate(),
                    decoration: InputDecoration(
                      hintText: 'phone_hint'.tr,
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🇮🇳', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 8),
                            Text(
                              '+91',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppDesign.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(left: 10),
                              width: 1,
                              height: 24,
                              color: AppDesign.border,
                            ),
                          ],
                        ),
                      ),
                    ),
                    style: theme.textTheme.titleLarge?.copyWith(
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
            Obx(() => AuthInlineError(message: controller.errorMessage.value)),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: Obx(
                () => FilledButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          HapticFeedback.mediumImpact();
                          controller.checkAndNavigate();
                        },
                  child: controller.isLoading.value
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'checking_account'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'continue_btn'.tr,
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
      ),
    );
  }
}
