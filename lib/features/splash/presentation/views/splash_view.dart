import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/features/splash/presentation/controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final slides = _onboardingSlides;

    return Scaffold(
      backgroundColor: AppDesign.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppDesign.primaryYellow.withValues(alpha: 0.12),
                      AppDesign.background,
                      AppDesign.accentBlue.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            PageView.builder(
              controller: controller.pageController,
              itemCount: slides.length,
              onPageChanged: (index) => controller.currentStep.value = index,
              itemBuilder: (context, index) => _OnboardingSlideCard(
                slide: slides[index],
                fadeAnimation: controller.fadeAnimation,
                slideAnimation: controller.slideAnimation,
                scaleAnimation: controller.scaleAnimation,
              ),
            ),
            Positioned(
              top: 16,
              right: 12,
              child: TextButton(
                onPressed: controller.skipToHome,
                child: Text(
                  'skip'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppDesign.textSecondary),
                ),
              ),
            ),
            Positioned(
              bottom: 22,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppDesign.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppDesign.border),
                    boxShadow: AppDesign.getCardShadow(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Obx(() {
                      final currentStep = controller.currentStep.value;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(slides.length, (index) {
                              final selected = index == currentStep;
                              return AnimatedContainer(
                                duration: AppDurations.fast,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 8,
                                width: selected ? 30 : 8,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppDesign.primaryYellow
                                      : AppDesign.border.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              if (currentStep > 0)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: controller.previousStep,
                                    icon: const Icon(Icons.arrow_back, size: 18),
                                    label: Text('back'.tr),
                                  ),
                                )
                              else
                                const Spacer(),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed: controller.nextStep,
                                  icon: Icon(
                                    currentStep < slides.length - 1
                                        ? Icons.arrow_forward
                                        : Icons.check_circle_outline,
                                  ),
                                  label: Text(
                                    currentStep < slides.length - 1 ? 'next'.tr : 'get_started'.tr,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_OnboardingSlideModel> get _onboardingSlides => const [
    _OnboardingSlideModel(
      icon: Icons.threesixty,
      titleKey: 'onboarding_slide_1_title',
      descriptionKey: 'onboarding_slide_1_desc',
      points: [
        'onboarding_slide_1_point_1',
        'onboarding_slide_1_point_2',
        'onboarding_slide_1_point_3',
      ],
      accentColor: AppDesignTokens.brandGold,
      chipLabelKey: 'onboarding_chip_live_tours',
    ),
    _OnboardingSlideModel(
      icon: Icons.verified_user_outlined,
      titleKey: 'onboarding_slide_2_title',
      descriptionKey: 'onboarding_slide_2_desc',
      points: [
        'onboarding_slide_2_point_1',
        'onboarding_slide_2_point_2',
        'onboarding_slide_2_point_3',
      ],
      accentColor: AppDesignTokens.accentBlue,
      chipLabelKey: 'onboarding_chip_verified',
    ),
    _OnboardingSlideModel(
      icon: Icons.handshake_outlined,
      titleKey: 'onboarding_slide_3_title',
      descriptionKey: 'onboarding_slide_3_desc',
      points: [
        'onboarding_slide_3_point_1',
        'onboarding_slide_3_point_2',
        'onboarding_slide_3_point_3',
      ],
      accentColor: AppDesignTokens.accentGreen,
      chipLabelKey: 'onboarding_chip_support',
    ),
  ];
}

class _OnboardingSlideCard extends StatelessWidget {
  const _OnboardingSlideCard({
    required this.slide,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.scaleAnimation,
  });

  final _OnboardingSlideModel slide;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 150),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScaleTransition(
                scale: scaleAnimation,
                child: _HeroOrb(
                  icon: slide.icon,
                  accentColor: slide.accentColor,
                  chipLabel: slide.chipLabelKey.tr,
                ),
              ),
              const SizedBox(height: 34),
              Text(
                slide.titleKey.tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: AppDesign.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                slide.descriptionKey.tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: AppDesign.textSecondary),
              ),
              const SizedBox(height: 26),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppDesign.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppDesign.border),
                  boxShadow: AppDesign.getCardShadow(),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: slide.points
                        .map(
                          (point) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: slide.accentColor.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check, size: 14, color: slide.accentColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    point.tr,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppDesign.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
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

class _HeroOrb extends StatelessWidget {
  const _HeroOrb({required this.icon, required this.accentColor, required this.chipLabel});

  final IconData icon;
  final Color accentColor;
  final String chipLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accentColor.withValues(alpha: 0.35), accentColor.withValues(alpha: 0.05)],
              ),
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: AppDesign.surface,
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 2),
              boxShadow: AppDesign.getCardShadow(),
            ),
            child: Icon(icon, size: 62, color: accentColor),
          ),
          Positioned(top: 24, right: 40, child: _GlintDot(color: accentColor)),
          const Positioned(bottom: 30, left: 40, child: _GlintDot(color: AppDesign.primaryYellow)),
          Positioned(
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppDesign.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppDesign.border),
              ),
              child: Text(
                chipLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppDesign.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlintDot extends StatelessWidget {
  const _GlintDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
        ],
      ),
    );
  }
}

class _OnboardingSlideModel {
  const _OnboardingSlideModel({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.points,
    required this.accentColor,
    required this.chipLabelKey,
  });

  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final List<String> points;
  final Color accentColor;
  final String chipLabelKey;
}
