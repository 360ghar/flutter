import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

class ProfileCompletionController extends GetxController {
  final formKey = GlobalKey<FormState>();
  
  // Form controllers
  final dateOfBirthController = TextEditingController();
  final phoneController = TextEditingController();
  final occupationController = TextEditingController();
  final budgetMinController = TextEditingController();
  final budgetMaxController = TextEditingController();
  final preferredCitiesController = TextEditingController();
  
  // Observable states
  final currentStep = 0.obs;
  final isLoading = false.obs;
  final selectedIncome = ''.obs;
  final selectedPropertyPurpose = 'rent'.obs;
  final selectedPropertyTypes = <String>[].obs;
  final selectedBedroomsMin = 0.obs;
  final selectedBedroomsMax = 0.obs;
  final maxDistance = 10.0.obs;
  final selectedAmenities = <String>[].obs;
  final currentLocation = Rxn<Position>();
  
  // Data lists
  final incomeRanges = [
    'Under ₹5 Lakhs',
    '₹5-10 Lakhs',
    '₹10-20 Lakhs',
    '₹20-50 Lakhs',
    '₹50 Lakhs - 1 Crore',
    'Above ₹1 Crore',
    'Prefer not to say'
  ];
  
  final propertyPurposes = ['rent', 'buy', 'short_stay'];
  
  final propertyTypes = [
    'apartment',
    'house',
    'villa',
    'studio',
    'penthouse',
    'duplex'
  ];
  
  final amenities = [
    'parking',
    'gym',
    'swimming_pool',
    'security',
    'power_backup',
    'elevator',
    'garden',
    'playground',
    'club_house',
    'wifi',
    'air_conditioning',
    'balcony',
    'furnished',
    'pet_friendly'
  ];

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
        phoneController.text = user.phone ?? '';
        
        final preferences = user.preferences;
        if (preferences != null) {
          selectedPropertyPurpose.value = preferences['purpose'] ?? 'rent';
          
          if (preferences['property_type'] != null) {
            selectedPropertyTypes.clear();
            selectedPropertyTypes.addAll(
              List<String>.from(preferences['property_type'])
            );
          }
          
          budgetMinController.text = preferences['budget_min']?.toString() ?? '';
          budgetMaxController.text = preferences['budget_max']?.toString() ?? '';
          selectedBedroomsMin.value = preferences['bedrooms_min'] ?? 0;
          selectedBedroomsMax.value = preferences['bedrooms_max'] ?? 0;
          maxDistance.value = (preferences['max_distance_km'] ?? 10).toDouble();
          
          if (preferences['amenities'] != null) {
            selectedAmenities.clear();
            selectedAmenities.addAll(
              List<String>.from(preferences['amenities'])
            );
          }
        }
      }
    } catch (e) {
      print('Error loading existing data: $e');
    }
  }

  void nextStep() {
    if (_validateCurrentStep()) {
      if (currentStep.value < 2) {
        currentStep.value++;
      }
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep.value) {
      case 0:
        return _validatePersonalInfo();
      case 1:
        return _validatePropertyPreferences();
      case 2:
        return _validateLocationPreferences();
      default:
        return true;
    }
  }

  bool _validatePersonalInfo() {
    // Basic validation - these fields are optional for profile completion
    return true;
  }

  bool _validatePropertyPreferences() {
    if (selectedPropertyTypes.isEmpty) {
      Get.snackbar(
        'Required',
        'Please select at least one property type',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  bool _validateLocationPreferences() {
    // Location preferences are optional
    return true;
  }

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

  Future<void> getCurrentLocation() async {
    try {
      isLoading.value = true;
      
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          'Permission Denied',
          'Location permission is permanently denied. Please enable it in settings.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Permission Required',
          'Location permission is required to use this feature.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      currentLocation.value = position;
      
      // Update location in backend
      await authController.updateUserLocation(
        position.latitude,
        position.longitude,
      );
      
      Get.snackbar(
        'Success',
        'Current location updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get current location: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> completeProfile() async {
    if (!_validateCurrentStep()) return;
    
    try {
      isLoading.value = true;
      
      // Prepare profile data
      final profileData = <String, dynamic>{};
      final preferences = <String, dynamic>{};
      
      // Personal info
      if (dateOfBirthController.text.isNotEmpty) {
        try {
          final date = DateFormat('dd/MM/yyyy').parse(dateOfBirthController.text);
          profileData['date_of_birth'] = DateFormat('yyyy-MM-dd').format(date);
        } catch (e) {
          // Invalid date format, skip
        }
      }
      
      if (phoneController.text.isNotEmpty) {
        profileData['phone'] = phoneController.text.trim();
      }
      
      // Property preferences
      preferences['purpose'] = selectedPropertyPurpose.value;
      preferences['property_type'] = selectedPropertyTypes.toList();
      
      if (budgetMinController.text.isNotEmpty) {
        preferences['budget_min'] = int.tryParse(budgetMinController.text) ?? 0;
      }
      
      if (budgetMaxController.text.isNotEmpty) {
        preferences['budget_max'] = int.tryParse(budgetMaxController.text) ?? 0;
      }
      
      preferences['bedrooms_min'] = selectedBedroomsMin.value;
      preferences['bedrooms_max'] = selectedBedroomsMax.value;
      preferences['max_distance_km'] = maxDistance.value.round();
      preferences['amenities'] = selectedAmenities.toList();
      
      // Location preferences
      if (preferredCitiesController.text.isNotEmpty) {
        final cities = preferredCitiesController.text
            .split(',')
            .map((city) => city.trim())
            .where((city) => city.isNotEmpty)
            .toList();
        preferences['location_preference'] = cities;
      }
      
      // Update profile
      if (profileData.isNotEmpty) {
        await authController.updateUserProfile(profileData);
      }
      
      // Update preferences
      if (preferences.isNotEmpty) {
        await authController.updateUserPreferences(preferences);
      }
      
      Get.snackbar(
        'Success',
        'Profile completed successfully!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
      // Navigate to home
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to complete profile: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void skipToHome() {
    Get.offAllNamed(AppRoutes.home);
  }

  @override
  void onClose() {
    _isDisposed = true;
    
    // Dispose text controllers
    dateOfBirthController.dispose();
    phoneController.dispose();
    occupationController.dispose();
    budgetMinController.dispose();
    budgetMaxController.dispose();
    preferredCitiesController.dispose();
    
    super.onClose();
  }
}