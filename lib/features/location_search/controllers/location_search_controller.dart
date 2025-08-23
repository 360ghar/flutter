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
      // Try to get location details with retry mechanism
      LocationData? locationDetails = await locationController.getPlaceDetails(suggestion.placeId);

      // If first attempt fails, try enhanced location resolution
      if (locationDetails == null) {
        DebugLogger.warning('⚠️ Standard location resolution failed, trying enhanced method for: ${suggestion.description}');
        locationDetails = await locationController.getEnhancedLocationDetails(suggestion.placeId, suggestion.description);
      }

      if (locationDetails != null) {
        filterService.updateLocation(locationDetails);
        Get.back();
        Get.snackbar(
          'Location Updated',
          'Showing properties in ${locationDetails.name}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      } else {
        // Enhanced error handling with better user feedback
        DebugLogger.error('❌ Could not fetch location details for placeId: ${suggestion.placeId}');

        // Try to extract city name from suggestion description for better error message
        final suggestionText = suggestion.description;
        String cityName = 'this location';

        // Try to extract city name from the suggestion
        if (suggestionText.contains(',')) {
          final parts = suggestionText.split(',');
          if (parts.isNotEmpty) {
            cityName = parts[0].trim();
          }
        }

        Get.snackbar(
          'Location Error',
          'Unable to get details for $cityName. This might be due to network issues or API limits. Please try again or select a different location.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      DebugLogger.error('❌ Error in selectPlace: $e');
      Get.snackbar(
        'Error',
        'An unexpected error occurred while selecting location.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Try alternative methods to get location data when primary method fails
  Future<LocationData?> _tryAlternativeLocationMethods(PlaceSuggestion suggestion) async {
    try {
      DebugLogger.info('🔄 Trying alternative location methods for: ${suggestion.description}');

      // Method 1: Try to extract coordinates from suggestion description (if available)
      // This is a fallback for when Google Places API completely fails

      final description = suggestion.description.toLowerCase();

      // Check if it's one of our major cities and provide coordinates
      final majorCities = {
        'mumbai': LocationData(name: 'Mumbai, Maharashtra, India', latitude: 19.0760, longitude: 72.8777, city: 'Mumbai', locality: 'Mumbai'),
        'delhi': LocationData(name: 'Delhi, India', latitude: 28.7041, longitude: 77.1025, city: 'Delhi', locality: 'Delhi'),
        'bangalore': LocationData(name: 'Bangalore, Karnataka, India', latitude: 12.9716, longitude: 77.5946, city: 'Bangalore', locality: 'Bangalore'),
        'hyderabad': LocationData(name: 'Hyderabad, Telangana, India', latitude: 17.3850, longitude: 78.4867, city: 'Hyderabad', locality: 'Hyderabad'),
        'chennai': LocationData(name: 'Chennai, Tamil Nadu, India', latitude: 13.0827, longitude: 80.2707, city: 'Chennai', locality: 'Chennai'),
        'kolkata': LocationData(name: 'Kolkata, West Bengal, India', latitude: 22.5726, longitude: 88.3639, city: 'Kolkata', locality: 'Kolkata'),
        'pune': LocationData(name: 'Pune, Maharashtra, India', latitude: 18.5204, longitude: 73.8567, city: 'Pune', locality: 'Pune'),
        'ahmedabad': LocationData(name: 'Ahmedabad, Gujarat, India', latitude: 23.0225, longitude: 72.5714, city: 'Ahmedabad', locality: 'Ahmedabad'),
        'jaipur': LocationData(name: 'Jaipur, Rajasthan, India', latitude: 26.9124, longitude: 75.7873, city: 'Jaipur', locality: 'Jaipur'),
        'surat': LocationData(name: 'Surat, Gujarat, India', latitude: 21.1702, longitude: 72.8311, city: 'Surat', locality: 'Surat'),
      };

      for (final entry in majorCities.entries) {
        if (description.contains(entry.key)) {
          DebugLogger.success('✅ Found coordinates for ${entry.key} using alternative method');
          return entry.value;
        }
      }

      // Method 2: Try using the mainText from suggestion as a search term
      if (suggestion.mainText.isNotEmpty) {
        DebugLogger.info('🔍 Trying to search for coordinates using main text: ${suggestion.mainText}');
        // This would require additional API calls, but for now we'll return null
        // In a full implementation, you could call a geocoding service here
      }

      DebugLogger.warning('❌ All alternative location methods failed for: ${suggestion.description}');
      return null;

    } catch (e, stackTrace) {
      DebugLogger.error('❌ Error in alternative location methods: $e', stackTrace);
      return null;
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

  // Debug method to test location search for specific cities
  Future<void> debugCitySearch(String cityName) async {
    DebugLogger.info('🔧 Starting debug for city: $cityName');
    await locationController.debugLocationSearch(cityName);
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