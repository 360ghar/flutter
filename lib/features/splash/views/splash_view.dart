import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../core/utils/theme.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryYellow.withValues(alpha: 0.1),
                    AppTheme.backgroundWhite,
                    AppTheme.accentBlue.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),

            // Main content
            PageView(
              controller: controller.pageController,
              onPageChanged: (index) => controller.currentStep.value = index,
              children: [
                _buildStep1(context),
                _buildStep2(context),
                _buildStep3(context),
                _buildStep4(context),
              ],
            ),

            // Skip button
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: controller.skipToHome,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Bottom navigation indicators and controls
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Page indicators
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: controller.currentStep.value == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: controller.currentStep.value == index
                                ? AppTheme.primaryYellow
                                : AppTheme.textLight.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Previous button
                          controller.currentStep.value > 0
                              ? TextButton.icon(
                                  onPressed: controller.previousStep,
                                  icon: const Icon(Icons.arrow_back),
                                  label: const Text('Back'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.textGray,
                                  ),
                                )
                              : const SizedBox(width: 80),

                          // Next/Get Started button
                          ElevatedButton(
                            onPressed: controller.nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryYellow,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              controller.currentStep.value < 3
                                  ? 'Next'
                                  : 'Get Started',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: 360° Virtual Tours
  Widget _buildStep1(BuildContext context) {
    return FadeTransition(
      opacity: controller.fadeAnimation,
      child: SlideTransition(
        position: controller.slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 360° Tour Animation
              ScaleTransition(
                scale: controller.scaleAnimation,
                child: _build360TourIllustration(),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'Experience 360° Virtual Tours',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                'Step inside every property from anywhere. Our immersive 360° tours let you explore homes as if you were there, saving time and making better decisions.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGray,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feature highlights
              _buildFeatureHighlights([
                'Immersive 360° Views',
                'High-Quality Images',
                'Interactive Navigation',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // Step 2: Virtual Tours Convenience
  Widget _buildStep2(BuildContext context) {
    return FadeTransition(
      opacity: controller.fadeAnimation,
      child: SlideTransition(
        position: controller.slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Virtual Tours Animation
              ScaleTransition(
                scale: controller.scaleAnimation,
                child: _buildVirtualToursIllustration(),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'Tour at Your Convenience',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                'Visit properties 24/7 from the comfort of your home. No scheduling conflicts, no travel time – just instant access to your dream homes.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGray,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feature highlights
              _buildFeatureHighlights([
                '24/7 Availability',
                'No Travel Required',
                'Instant Access',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // Step 3: Verified Listings
  Widget _buildStep3(BuildContext context) {
    return FadeTransition(
      opacity: controller.fadeAnimation,
      child: SlideTransition(
        position: controller.slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Verified Listings Animation
              ScaleTransition(
                scale: controller.scaleAnimation,
                child: _buildVerifiedListingIllustration(),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'Verified & Authentic Listings',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                'Every property is thoroughly verified by our team. Real photos, accurate details, and authentic information – no fake listings, guaranteed.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGray,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feature highlights
              _buildFeatureHighlights([
                'Thoroughly Verified',
                'Authentic Photos',
                'Accurate Details',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  // Step 4: Low Brokerage Complete Service
  Widget _buildStep4(BuildContext context) {
    return FadeTransition(
      opacity: controller.fadeAnimation,
      child: SlideTransition(
        position: controller.slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Low Brokerage Animation
              ScaleTransition(
                scale: controller.scaleAnimation,
                child: _buildLowBrokerageIllustration(),
              ),

              const SizedBox(height: 48),

              // Title
              Text(
                'Low Brokerage, Complete Service',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Description
              Text(
                'Save thousands with our transparent, low brokerage fees while getting full-service support. Expert guidance, legal assistance, and end-to-end support.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGray,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Feature highlights
              _buildFeatureHighlights([
                'Transparent Pricing',
                'Expert Guidance',
                'End-to-End Support',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights(List<String> features) {
    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.successGreen,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                feature,
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 360° Tour Illustration
  Widget _build360TourIllustration() {
    return RotationTransition(
      turns: controller.rotationAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                width: 3,
              ),
            ),
          ),
          // Center house icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryYellow,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.home_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          // 360° text
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '360°',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Virtual Tours Illustration
  Widget _buildVirtualToursIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Phone mockup
        Container(
          width: 160,
          height: 280,
          decoration: BoxDecoration(
            color: AppTheme.textDark,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Screen
              Positioned(
                top: 20,
                left: 12,
                right: 12,
                bottom: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Property image
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.apartment,
                            size: 40,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ),
                      // Play button for virtual tour
                      Positioned(
                        top: 60,
                        left: 55,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryYellow,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Floating convenience icons
        Positioned(
          top: 50,
          right: 20,
          child: _buildFloatingIcon(Icons.access_time, AppTheme.accentGreen),
        ),
        Positioned(
          bottom: 80,
          left: 20,
          child: _buildFloatingIcon(Icons.location_on, AppTheme.accentOrange),
        ),
        Positioned(
          top: 120,
          left: 30,
          child: _buildFloatingIcon(Icons.home_work, AppTheme.accentBlue),
        ),
      ],
    );
  }

  // Verified Listing Illustration
  Widget _buildVerifiedListingIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Document background
        Container(
          width: 220,
          height: 280,
          decoration: BoxDecoration(
            color: AppTheme.backgroundWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Property image placeholder
              Container(
                height: 95,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 30, color: AppTheme.textGray),
                ),
              ),
              const SizedBox(height: 14),
              // Property details with checkmarks
              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successGreen,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundGray,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        // Verified badge
        Positioned(
          top: -10,
          right: -10,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.successGreen,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.successGreen.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 30),
          ),
        ),
      ],
    );
  }

  // Low Brokerage Illustration
  Widget _buildLowBrokerageIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Money illustration
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.successGreen.withValues(alpha: 0.1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Central money icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.successGreen,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.successGreen.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.attach_money,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              // Percentage badge
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LOW %',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Service icons around the circle
        ...List.generate(6, (index) {
          final icons = [
            Icons.support_agent,
            Icons.verified_user,
            Icons.handshake,
            Icons.schedule,
            Icons.security,
            Icons.thumb_up,
          ];

          return Positioned(
            left: 100 + 100 * (index % 2 == 0 ? 1 : -1),
            top: 100 + 30 * (index - 2.5),
            child: _buildFloatingIcon(icons[index], AppTheme.accentBlue),
          );
        }),
      ],
    );
  }

  Widget _buildFloatingIcon(IconData icon, Color color) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}
