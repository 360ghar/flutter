import 'dart:async';
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

  // Timer management for cancellable operations
  Timer? _autoAdvanceTimer;
  Timer? _navigationTimer;
  Timer? _animationTimer;
  Timer? _authDelayTimer;
  Timer? _profileWaitTimer;

  // Disposal state tracking
  bool _isDisposed = false;

  // Animations
  late Animation<double> fadeAnimation;
  late Animation<Offset> slideAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> rotationAnimation;

  // Page controller for smooth transitions
  late PageController pageController;

  // Auto-advance timer
  int autoAdvanceSeconds = 4;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
  }

  @override
  void onReady() {
    super.onReady();
    // Start auto-advance after the view is ready and PageController is attached
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
    ).animate(CurvedAnimation(parent: fadeController, curve: Curves.easeInOut));

    slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: slideController, curve: Curves.elasticOut),
        );

    scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: scaleController, curve: Curves.bounceOut),
    );

    rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: rotationController, curve: Curves.linear),
    );

    // Initialize page controller
    pageController = PageController();

    // Start initial animations after a brief delay to ensure proper initialization
    _animationTimer = Timer(const Duration(milliseconds: 50), () {
      if (!_isDisposed) {
        _startStepAnimations();
      }
    });
  }

  void _startStepAnimations() {
    if (_isDisposed) return;

    try {
      fadeController.forward();
      slideController.forward();
      scaleController.forward();
      rotationController.repeat();
    } catch (e, stackTrace) {
      DebugLogger.error('Error starting step animations', e, stackTrace);
    }
  }

  void _startAutoAdvance() {
    // Cancel any existing timer
    _autoAdvanceTimer?.cancel();

    // Create cancellable timer
    _autoAdvanceTimer = Timer(Duration(seconds: autoAdvanceSeconds), () {
      if (!_isDisposed) {
        nextStep();
      }
    });
  }

  void nextStep() {
    if (_isDisposed) return;

    if (currentStep.value < 3) {
      currentStep.value++;
      _animateToStep(currentStep.value);
      _resetAndStartAnimations();
      _startAutoAdvance();
    } else {
      // Check authentication status after splash
      _navigationTimer?.cancel();
      _navigationTimer = Timer(const Duration(milliseconds: 500), () {
        if (!_isDisposed) {
          _checkAuthenticationAndNavigate();
        }
      });
    }
  }

  void previousStep() {
    if (_isDisposed) return;

    if (currentStep.value > 0) {
      currentStep.value--;
      _animateToStep(currentStep.value);
      _resetAndStartAnimations();
    }
  }

  void goToStep(int step) {
    if (_isDisposed) return;

    if (step >= 0 && step <= 3) {
      currentStep.value = step;
      _animateToStep(step);
      _resetAndStartAnimations();
    }
  }

  void _animateToStep(int step) {
    if (_isDisposed) return;

    // Check if PageController is attached to a PageView before animating
    if (pageController.hasClients) {
      try {
        pageController.animateToPage(
          step,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e, stackTrace) {
        DebugLogger.error('Error animating to step $step', e, stackTrace);
      }
    } else {
      DebugLogger.warning(
        'PageController not attached to PageView, skipping animation',
      );
      // Retry after a short delay if PageController not ready
      Timer(const Duration(milliseconds: 100), () {
        if (!_isDisposed && pageController.hasClients) {
          try {
            pageController.animateToPage(
              step,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } catch (e, stackTrace) {
            DebugLogger.error(
              'Error animating to step $step after retry',
              e,
              stackTrace,
            );
          }
        }
      });
    }
  }

  void _resetAndStartAnimations() {
    if (_isDisposed) return;

    try {
      fadeController.reset();
      slideController.reset();
      scaleController.reset();
    } catch (e, stackTrace) {
      DebugLogger.error('Error resetting animations', e, stackTrace);
      return;
    }

    _animationTimer?.cancel();
    _animationTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isDisposed) {
        _startStepAnimations();
      }
    });
  }

  void skipToHome() {
    if (_isDisposed) return;
    _checkAuthenticationAndNavigate();
  }

  bool _hasNavigated = false;

  void _checkAuthenticationAndNavigate() async {
    // Prevent multiple navigation attempts or disposed state
    if (_hasNavigated || _isDisposed) return;
    _hasNavigated = true;

    try {
      // Check if AuthController is available
      if (!Get.isRegistered<AuthController>()) {
        DebugLogger.warning(
          'AuthController not registered, going to onboarding',
        );
        Get.offAllNamed(AppRoutes.onboarding);
        return;
      }

      final authController = Get.find<AuthController>();

      // Wait for auth controller initialization to complete
      final completer = Completer<void>();
      _authDelayTimer?.cancel();
      _authDelayTimer = Timer(const Duration(milliseconds: 500), () {
        if (!_isDisposed) {
          completer.complete();
        }
      });
      await completer.future;

      // Check current authentication status (no need to restore session manually)
      // The AuthController already handles session restoration in onInit
      if (authController.isAuthenticated) {
        final currentUser = authController.currentUser.value;

        // Check if user profile is loaded and complete
        if (currentUser != null) {
          if (_isProfileComplete(currentUser)) {
            // Profile is complete, go to dashboard (middleware will handle auth check)
            Get.offAllNamed(AppRoutes.dashboard);
          } else {
            // Need to complete profile
            Get.offAllNamed(AppRoutes.profileCompletion);
          }
        } else {
          // User is authenticated but profile not loaded, wait a bit
          final profileCompleter = Completer<void>();
          _profileWaitTimer?.cancel();
          _profileWaitTimer = Timer(const Duration(milliseconds: 1000), () {
            if (!_isDisposed) {
              profileCompleter.complete();
            }
          });
          await profileCompleter.future;

          if (!_isDisposed) {
            if (authController.currentUser.value != null) {
              Get.offAllNamed(AppRoutes.dashboard);
            } else {
              // Profile loading failed, might need to complete profile
              Get.offAllNamed(AppRoutes.profileCompletion);
            }
          }
        }
      } else {
        // User not authenticated, show onboarding
        Get.offAllNamed(AppRoutes.onboarding);
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Error during splash navigation', e, stackTrace);
      // On any error, go to onboarding
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }

  /// Checks if user profile is complete enough to access the main app
  bool _isProfileComplete(dynamic user) {
    if (user == null) return false;

    // Basic checks for profile completion
    try {
      final hasBasicInfo =
          user.name?.isNotEmpty == true && user.email?.isNotEmpty == true;

      // You can add more specific checks here based on your requirements
      return hasBasicInfo;
    } catch (e, stackTrace) {
      DebugLogger.error('Error checking profile completion', e, stackTrace);
      return false;
    }
  }

  @override
  void onClose() {
    // Mark as disposed to prevent any further operations
    _isDisposed = true;

    try {
      // Cancel all timers
      _autoAdvanceTimer?.cancel();
      _navigationTimer?.cancel();
      _animationTimer?.cancel();
      _authDelayTimer?.cancel();
      _profileWaitTimer?.cancel();

      // Clear timer references
      _autoAdvanceTimer = null;
      _navigationTimer = null;
      _animationTimer = null;
      _authDelayTimer = null;
      _profileWaitTimer = null;

      // Stop animation controllers before disposal
      if (rotationController.isAnimating) {
        rotationController.stop();
      }

      // Dispose animation controllers safely
      fadeController.dispose();
      slideController.dispose();
      scaleController.dispose();
      rotationController.dispose();
      pageController.dispose();

      DebugLogger.info('SplashController properly disposed');
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Error during SplashController disposal',
        e,
        stackTrace,
      );
    } finally {
      super.onClose();
    }
  }
}
