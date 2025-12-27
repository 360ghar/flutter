// lib/features/auth/views/phone_entry_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/utils/theme.dart';
import 'package:ghar360/core/widgets/common/shake_widget.dart';
import 'package:ghar360/features/auth/controllers/phone_entry_controller.dart';

class PhoneEntryView extends GetView<PhoneEntryController> {
  const PhoneEntryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppTheme.darkBackground, AppTheme.darkSurface]
                : [AppTheme.backgroundWhite, AppTheme.backgroundGray],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // App Logo with Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryYellow.withValues(alpha: 0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.home_rounded, size: 60, color: AppTheme.textDark),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Welcome Text with Fade Animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'welcome_to_app'.tr,
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'enter_mobile_to_continue'.tr,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Phone Input Field
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Obx(() {
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
                                    ? AppTheme.primaryYellow.withValues(alpha: isDark ? 0.22 : 0.18)
                                    : (isDark
                                          ? AppTheme.darkShadow
                                          : AppTheme.cardShadow.withValues(alpha: 0.1)),
                                blurRadius: isFocused ? 28 : 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: controller.phoneController,
                            focusNode: controller.phoneFocusNode,
                            autofocus: true,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              hintText: 'phone_hint'.tr,
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      '+91',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    Container(
                                      height: 24,
                                      width: 1,
                                      margin: const EdgeInsets.only(left: AppSpacing.md - 4),
                                      color: colorScheme.outline.withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                              ),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkCard : AppTheme.backgroundWhite,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryYellow,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.error, width: 1),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.error, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.lg,
                              ),
                              errorStyle: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: controller.validatePhone,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) {
                              if (controller.errorMessage.value.isNotEmpty) {
                                controller.errorMessage.value = '';
                              }
                            },
                            onFieldSubmitted: (_) => controller.checkAndNavigate(),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Error Message
                  Obx(() {
                    if (controller.errorMessage.value.isEmpty) {
                      return const SizedBox(height: 20);
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            controller.errorMessage.value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Continue Button
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 40 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  controller.checkAndNavigate();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryYellow,
                            foregroundColor: AppTheme.textDark,
                            disabledBackgroundColor: AppTheme.primaryYellow.withValues(alpha: 0.6),
                            elevation: 0,
                            shadowColor: AppTheme.primaryYellow.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: controller.isLoading.value
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: AppTheme.textDark,
                                        strokeWidth: 2.5,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'checking_account'.tr,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'continue_btn'.tr,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Footer Text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'terms_footer'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
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
