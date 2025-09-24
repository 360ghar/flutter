// lib/features/auth/controllers/login_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/firebase/analytics_service.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final RxBool rememberMe = false.obs;
  final RxString errorMessage = ''.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
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

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final phone = _normalizeIndianPhone(phoneController.text.trim());
      final password = passwordController.text;

      await _authRepository.signInWithPhonePassword(phone, password);

      // Success! The AuthController listener will handle navigation
      DebugLogger.success('Sign in successful for $phone');
      AnalyticsService.login(method: 'phone_password');
    } on AuthException catch (e) {
      // Handle authentication errors
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        errorMessage.value = 'invalid_credentials'.tr;
      } else {
        errorMessage.value = e.message;
      }
      ErrorHandler.handleAuthError(e);
      DebugLogger.error('Sign in failed', e);
    } catch (e) {
      // Handle other errors like network issues
      errorMessage.value = 'login_error'.tr;
      ErrorHandler.handleNetworkError(e);
      DebugLogger.error('Unexpected login error', e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
