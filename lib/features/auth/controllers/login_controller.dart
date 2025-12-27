// lib/features/auth/controllers/login_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_handler.dart';
import 'package:ghar360/core/utils/formatters.dart';
import 'package:ghar360/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString prefilledPhone = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Check for pre-filled phone from arguments
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic> && args['phone'] != null) {
      prefilledPhone.value = args['phone'] as String;
      phoneController.text = prefilledPhone.value.replaceFirst('+91', '');
    } else {
      // No phone provided - redirect back to phone entry
      DebugLogger.warning('LoginView accessed without phone number, redirecting to phone entry');
      Future.microtask(() => Get.offNamed(AppRoutes.phoneEntry));
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final phone = Formatters.normalizeIndianPhone(phoneController.text.trim());
      final password = passwordController.text;

      await _authRepository.signInWithPhonePassword(phone, password);

      // Success! The AuthController listener will handle navigation
      DebugLogger.success('Sign in successful for $phone');
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
