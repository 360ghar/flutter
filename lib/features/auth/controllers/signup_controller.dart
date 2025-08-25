import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/debug_logger.dart';

class SignupController extends GetxController {
  final formKey = GlobalKey<FormState>();
  
  // Form fields
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final fullNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Observable states
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final currentStep = 0.obs; // 0: signup form, 1: email OTP, 2: phone OTP
  final errorMessage = ''.obs;
  
  // OTP related
  final emailOtpController = TextEditingController();
  final phoneOtpController = TextEditingController();
  final canResendEmailOtp = false.obs;
  final canResendPhoneOtp = false.obs;
  final emailOtpCountdown = 0.obs;
  final phoneOtpCountdown = 0.obs;
  
  final _supabase = Supabase.instance.client;
  late final AuthController authController;

  @override
  void onInit() {
    super.onInit();
    authController = Get.find<AuthController>();
    _startOtpTimers();
  }

  void _startOtpTimers() {
    // Email OTP timer
    ever(emailOtpCountdown, (int count) {
      if (count <= 0) {
        canResendEmailOtp.value = true;
      }
    });
    
    // Phone OTP timer
    ever(phoneOtpCountdown, (int count) {
      if (count <= 0) {
        canResendPhoneOtp.value = true;
      }
    });
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Create account with Supabase
      final response = await _supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'full_name': fullNameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );

      if (response.user != null) {
        // Move to email verification step
        currentStep.value = 1;
        _startEmailOtpCountdown();
        
        ErrorHandler.showSuccess('Verification email sent! Please check your inbox.');
      } else {
        throw Exception('Failed to create account');
      }
    } catch (e, stackTrace) {
      errorMessage.value = _getErrorMessage(e);
      ErrorHandler.handleAuthError(e, onRetry: signUp);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmailOtp() async {
    if (emailOtpController.text.length != 6) {
      ErrorHandler.handleValidationError('OTP', 'Please enter a valid 6-digit OTP');
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _supabase.auth.verifyOTP(
        email: emailController.text.trim(),
        token: emailOtpController.text,
        type: OtpType.signup,
      );

      if (response.user != null) {
        // Email verified, now verify phone
        currentStep.value = 2;
        await _sendPhoneOtp();
        _startPhoneOtpCountdown();
      } else {
        throw Exception('Invalid OTP');
      }
    } catch (e, stackTrace) {
      errorMessage.value = _getErrorMessage(e);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _sendPhoneOtp() async {
    try {
      // Send OTP to phone using Supabase
      await _supabase.auth.signInWithOtp(
        phone: phoneController.text.trim(),
      );
      
      Get.snackbar(
        'Success',
        'OTP sent to your phone number',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      DebugLogger.error('Phone OTP error', e, stackTrace);
      // For now, we'll skip phone verification if it fails
      await _completeSignup();
    }
  }

  Future<void> verifyPhoneOtp() async {
    if (phoneOtpController.text.length != 6) {
      Get.snackbar(
        'Error',
        'Please enter a valid 6-digit OTP',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _supabase.auth.verifyOTP(
        phone: phoneController.text.trim(),
        token: phoneOtpController.text,
        type: OtpType.sms,
      );

      if (response.user != null) {
        await _completeSignup();
      } else {
        throw Exception('Invalid phone OTP');
      }
    } catch (e, stackTrace) {
      errorMessage.value = _getErrorMessage(e);
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _completeSignup() async {
    try {
      // Sync user profile with backend
      await authController.refreshUserProfile();
      
      Get.snackbar(
        'Success',
        'Account created successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate to home or profile completion
      if (authController.currentUser.value != null) {
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.offAllNamed(AppRoutes.profileCompletion);
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Profile sync error', e, stackTrace);
      // Still go to profile completion even if sync fails
      Get.offAllNamed(AppRoutes.profileCompletion);
    }
  }

  Future<void> skipPhoneVerification() async {
    await _completeSignup();
  }

  Future<void> resendEmailOtp() async {
    if (!canResendEmailOtp.value) return;

    try {
      isLoading.value = true;
      
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: emailController.text.trim(),
      );
      
      _startEmailOtpCountdown();
      
      Get.snackbar(
        'Success',
        'Verification email resent!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      Get.snackbar(
        'Error',
        'Failed to resend email: ${_getErrorMessage(e)}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendPhoneOtp() async {
    if (!canResendPhoneOtp.value) return;

    try {
      isLoading.value = true;
      await _sendPhoneOtp();
      _startPhoneOtpCountdown();
    } finally {
      isLoading.value = false;
    }
  }

  void _startEmailOtpCountdown() {
    canResendEmailOtp.value = false;
    emailOtpCountdown.value = 60;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      emailOtpCountdown.value--;
      return emailOtpCountdown.value > 0;
    });
  }

  void _startPhoneOtpCountdown() {
    canResendPhoneOtp.value = false;
    phoneOtpCountdown.value = 60;
    
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      phoneOtpCountdown.value--;
      return phoneOtpCountdown.value > 0;
    });
  }

  void goToLogin() {
    Get.offNamed(AppRoutes.login);
  }

  void goBack() {
    if (currentStep.value > 0) {
      currentStep.value--;
    } else {
      Get.back();
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'User already registered':
          return 'An account with this email already exists';
        case 'Password should be at least 6 characters':
          return 'Password must be at least 6 characters long';
        case 'Invalid email':
          return 'Please enter a valid email address';
        case 'Signup disabled':
          return 'New user registration is currently disabled';
        default:
          return error.message;
      }
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else {
      return 'An unexpected error occurred';
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    fullNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    emailOtpController.dispose();
    phoneOtpController.dispose();
    super.onClose();
  }
}