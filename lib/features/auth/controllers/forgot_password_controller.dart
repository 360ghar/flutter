// lib/features/auth/controllers/forgot_password_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_handler.dart';
import 'package:ghar360/core/utils/formatters.dart';
import 'package:ghar360/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final RxInt currentStep = 0.obs; // 0: phone, 1: OTP, 2: new password
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

  // Step 1: Send OTP for password reset
  Future<void> sendResetOtp() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final phone = Formatters.normalizeIndianPhone(phoneController.text.trim());
      await _authRepository.sendPhoneOtp(phone);

      currentStep.value = 1; // Move to OTP step
      _startOtpCountdown();

      Get.snackbar('otp_sent'.tr, 'password_reset_otp_sent'.tr, snackPosition: SnackPosition.TOP);

      DebugLogger.success('Password reset OTP sent to $phone');
    } catch (e) {
      errorMessage.value = 'failed_to_send_otp'.tr;
      ErrorHandler.handleAuthError(e);
      DebugLogger.error('Failed to send password reset OTP', e);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: Verify OTP and create temporary session
  Future<void> verifyResetOtp() async {
    if (otpController.text.trim().length != 6) {
      errorMessage.value = 'invalid_otp'.tr;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final phone = Formatters.normalizeIndianPhone(phoneController.text.trim());
      await _authRepository.verifyPhoneOtp(phone: phone, token: otpController.text.trim());

      // This creates a temporary session for password reset
      currentStep.value = 2; // Move to password reset step

      DebugLogger.success('OTP verification successful for password reset');
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      ErrorHandler.handleAuthError(e);
      DebugLogger.error('OTP verification failed for password reset', e);
    } catch (e) {
      errorMessage.value = 'otp_verification_error'.tr;
      ErrorHandler.handleNetworkError(e);
      DebugLogger.error('Unexpected OTP verification error', e);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 3: Update password using the temporary session
  Future<void> updatePassword() async {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (newPassword.isEmpty) {
      errorMessage.value = 'password_required'.tr;
      return;
    }

    if (newPassword.length < 6) {
      errorMessage.value = 'password_min_length'.tr;
      return;
    }

    if (newPassword != confirmPassword) {
      errorMessage.value = 'passwords_dont_match'.tr;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _authRepository.updateUserPassword(newPassword);

      Get.snackbar(
        'success'.tr,
        'password_updated_successfully'.tr,
        snackPosition: SnackPosition.TOP,
      );

      // Navigate to login screen
      Get.offAllNamed(AppRoutes.login);

      DebugLogger.success('Password updated successfully');
    } catch (e) {
      errorMessage.value = 'failed_to_update_password'.tr;
      ErrorHandler.handleAuthError(e);
      DebugLogger.error('Failed to update password', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (canResendOtp.value) {
      try {
        isLoading.value = true;
        final phone = Formatters.normalizeIndianPhone(phoneController.text.trim());
        await _authRepository.sendPhoneOtp(phone);

        _startOtpCountdown();
        Get.snackbar('otp_sent'.tr, 'otp_resent_message'.tr);

        DebugLogger.info('Password reset OTP resent to $phone');
      } catch (e) {
        ErrorHandler.handleAuthError(e);
        DebugLogger.error('Failed to resend password reset OTP', e);
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

  void goBackToStep(int step) {
    if (step >= 0 && step < currentStep.value) {
      currentStep.value = step;
      errorMessage.value = '';

      // Clear appropriate fields
      if (step < 1) {
        otpController.clear();
        _otpTimer?.cancel();
      }
      if (step < 2) {
        newPasswordController.clear();
        confirmPasswordController.clear();
      }
    }
  }

  @override
  void onClose() {
    _otpTimer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
