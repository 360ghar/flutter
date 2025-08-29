import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/auth_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/debug_logger.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  
  // Form fields
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // OTP state
  final otpController = TextEditingController();
  // Unified flow control
  // flow: 'login' or 'forgot'
  final flow = 'login'.obs;
  // step: 0 (inputs), 1 (otp), 2 (new password for forgot)
  final currentStep = 0.obs;
  final canResendOtp = false.obs;
  final otpCountdown = 0.obs;
  final createdDuringFlow = false.obs; // true if we signed up in this attempt
  
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

      final phone = _normalizeIndianPhone(phoneController.text.trim());
      DebugLogger.auth('Attempting phone login for: $phone');

      // Use Supabase phone + password sign-in directly
      final response = await Supabase.instance.client.auth.signInWithPassword(
        phone: phone,
        password: passwordController.text,
      );

      if (response.user != null && response.session != null) {
        DebugLogger.success('Phone login successful');
        ErrorHandler.showSuccess('Signed in successfully');
        // onAuthStateChange in AuthController will handle navigation
        return;
      }

      // If no session/user, treat as failure
      throw const AuthException('Invalid login credentials', code: 'invalid_credentials');
    } catch (e, stackTrace) {
      // Treat invalid credentials and not-confirmed as expected flow transitions
      if (e is AuthException) {
        final msg = e.message.toLowerCase();
        // Existing user but not confirmed → send OTP without creating user
        if (msg.contains('confirm')) {
          DebugLogger.info('Phone not confirmed. Sending OTP for verification.');
          await _sendOtp(shouldCreateUser: false);
          return;
        }
        // Wrong password vs new user detection via signup
        if (passwordController.text.length < 6) {
          errorMessage.value = 'Password must be at least 6 characters';
          return;
        }
        try {
          final normalizedPhone = _normalizeIndianPhone(phoneController.text.trim());
          
          final signupResp = await Supabase.instance.client.auth.signUp(
            phone: normalizedPhone,
            password: passwordController.text,
          );
          if (signupResp.user != null) {
            createdDuringFlow.value = true;
            currentStep.value = 1;
            _startOtpCountdown();
            ErrorHandler.showInfo('Verify the OTP sent to your phone');
            return;
          }
        } catch (signupError, st3) {
          // Existing user → signal wrong password cleanly (no noisy error log)
          if (signupError is AuthException && signupError.message.toLowerCase().contains('already')) {
            errorMessage.value = 'Wrong password. Try again or use Forgot password';
            passwordController.clear();
            return;
          }
          // Unexpected error: log and show (as warning if weak password)
          final msg = signupError is AuthException ? signupError.message.toLowerCase() : signupError.toString().toLowerCase();
          if (msg.contains('password') || msg.contains('weak')) {
            DebugLogger.warning('Signup rejected due to weak password');
          } else {
            DebugLogger.error('Signup attempt after login failure', signupError, st3);
          }
          ErrorHandler.handleAuthError(signupError);
          return;
        }
        // Fallback: show friendly error without stack
        errorMessage.value = 'Unable to sign in. Please try again.';
        return;
      }
      // Non-auth exceptions
      DebugLogger.error('Phone login unexpected error', e, stackTrace);
      errorMessage.value = e.toString();
      ErrorHandler.handleAuthError(e, onRetry: signIn);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _sendOtp({bool shouldCreateUser = false}) async {
    try {
      isLoading.value = true;
      final phone = _normalizeIndianPhone(phoneController.text.trim());
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: shouldCreateUser,
      );
      currentStep.value = 1;
      _startOtpCountdown();
      ErrorHandler.showInfo('OTP sent to your phone');
    } catch (e, st) {
      DebugLogger.error('Failed to send OTP', e, st);
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (!canResendOtp.value) return;
    await _sendOtp(shouldCreateUser: false);
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
        DebugLogger.success('Phone verified and signed in');
        ErrorHandler.showSuccess('Phone verified');
        // Auth state listener will navigate based on profile completeness
      } else {
        throw const AuthException('Invalid OTP', code: 'invalid_otp');
      }
    } catch (e, st) {
      DebugLogger.error('OTP verify error', e, st);
      otpController.clear();
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
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

  // Normalize Indian phone numbers to E.164 (+91XXXXXXXXXX)
  String _normalizeIndianPhone(String input) {
    var cleaned = input.replaceAll(RegExp(r"\s+"), "");
    // If it already starts with +91 and 10 digits, keep it
    if (RegExp(r"^\+91[0-9]{10}$").hasMatch(cleaned)) return cleaned;
    // Remove non-digits except leading +
    cleaned = cleaned.replaceAll(RegExp(r"(?!^\+)[^0-9]"), "");
    // If 10 digits, prefix +91
    if (RegExp(r"^[0-9]{10}$").hasMatch(cleaned)) return "+91$cleaned";
    // If starts with 0 and 11 digits (0XXXXXXXXXX), drop leading 0 and add +91
    final m = RegExp(r"^0([0-9]{10})$").firstMatch(cleaned);
    if (m != null) return "+91${m.group(1)}";
    // As a last resort, return original trimmed to let validator show error upstream
    return input.trim();
  }

  // Switch to integrated forgot password flow on the same screen
  Future<void> resetPassword() async {
    flow.value = 'forgot';
    currentStep.value = 0;
    errorMessage.value = '';
  }

  // Forgot password flow: send OTP
  Future<void> sendForgotOtp() async {
    if (isLoading.value) return;
    // Validate phone input only
    final raw = phoneController.text.trim();
    if (raw.isEmpty) {
      ErrorHandler.handleValidationError('Phone', 'Please enter your phone number');
      return;
    }
    try {
      isLoading.value = true;
      final phone = _normalizeIndianPhone(raw);
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: false,
      );
      currentStep.value = 1;
      _startOtpCountdown();
      ErrorHandler.showInfo('OTP sent to your phone');
    } catch (e, st) {
      DebugLogger.error('Forgot flow: send OTP error', e, st);
      final msg = e is AuthException ? e.message.toLowerCase() : e.toString().toLowerCase();
      if (msg.contains('not found')) {
        errorMessage.value = 'No account found for this number';
        return;
      }
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Forgot password flow: verify OTP then show new password
  Future<void> verifyForgotOtp() async {
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
        DebugLogger.success('OTP verified for reset');
        currentStep.value = 2;
      } else {
        throw const AuthException('Invalid OTP', code: 'invalid_otp');
      }
    } catch (e, st) {
      DebugLogger.error('Forgot flow: verify OTP error', e, st);
      otpController.clear();
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Forgot password flow: update password for signed-in (OTP) user
  Future<void> updateForgotPassword(String newPassword) async {
    if (newPassword.isEmpty || newPassword.length < 6) {
      ErrorHandler.handleValidationError('Password', 'Password must be at least 6 characters');
      return;
    }
    try {
      isLoading.value = true;
      // Ensure user is authenticated via OTP before updating password
      if (Supabase.instance.client.auth.currentUser == null) {
        ErrorHandler.handleAuthError(const AuthException('Session not found'));
        return;
      }
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: newPassword));
      ErrorHandler.showSuccess('Password updated. You are now signed in');
      // Auth state listener will route appropriately
    } catch (e, st) {
      DebugLogger.error('Forgot flow: update password error', e, st);
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void goToSignup() {
    // Single login flow; redirect to self
    if (Get.currentRoute != AppRoutes.login) {
      Get.offNamed(AppRoutes.login);
    }
  }

  void clearError() {
    errorMessage.value = '';
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
