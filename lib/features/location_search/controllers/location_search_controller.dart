import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/data/models/unified_filter_model.dart';
import '../../../core/utils/debug_logger.dart';

class LocationSearchController extends GetxController {
  late final LocationController locationController;
  late final FilterService filterService;
  
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  
  // Debounce timer
  Worker? _debounceWorker;

  @override
  void onInit() {
    super.onInit();
    locationController = Get.find<LocationController>();
    filterService = Get.find<FilterService>();

    // Setup debounce for search with reduced delay for faster feedback
    _debounceWorker = debounce(
      searchQuery,
      (_) => _performSearch(),
      time: const Duration(milliseconds: 300),
    );
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
  }

  Future<void> _performSearch() async {
    if (searchQuery.value.trim().isEmpty) {
      locationController.clearPlaceSuggestions();
      return;
    }
    
    await locationController.getPlaceSuggestions(searchQuery.value);
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    locationController.clearPlaceSuggestions();
  }

  Future<void> selectPlace(PlaceSuggestion suggestion) async {
    isLoading.value = true;
    DebugLogger.info('🎯 Selecting place: ${suggestion.description} (placeId: ${suggestion.placeId})');

    try {
      // --- THIS IS THE FIX ---
      // We still need coordinates, so we will fetch them with better error handling.
      final locationDetails = await locationController.getPlaceDetails(suggestion.placeId);

      if (locationDetails != null) {
        filterService.updateLocation(locationDetails);
        Get.back();
        Get.snackbar(
          'Location Updated',
          'Showing properties in ${locationDetails.name}',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        // Fallback if details fail
        DebugLogger.error('❌ Could not fetch location details for placeId: ${suggestion.placeId}');
        Get.snackbar('Error', 'Failed to get location details. Please try another location.');
      }
    } catch (e) {
      DebugLogger.error('❌ Error in selectPlace: $e');
      Get.snackbar('Error', 'An unexpected error occurred.');
    } finally {
      isLoading.value = false;
    }
  }

  void selectCity(String cityName, String stateName) async {
    isLoading.value = true;
    // First, get suggestions for the city to find its placeId
    final suggestions = await locationController.getPlaceSuggestions('$cityName, $stateName');
    if (suggestions.isNotEmpty) {
      // Use the first suggestion
      await selectPlace(suggestions.first);
    } else {
      Get.snackbar('Error', 'Could not find details for $cityName.');
      isLoading.value = false;
    }
  }



  Future<void> useCurrentLocation() async {
    isLoading.value = true;
    
    try {
      // Get current location if not already available
      if (!locationController.hasLocation) {
        await locationController.getCurrentLocation(forceRefresh: true);
      }
      
      if (locationController.hasLocation) {
        final locationData = LocationData(
          name: locationController.currentAddress.value.isNotEmpty
              ? locationController.currentAddress.value
              : 'Current Location',
          latitude: locationController.currentLatitude!,
          longitude: locationController.currentLongitude!,
          city: locationController.currentCity.value,
          locality: null,
        );
        
        filterService.updateLocation(locationData);
        
        Get.back();
        Get.snackbar(
          'Location Updated',
          'Using your current location',
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'Location Error',
          'Unable to get your current location',
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    _debounceWorker?.dispose();
    super.onClose();
  }
}