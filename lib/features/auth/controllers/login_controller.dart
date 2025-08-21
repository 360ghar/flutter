import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/debug_logger.dart';

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
    // Early guard to prevent double submissions
    if (isLoading.value) return;

    // Null-safe form validation
    if (!(formKey.currentState?.validate() ?? false)) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      DebugLogger.auth('Attempting login for: ${emailController.text.trim()}');

      final success = await authController.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (success) {
        DebugLogger.success('Login controller: Authentication successful');
        // AuthController will handle navigation and JWT token logging
        ErrorHandler.showSuccess('welcome_back'.tr);
      } else {
        DebugLogger.warning('Login controller: Authentication failed');
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Login controller error', e, stackTrace);
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

      DebugLogger.auth('Attempting Google sign-in...');

      final success = await authController.signInWithGoogle();
      
      if (success) {
        DebugLogger.success('Google sign-in successful');
        ErrorHandler.showSuccess('signed_in_with_google'.tr);
      } else {
        DebugLogger.warning('Google sign-in failed');
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Google sign-in error', e, stackTrace);
      errorMessage.value = e.toString();
      ErrorHandler.handleAuthError(e, onRetry: signInWithGoogle);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) {
      ErrorHandler.handleValidationError('email'.tr, 'enter_email_first'.tr);
      return;
    }

    try {
      isLoading.value = true;
      
      DebugLogger.auth('Attempting password reset for: ${emailController.text.trim()}');
      
      final success = await authController.resetPassword(emailController.text.trim());
      
      if (success) {
        DebugLogger.success('Password reset email sent');
        ErrorHandler.showSuccess('password_reset_email_sent'.tr);
      } else {
        DebugLogger.warning('Password reset failed');
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Password reset error', e, stackTrace);
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