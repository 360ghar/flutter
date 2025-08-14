import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/user_controller.dart';

class EditProfileController extends GetxController {
  final UserController _userController = Get.find<UserController>();
  
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  
  // Observable fields
  final RxString profileImageUrl = ''.obs;
  final Rx<DateTime?> dateOfBirth = Rx<DateTime?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    super.onClose();
  }

  void _loadUserData() {
    final user = _userController.user.value;
    if (user != null) {
      nameController.text = user.name;
      emailController.text = user.email;
      phoneController.text = user.phone ?? '';
      profileImageUrl.value = user.profileImage ?? '';
      
      // Load additional fields from preferences if available
      final prefs = user.preferences;
      if (prefs?.containsKey('location') == true) {
        final location = prefs!['location'];
        locationController.text = location is String ? location : '';
      }
      if (prefs?.containsKey('dateOfBirth') == true) {
        final dobString = prefs!['dateOfBirth'];
        if (dobString is String) {
          try {
            dateOfBirth.value = DateTime.parse(dobString);
          } catch (e) {
            // Invalid date format, ignore
          }
        }
      }
    }
  }

  Future<void> pickProfileImage() async {
    // In a real app, this would open image picker
    // For now, just show a placeholder dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Profile Picture'),
        content: const Text('Image picker functionality would be implemented here using image_picker package.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth.value ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Minimum 13 years old
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFFBC05), // AppTheme.primaryYellow
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      dateOfBirth.value = picked;
    }
  }

  void clearDateOfBirth() {
    dateOfBirth.value = null;
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      final currentUser = _userController.user.value;
      if (currentUser == null) {
        Get.snackbar('Error', 'User data not found');
        return;
      }

      // Prepare updated preferences
      final updatedPreferences = Map<String, dynamic>.from(currentUser.preferences ?? {});
      updatedPreferences['location'] = locationController.text.trim();
      if (dateOfBirth.value != null) {
        updatedPreferences['dateOfBirth'] = dateOfBirth.value!.toIso8601String();
      } else {
        updatedPreferences.remove('dateOfBirth');
      }

      // Prepare profile data for update
      final profileData = {
        'full_name': nameController.text.trim(),
        'phone': phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        'profile_image_url': profileImageUrl.value.isEmpty ? null : profileImageUrl.value,
      };

      // Update user profile
      await _userController.updateProfile(profileData);
      
      // Update preferences separately
      await _userController.updatePreferences(updatedPreferences);

      Get.back();
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF50C878), // AppTheme.accentGreen
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
} 