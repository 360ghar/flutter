import 'package:get/get.dart';
import 'package:flutter/material.dart';

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
      // Navigate to home after the last step
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.offAllNamed('/home');
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
    Get.offAllNamed('/home');
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