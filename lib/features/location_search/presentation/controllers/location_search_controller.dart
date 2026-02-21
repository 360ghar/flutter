import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/location_controller.dart';
import 'package:ghar360/core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/services/google_places_service.dart';
import 'package:ghar360/core/utils/app_toast.dart';

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
        AppToast.success(
          'location_selected_title'.tr,
          'location_selected_message'.trParams({'name': locationData.name}),
        );
      } else {
        AppToast.error('error'.tr, 'location_details_failed'.tr);
      }
    } finally {
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
        AppToast.success(
          'location_set_title'.tr,
          'location_set_message'.trParams({'location': locationName}),
        );
      } else {
        AppToast.error('location_error_title'.tr, 'unable_get_location'.tr);
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
