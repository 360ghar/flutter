// lib/features/auth/controllers/profile_completion_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/models/auth_status.dart';
import '../../../core/utils/error_handler.dart';

class ProfileCompletionController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final isLoading = false.obs;
  final RxInt currentStep = 0.obs;
  final RxString selectedPropertyPurpose = 'buy'.obs;
  final List<String> propertyPurposes = ['Buy', 'Rent', 'Investment'];

  // Store the selected DateTime object
  DateTime? selectedDateOfBirth;

  late final AuthController authController;
  PageStateService? pageStateService;

  @override
  void onInit() {
    super.onInit();
    authController = Get.find<AuthController>();
    if (Get.isRegistered<PageStateService>()) {
      pageStateService = Get.find<PageStateService>();
    }
    emailController.text = authController.userEmail ?? '';
  }

  Future<void> completeProfile() async {
    if (isLoading.value || !(formKey.currentState?.validate() ?? false)) return;

    try {
      isLoading.value = true;
      update(); // Trigger UI rebuild to show loading state

      final profileData = {
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'date_of_birth': selectedDateOfBirth != null
            ? '${selectedDateOfBirth!.year.toString().padLeft(4, '0')}-'
                  '${selectedDateOfBirth!.month.toString().padLeft(2, '0')}-'
                  '${selectedDateOfBirth!.day.toString().padLeft(2, '0')}'
            : null,
        'property_purpose': selectedPropertyPurpose.value,
      };

      // Call the central AuthController to update the profile.
      // The AuthController will then refresh its state, and the Root widget will
      // automatically navigate to the Dashboard.
      final success = await authController.updateUserProfile(profileData);

      if (success) {
        // Sync chosen purpose to PageStateService if available.
        // If not yet registered (will be by DashboardBinding), the user preference
        // has already been persisted via updateUserProfile -> updateUserPreferences.
        if (Get.isRegistered<PageStateService>()) {
          (pageStateService ?? Get.find<PageStateService>()).setPurposeForAllPages(
            selectedPropertyPurpose.value,
          );
        }
      } else {
        // The error is already shown by the AuthController, but you can add specific logic here if needed.
      }
    } catch (e) {
      ErrorHandler.handleNetworkError(e);
    } finally {
      isLoading.value = false;
      update(); // Trigger UI rebuild to hide loading state
    }
  }

  void skipToHome() {
    // This is a bit of a cheat. Ideally, we'd set a flag, but for simplicity:
    // We can just force the auth status.
    authController.authStatus.value = AuthStatus.authenticated;
  }

  void nextStep() {
    if (currentStep.value < 1) {
      currentStep.value++;
      update(); // Trigger UI rebuild for GetBuilder
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      update(); // Trigger UI rebuild for GetBuilder
    }
  }

  Future<void> selectDateOfBirth() async {
    final DateTime? pickedDate = await showDatePicker(
      context: Get.context!,
      initialDate: selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
    );

    if (pickedDate != null) {
      // Store the DateTime object
      selectedDateOfBirth = pickedDate;

      // Format for UI display (dd/MM/yyyy)
      final formattedDate =
          '${pickedDate.day.toString().padLeft(2, '0')}/'
          '${pickedDate.month.toString().padLeft(2, '0')}/'
          '${pickedDate.year}';
      dateOfBirthController.text = formattedDate;

      update(); // Trigger UI rebuild for GetBuilder
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    dateOfBirthController.dispose();
    super.onClose();
  }
}
