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

    return Semantics(
      label: 'qa.auth.phone_entry.screen',
      identifier: 'qa.auth.phone_entry.screen',
      child: AuthPremiumShell(
        key: const ValueKey('qa.auth.phone_entry.screen'),
        title: 'auth_phone_title'.tr,
        subtitle: 'auth_phone_subtitle'.tr,
        chips: ['auth_chip_verified'.tr, 'auth_chip_transparent'.tr, 'auth_chip_support'.tr],
        footer: Text('terms_footer'.tr, textAlign: TextAlign.center),
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
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: AppDesign.overlayLight.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: Semantics(
                      label: 'qa.auth.phone_entry.phone_input',
                      identifier: 'qa.auth.phone_entry.phone_input',
                      child: TextFormField(
                        key: const ValueKey('qa.auth.phone_entry.phone_input'),
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
                        style: const TextStyle(
                          color: AppDesign.overlayLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'phone_hint'.tr,
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('india_flag'.tr, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  'india_code'.tr,
                                  style: const TextStyle(
                                    color: AppDesign.overlayLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  width: 1,
                                  height: 24,
                                  color: AppDesign.overlayLight.withValues(alpha: 0.25),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              Obx(() => AuthInlineError(message: controller.errorMessage.value)),
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: Obx(
                  () => Semantics(
                    label: 'qa.auth.phone_entry.continue',
                    identifier: 'qa.auth.phone_entry.continue',
                    child: FilledButton(
                      key: const ValueKey('qa.auth.phone_entry.continue'),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Color(0xFF8C6B52),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'checking_account'.tr,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF8C6B52),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'continue_btn'.tr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8C6B52),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
