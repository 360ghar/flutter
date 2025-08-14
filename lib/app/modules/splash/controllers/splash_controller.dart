import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/debug_logger.dart';

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
    fadeController.forward();
    slideController.forward();
    scaleController.forward();
    rotationController.repeat();
  }
  
  void _startAutoAdvance() {
    Future.delayed(Duration(seconds: autoAdvanceSeconds), () {
      nextStep();
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
        _checkAuthenticationAndNavigate();
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
    pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  void _resetAndStartAnimations() {
    fadeController.reset();
    slideController.reset();
    scaleController.reset();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _startStepAnimations();
    });
  }
  
  void skipToHome() {
    _checkAuthenticationAndNavigate();
  }

  bool _hasNavigated = false;

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
          await Future.delayed(const Duration(milliseconds: 1000));
          if (authController.currentUser.value != null) {
            Get.offAllNamed(AppRoutes.dashboard);
          } else {
            // Profile loading failed, might need to complete profile
            Get.offAllNamed(AppRoutes.profileCompletion);
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
      final hasBasicInfo = user.name?.isNotEmpty == true && 
                          user.email?.isNotEmpty == true;
      
      // You can add more specific checks here based on your requirements
      return hasBasicInfo;
    } catch (e, stackTrace) {
      DebugLogger.error('Error checking profile completion', e, stackTrace);
      return false;
    }
  }
  
  @override
  void onClose() {
    fadeController.dispose();
    slideController.dispose();
    scaleController.dispose();
    rotationController.dispose();
    pageController.dispose();
    super.onClose();
  }
} 