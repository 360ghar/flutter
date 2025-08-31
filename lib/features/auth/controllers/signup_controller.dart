// lib/features/auth/controllers/signup_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/debug_logger.dart';

class SignUpController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final RxInt currentStep = 0.obs; // 0 for form, 1 for OTP
  final RxString errorMessage = ''.obs;

  final canResendOtp = false.obs;
  final otpCountdown = 0.obs;
  Timer? _otpTimer;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  String _normalizeIndianPhone(String phone) {
    if (phone.startsWith('+91')) {
      return phone;
    }
    if (phone.length == 10) {
      return '+91$phone';
    }
    return phone; // Return as-is if it doesn't match expected formats
  }

  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final phone = _normalizeIndianPhone(phoneController.text.trim());
      final password = passwordController.text;
      await _authRepository.signUpWithPhonePassword(phone, password);

      currentStep.value = 1; // Move to OTP step
      _startOtpCountdown();

      Get.snackbar(
        'verify_phone'.tr,
        'otp_sent_message'.tr,
        snackPosition: SnackPosition.TOP,
      );

      DebugLogger.success('Sign up initiated for $phone');
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      ErrorHandler.handleAuthError(e);
      DebugLogger.error('Sign up failed', e);
    } catch (e) {
      errorMessage.value = 'signup_error'.tr;
      ErrorHandler.handleNetworkError(e);
      DebugLogger.error('Unexpected signup error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.trim().length != 6) {
      errorMessage.value = 'invalid_otp'.tr;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final phone = _normalizeIndianPhone(phoneController.text.trim());
      await _authRepository.verifyPhoneOtp(
        phone: phone,
        token: otpController.text.trim(),
      );

      // Success! The AuthController will now automatically navigate
      // the user to the profile completion screen.
      DebugLogger.success('OTP verification successful for $phone');
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      ErrorHandler.handleAuthError(e);
      DebugLogger.error('OTP verification failed', e);
    } catch (e) {
      errorMessage.value = 'otp_verification_error'.tr;
      ErrorHandler.handleNetworkError(e);
      DebugLogger.error('Unexpected OTP verification error', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (canResendOtp.value) {
      try {
        isLoading.value = true;
        final phone = _normalizeIndianPhone(phoneController.text.trim());
        await _authRepository.signUpWithPhonePassword(
          phone,
          passwordController.text,
        );

        _startOtpCountdown();
        Get.snackbar('otp_sent'.tr, 'otp_resent_message'.tr);

        DebugLogger.info('OTP resent for signup to $phone');
      } catch (e) {
        ErrorHandler.handleAuthError(e);
        DebugLogger.error('Failed to resend OTP', e);
      } finally {
        isLoading.value = false;
      }
    }
  }

  void _startOtpCountdown() {
    canResendOtp.value = false;
    otpCountdown.value = 60;
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (otpCountdown.value > 0) {
        otpCountdown.value--;
      } else {
        canResendOtp.value = true;
        timer.cancel();
      }
    });
  }

  void goBackToForm() {
    currentStep.value = 0;
    otpController.clear();
    errorMessage.value = '';
    _otpTimer?.cancel();
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
