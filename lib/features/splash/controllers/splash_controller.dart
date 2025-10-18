// lib/features/splash/controllers/splash_controller.dart

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/routes/app_routes.dart';

class SplashController extends GetxController with GetTickerProviderStateMixin {
  // The splash controller is now only responsible for splash screen animations,
  // not navigation. All navigation logic is handled by the Root widget.

  late PageController pageController;
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> rotationAnimation;

  final RxInt currentStep = 0.obs;
  final GetStorage _storage = GetStorage();

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    pageController = PageController();
  }

  void _initializeAnimations() {
    animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeOutCubic));

    scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeOutBack));

    rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    animationController.forward();
  }

  void nextStep() {
    if (currentStep.value < 3) {
      currentStep.value++;
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboardingAndNavigate();
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      pageController.animateToPage(
        currentStep.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skipToHome() {
    _completeOnboardingAndNavigate();
  }

  void _completeOnboardingAndNavigate() {
    try {
      _storage.write('has_seen_onboarding', true);
    } catch (_) {}

    // Route based on auth status
    try {
      final auth = Get.find<AuthController>();
      if (auth.isAuthenticated) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    } catch (_) {
      // Fallback to login
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    pageController.dispose();
    super.onClose();
  }
}
