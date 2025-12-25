// lib/features/auth/controllers/signup_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_handler.dart';
import 'package:ghar360/core/utils/formatters.dart';
import 'package:ghar360/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final formKey = GlobalKey<FormState>();
  final personalInfoFormKey = GlobalKey<FormState>();
  final securityFormKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final otpController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final dateOfBirthController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isTermsAccepted = false.obs;
  final RxInt currentStep = 0.obs; // 0: personal info, 1: security, 2: OTP
  final RxString errorMessage = ''.obs;
  final RxString prefilledPhone = ''.obs;
  final RxInt passwordStrength = 0.obs; // 0: none, 1: weak, 2: medium, 3: strong

  final canResendOtp = false.obs;
  final otpCountdown = 0.obs;
  Timer? _otpTimer;
  final RxBool _isControllerDisposed = false.obs;

  // Store the selected DateTime object
  DateTime? selectedDateOfBirth;

  @override
  void onInit() {
    super.onInit();
    // Check for pre-filled phone from arguments
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic> && args['phone'] != null) {
      prefilledPhone.value = args['phone'] as String;
      phoneController.text = prefilledPhone.value.replaceFirst('+91', '');
    }

    // Listen to password changes for strength indicator
    passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = passwordController.text;
    if (password.isEmpty) {
      passwordStrength.value = 0;
      return;
    }

    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    if (strength <= 2) {
      passwordStrength.value = 1; // weak
    } else if (strength <= 4) {
      passwordStrength.value = 2; // medium
    } else {
      passwordStrength.value = 3; // strong
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void nextStep() {
    errorMessage.value = '';

    if (currentStep.value == 0) {
      // Validate personal info
      if (personalInfoFormKey.currentState?.validate() ?? false) {
        currentStep.value = 1;
      }
    } else if (currentStep.value == 1) {
      // Validate security info and proceed to signup
      if (securityFormKey.currentState?.validate() ?? false) {
        if (!isTermsAccepted.value) {
          errorMessage.value = 'terms_consent_required'.tr;
          return;
        }
        signUp();
      }
    }
  }

  void previousStep() {
    errorMessage.value = '';
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<void> selectDateOfBirth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
    );

    if (pickedDate != null) {
      selectedDateOfBirth = pickedDate;
      final formattedDate =
          '${pickedDate.day.toString().padLeft(2, '0')}/'
          '${pickedDate.month.toString().padLeft(2, '0')}/'
          '${pickedDate.year}';
      dateOfBirthController.text = formattedDate;
    }
  }

  Future<void> signUp() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final phone = Formatters.normalizeIndianPhone(phoneController.text.trim());
      final password = passwordController.text;

      // Include user metadata in signup
      final userData = {
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'date_of_birth': selectedDateOfBirth != null
            ? '${selectedDateOfBirth!.year.toString().padLeft(4, '0')}-'
                  '${selectedDateOfBirth!.month.toString().padLeft(2, '0')}-'
                  '${selectedDateOfBirth!.day.toString().padLeft(2, '0')}'
            : null,
      };

      await _authRepository.signUpWithPhonePassword(phone, password, data: userData);

      currentStep.value = 2; // Move to OTP step
      _startOtpCountdown();

      Get.snackbar('verify_phone'.tr, 'otp_sent_message'.tr, snackPosition: SnackPosition.TOP);

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
      final phone = Formatters.normalizeIndianPhone(phoneController.text.trim());
      await _authRepository.verifyPhoneOtp(phone: phone, token: otpController.text.trim());

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
        final phone = Formatters.normalizeIndianPhone(phoneController.text.trim());
        await _authRepository.signUpWithPhonePassword(phone, passwordController.text);

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
    // Cancel any existing timer first
    _cancelOtpTimer();

    canResendOtp.value = false;
    otpCountdown.value = 60;

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isControllerDisposed.value) {
        timer.cancel();
        return;
      }

      if (otpCountdown.value > 0) {
        otpCountdown.value--;
      } else {
        canResendOtp.value = true;
        timer.cancel();
      }
    });
  }

  void _cancelOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = null;
  }

  void goBackToForm() {
    if (currentStep.value == 2) {
      currentStep.value = 1; // Go back to security step from OTP
    } else if (currentStep.value > 0) {
      currentStep.value--;
    }
    otpController.clear();
    errorMessage.value = '';
    _cancelOtpTimer();
  }

  @override
  void onClose() {
    _disposeController();
    super.onClose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _disposeController() {
    if (_isControllerDisposed.value) return;

    _isControllerDisposed.value = true;
    _cancelOtpTimer();

    try {
      phoneController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
      otpController.dispose();
      fullNameController.dispose();
      emailController.dispose();
      dateOfBirthController.dispose();
    } catch (e) {
      DebugLogger.error('Error disposing text controllers', e);
    }
  }
}
