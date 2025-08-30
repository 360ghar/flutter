import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/controllers/page_state_service.dart';
import '../../../core/data/models/unified_filter_model.dart';

class LocationSearchController extends GetxController {
  late final LocationController locationController;
  late final PageStateService pageStateService;

  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  // Debounce timer
  Worker? _debounceWorker;

  @override
  void onInit() {
    super.onInit();
    locationController = Get.find<LocationController>();
    pageStateService = Get.find<PageStateService>();

    // Setup debounce for search
    _debounceWorker = debounce(
      searchQuery,
      (_) => _performSearch(),
      time: const Duration(milliseconds: 500),
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

    try {
      // Pass the selected name from autocomplete to preserve it
      final locationData = await locationController.getPlaceDetails(
        suggestion.placeId,
        preferredName: suggestion.mainText,
      );

      if (locationData != null) {
        // Update filter controller with selected location
        await pageStateService.updateLocation(locationData, source: 'search');

        Get.back();
        Get.snackbar(
          'Location Selected',
          'Selected: ${locationData.name}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to get location details',
          snackPosition: SnackPosition.TOP,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectCity(String cityName, String stateName) async {
    // Create location data for the selected city
    // In a real app, you might want to geocode this to get actual coordinates
    final locationData = LocationData(
      name: '$cityName, $stateName',
      latitude: 0.0, // These would be fetched from geocoding API
      longitude: 0.0,
    );

    // For now, just update the location without coordinates
    // You could enhance this by geocoding the city name
    await pageStateService.updateLocation(locationData, source: 'search');

    Get.back();
    Get.snackbar(
      'City Selected',
      'Selected: $cityName',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> useCurrentLocation() async {
    isLoading.value = true;

    try {
      // Get current location if not already available
      if (!locationController.hasLocation) {
        await locationController.getCurrentLocation(forceRefresh: true);
      }

      if (locationController.hasLocation) {
        // Always get fresh address from coordinates to ensure we have a real location name
        final locationName = await locationController.getAddressFromCoordinates(
          locationController.currentLatitude!,
          locationController.currentLongitude!,
        );

        final locationData = LocationData(
          name: locationName,
          latitude: locationController.currentLatitude!,
          longitude: locationController.currentLongitude!,
        );

        await pageStateService.updateLocation(locationData, source: 'search');

        Get.back();
        Get.snackbar(
          'Location Set',
          'Using $locationName',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
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
