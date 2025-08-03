import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../utils/error_handler.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  
  // Form fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Observable states
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final rememberMe = false.obs;
  final errorMessage = ''.obs;
  
  late final AuthController authController;

  @override
  void onInit() {
    super.onInit();
    authController = Get.find<AuthController>();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔐 Attempting login for: ${emailController.text.trim()}');

      final success = await authController.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (success) {
        print('✅ Login controller: Authentication successful');
        // AuthController will handle navigation and JWT token logging
        ErrorHandler.showSuccess('Welcome back!');
      } else {
        print('❌ Login controller: Authentication failed');
      }
    } catch (e) {
      print('💥 Login controller error: $e');
      errorMessage.value = e.toString();
      ErrorHandler.handleAuthError(e, onRetry: signIn);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('🔐 Attempting Google sign-in...');

      final success = await authController.signInWithGoogle();
      
      if (success) {
        print('✅ Google sign-in successful');
        ErrorHandler.showSuccess('Signed in with Google!');
      } else {
        print('❌ Google sign-in failed');
      }
    } catch (e) {
      print('💥 Google sign-in error: $e');
      errorMessage.value = e.toString();
      ErrorHandler.handleAuthError(e, onRetry: signInWithGoogle);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) {
      ErrorHandler.handleValidationError('Email', 'Please enter your email address first');
      return;
    }

    try {
      isLoading.value = true;
      
      print('🔐 Attempting password reset for: ${emailController.text.trim()}');
      
      final success = await authController.resetPassword(emailController.text.trim());
      
      if (success) {
        print('✅ Password reset email sent');
        ErrorHandler.showSuccess('Password reset email sent! Please check your inbox.');
      } else {
        print('❌ Password reset failed');
      }
    } catch (e) {
      print('💥 Password reset error: $e');
      ErrorHandler.handleAuthError(e, onRetry: resetPassword);
    } finally {
      isLoading.value = false;
    }
  }

  void goToSignup() {
    Get.offNamed(AppRoutes.register);
  }

  void clearError() {
    errorMessage.value = '';
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}