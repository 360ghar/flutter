import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/routes/app_routes.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final otpFormKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();

  // Step: 0 => phone, 1 => otp, 2 => new password
  final step = 0.obs;

  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final canResendOtp = false.obs;
  final otpCountdown = 0.obs;

  @override
  void onInit() {
    super.onInit();
  }

  String _normalizeIndianPhone(String input) {
    var cleaned = input.replaceAll(RegExp(r"\s+"), "");
    if (RegExp(r"^\+91[0-9]{10}$").hasMatch(cleaned)) return cleaned;
    cleaned = cleaned.replaceAll(RegExp(r"(?!^\+)[^0-9]"), "");
    if (RegExp(r"^[0-9]{10}$").hasMatch(cleaned)) return "+91$cleaned";
    final m = RegExp(r"^0([0-9]{10})$").firstMatch(cleaned);
    if (m != null) return "+91${m.group(1)}";
    return input.trim();
  }

  Future<void> sendOtp() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    try {
      isLoading.value = true;
      final phone = _normalizeIndianPhone(phoneController.text.trim());
      DebugLogger.auth('Sending reset OTP to: $phone');
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false,
      );
      step.value = 1;
      _startOtpCountdown();
      ErrorHandler.showInfo('OTP sent to your phone');
    } catch (e, st) {
      DebugLogger.error('Forgot password: send OTP error', e, st);
      if (e is AuthException && e.message.toLowerCase().contains('not found')) {
        ErrorHandler.showInfo('User not found. Please create a new account');
        Get.offNamed(AppRoutes.login);
        return;
      }
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (otpController.text.length != 6) {
      ErrorHandler.handleValidationError('OTP', 'Please enter a valid 6-digit OTP');
      return;
    }
    try {
      isLoading.value = true;
      final phone = _normalizeIndianPhone(phoneController.text.trim());
      final token = otpController.text;
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      if (response.user != null && response.session != null) {
        DebugLogger.success('OTP verified, proceed to reset password');
        step.value = 2;
      } else {
        throw const AuthException('Invalid OTP', code: 'invalid_otp');
      }
    } catch (e, st) {
      DebugLogger.error('Forgot password: verify OTP error', e, st);
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePassword() async {
    if (!(passwordFormKey.currentState?.validate() ?? false)) return;
    try {
      isLoading.value = true;
      final newPassword = passwordController.text;
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword));
      ErrorHandler.showSuccess('Password updated. You are now signed in');
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e, st) {
      DebugLogger.error('Forgot password: update password error', e, st);
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResendOtp.value) return;
    await sendOtp();
  }

  void _startOtpCountdown() {
    canResendOtp.value = false;
    otpCountdown.value = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      otpCountdown.value--;
      if (otpCountdown.value <= 0) {
        canResendOtp.value = true;
      }
      return otpCountdown.value > 0;
    });
  }

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
