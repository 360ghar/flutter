// lib/features/auth/controllers/phone_entry_controller.dart

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_handler.dart';
import 'package:ghar360/core/utils/formatters.dart';
import 'package:ghar360/features/auth/data/auth_repository.dart';

enum PhoneEntryState { idle, validating, checking, error, success }

class PhoneEntryController extends GetxController {
  final AuthRepository _authRepository = Get.find();
  final formKey = GlobalKey<FormState>();

  final phoneController = TextEditingController();

  final Rx<PhoneEntryState> state = PhoneEntryState.idle.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool userExists = false.obs;

  String? validatePhone(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return 'phone_required'.tr;
    }
    final cleaned = raw.replaceAll(RegExp(r'\s+'), '');
    final tenDigits = RegExp(r'^[0-9]{10}$');
    final e164IN = RegExp(r'^\+91[0-9]{10}$');
    if (!(tenDigits.hasMatch(cleaned) || e164IN.hasMatch(cleaned))) {
      return 'phone_invalid'.tr;
    }
    return null;
  }

  Future<void> checkAndNavigate() async {
    if (!formKey.currentState!.validate()) return;

    state.value = PhoneEntryState.checking;
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final phone = Formatters.normalizeIndianPhone(phoneController.text.trim());
      DebugLogger.auth('Checking if user exists for phone: $phone');

      final exists = await _authRepository.checkUserExists(phone);
      userExists.value = exists;
      state.value = PhoneEntryState.success;

      if (exists) {
        DebugLogger.auth('User exists, navigating to login');
        Get.toNamed(AppRoutes.login, arguments: {'phone': phone});
      } else {
        DebugLogger.auth('User does not exist, navigating to signup');
        Get.toNamed(AppRoutes.signup, arguments: {'phone': phone});
      }
    } catch (e) {
      DebugLogger.error('Error checking user existence', e);
      state.value = PhoneEntryState.error;
      errorMessage.value = 'network_error'.tr;
      ErrorHandler.handleNetworkError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}
