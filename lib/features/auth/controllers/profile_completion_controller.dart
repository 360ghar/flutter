import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/theme.dart';

class ProfileCompletionController extends GetxController {
  final formKey = GlobalKey<FormState>();
  
  // Form controllers
  final dateOfBirthController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  // Only required fields for this flow
  
  // Observable states
  final currentStep = 0.obs;
  final isLoading = false.obs;
  final selectedGender = ''.obs; // male, female, other
  final selectedPropertyPurpose = 'rent'.obs;
  
  // Data lists
  final genders = ['male', 'female', 'other'];
  
  final propertyPurposes = ['rent', 'buy'];

  late final AuthController authController;
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();
    authController = Get.find<AuthController>();
    _loadExistingDataOnce();
  }

  void _loadExistingDataOnce() {
    // Load data once without reactive patterns to avoid GetX scope issues
    try {
      final user = authController.currentUser.value;
      if (user != null && !_isDisposed) {
        fullNameController.text = user.fullName ?? '';
        emailController.text = user.email;
        final preferences = user.preferences;
        if (preferences != null) {
          selectedPropertyPurpose.value = preferences['purpose'] ?? 'rent';
        }
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Error loading existing profile data', e, stackTrace);
    }
  }

  void nextStep() {
    if (_validateCurrentStep()) {
      if (currentStep.value < 1) {
        currentStep.value++;
        update();
      }
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      update();
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        return _validatePersonalInfo();
      case 1:
        return _validatePreference();
      default:
        return true;
    }
  }

  bool _validatePersonalInfo() {
    // Validate only required fields
    if (fullNameController.text.trim().length < 2) return false;
    if (!GetUtils.isEmail(emailController.text.trim())) return false;
    if (selectedGender.value.isEmpty) return false;
    if (dateOfBirthController.text.isEmpty) return false;
    return true;
  }

  bool _validatePreference() => propertyPurposes.contains(selectedPropertyPurpose.value);

  Future<void> selectDateOfBirth() async {
    if (_isDisposed) return;
    
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    
    if (picked != null && !_isDisposed) {
      dateOfBirthController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> completeProfile() async {
    if (isLoading.value) return;
    if (!_validateCurrentStep()) return;
    
    try {
      isLoading.value = true;
      update();
      
      // Prepare profile data
      final profileData = <String, dynamic>{};
      final preferences = <String, dynamic>{};
      
      // Basic info
      if (fullNameController.text.isNotEmpty) {
        profileData['full_name'] = fullNameController.text.trim();
      }
      if (emailController.text.isNotEmpty) {
        profileData['email'] = emailController.text.trim();
      }
      if (selectedGender.value.isNotEmpty) {
        profileData['gender'] = selectedGender.value;
      }

      // Personal info
      if (dateOfBirthController.text.isNotEmpty) {
        try {
          final date = DateFormat('dd/MM/yyyy').parse(dateOfBirthController.text);
          profileData['date_of_birth'] = DateFormat('yyyy-MM-dd').format(date);
        } catch (e, stackTrace) {
          // Log the parsing error
          DebugLogger.error('Invalid date format in date of birth field', e, stackTrace);

          // Clear the invalid date and show user feedback
          dateOfBirthController.clear();
          Get.snackbar(
            'Invalid Date',
            'Please enter a valid date in DD/MM/YYYY format',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppTheme.warningAmber,
            colorText: AppTheme.backgroundWhite,
          );
        }
      }
      
      // Preference: only purpose
      preferences['purpose'] = selectedPropertyPurpose.value;
      
      // Update profile
      if (profileData.isNotEmpty) {
        await authController.updateUserProfile(profileData);
      }
      
      // Update preferences
      if (preferences.isNotEmpty) {
        await authController.updateUserPreferences(preferences);
      }

      // Apply default purpose across all filter pages and persist locally
      try {
        final dynamic pageState = Get.find();
        pageState.setPurposeForAllPages(selectedPropertyPurpose.value, onlyIfUnset: false);
      } catch (_) {}
      
      Get.snackbar(
        'Success',
        'Profile completed successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.successGreen,
        colorText: AppTheme.backgroundWhite,
      );
      
      // Navigate to home
      Get.offAllNamed(AppRoutes.dashboard);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete profile: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppTheme.errorRed,
        colorText: AppTheme.backgroundWhite,
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void skipToHome() {
    Get.offAllNamed(AppRoutes.dashboard);
  }

  @override
  void onClose() {
    _isDisposed = true;
    
    // Dispose text controllers
    dateOfBirthController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    
    super.onClose();
  }
}
