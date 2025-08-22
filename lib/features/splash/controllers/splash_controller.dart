import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/debug_logger.dart';

class SplashController extends GetxController with GetTickerProviderStateMixin {
  // Current step in the splash screen
  final currentStep = 0.obs;

  // Animation controllers
  late AnimationController fadeController;
  late AnimationController slideController;
  late AnimationController scaleController;
  late AnimationController rotationController;

  // Animations
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> rotationAnimation;

  // Page controller for smooth transitions
  late PageController pageController;

  // Auto-advance timer
  int autoAdvanceSeconds = 4;

  // --- FIX: Add flags to manage state ---
  bool _isDisposed = false;
  bool _hasNavigated = false;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
    _startAutoAdvance();
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize animations
    fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: fadeController,
      curve: Curves.easeInOut,
    ));

    slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: slideController,
      curve: Curves.elasticOut,
    ));

    scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: scaleController,
      curve: Curves.bounceOut,
    ));

    rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: rotationController,
      curve: Curves.linear,
    ));

    // Initialize page controller
    pageController = PageController();

    // Start initial animations
    _startStepAnimations();
  }

  void _startStepAnimations() {
    // --- FIX: Check if disposed before starting animations ---
    if (_isDisposed) return;
    fadeController.forward();
    slideController.forward();
    scaleController.forward();
    rotationController.repeat();
  }

  void _startAutoAdvance() {
    Future.delayed(Duration(seconds: autoAdvanceSeconds), () {
      // --- FIX: Check if disposed before advancing ---
      if (!_isDisposed) {
        nextStep();
      }
    });
  }

  void nextStep() {
    if (currentStep.value < 3) {
      currentStep.value++;
      _animateToStep(currentStep.value);
      _resetAndStartAnimations();
      _startAutoAdvance();
    } else {
      // Check authentication status after splash
      Future.delayed(const Duration(milliseconds: 500), () {
        // --- FIX: Check if disposed before navigating ---
        if (!_isDisposed) {
          _checkAuthenticationAndNavigate();
        }
      });
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      _animateToStep(currentStep.value);
      _resetAndStartAnimations();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 3) {
      currentStep.value = step;
      _animateToStep(step);
      _resetAndStartAnimations();
    }
  }

  void _animateToStep(int step) {
    // --- FIX: Check if pageController is still valid ---
    if (pageController.hasClients) {
      pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _resetAndStartAnimations() {
    // --- FIX: Check if disposed before resetting ---
    if (_isDisposed) return;
    fadeController.reset();
    slideController.reset();
    scaleController.reset();

    Future.delayed(const Duration(milliseconds: 100), () {
      // --- FIX: Check if disposed before starting animations ---
      if (!_isDisposed) {
        _startStepAnimations();
      }
    });
  }

  void skipToHome() {
    _checkAuthenticationAndNavigate();
  }

  void _checkAuthenticationAndNavigate() async {
    // Prevent multiple navigation attempts
    if (_hasNavigated) return;
    _hasNavigated = true;

    try {
      // Check if AuthController is available
      if (!Get.isRegistered<AuthController>()) {
        DebugLogger.warning('AuthController not registered, going to onboarding');
        Get.offAllNamed(AppRoutes.onboarding);
        return;
      }

      final authController = Get.find<AuthController>();

      // Wait for auth controller initialization to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Check current authentication status
      if (authController.isAuthenticated) {
        final currentUser = authController.currentUser.value;

        if (currentUser != null) {
          if (_isProfileComplete(currentUser)) {
            Get.offAllNamed(AppRoutes.dashboard);
          } else {
            Get.offAllNamed(AppRoutes.profileCompletion);
          }
        } else {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (authController.currentUser.value != null) {
            Get.offAllNamed(AppRoutes.dashboard);
          } else {
            Get.offAllNamed(AppRoutes.profileCompletion);
          }
        }
      } else {
        Get.offAllNamed(AppRoutes.onboarding);
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Error during splash navigation', e, stackTrace);
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }

  bool _isProfileComplete(dynamic user) {
    if (user == null) return false;

    try {
      final hasBasicInfo = user.name?.isNotEmpty == true &&
                          user.email?.isNotEmpty == true;
      return hasBasicInfo;
    } catch (e, stackTrace) {
      DebugLogger.error('Error checking profile completion', e, stackTrace);
      return false;
    }
  }

  @override
  void onClose() {
    // --- FIX: Set disposed flag and safely dispose controllers ---
    _isDisposed = true;
    fadeController.dispose();
    slideController.dispose();
    scaleController.dispose();
    rotationController.dispose();
    pageController.dispose();
    super.onClose();
  }
} 