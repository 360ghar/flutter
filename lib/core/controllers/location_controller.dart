import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../data/models/unified_filter_model.dart';
import '../utils/debug_logger.dart';
import 'auth_controller.dart';

class LocationController extends GetxController {
  late final AuthController _authController;

  final Rxn<Position> currentPosition = Rxn<Position>();
  final RxBool isLocationEnabled = false.obs;
  final RxBool isLocationPermissionGranted = false.obs;
  final RxBool isLoading = false.obs;
  final RxString locationError = ''.obs;
  
  // Location search
  final RxList<Map<String, dynamic>> searchResults = <Map<String, dynamic>>[].obs;
  
  final RxString selectedCity = ''.obs;
  final RxString currentAddress = ''.obs;
  final RxString currentCity = ''.obs;
  
  // Google Places suggestions
  final RxList<PlaceSuggestion> placeSuggestions = <PlaceSuggestion>[].obs;
  final RxBool isSearchingPlaces = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    await _checkLocationService();
    await _requestLocationPermission();
    if (isLocationPermissionGranted.value && isLocationEnabled.value) {
      await getCurrentLocation();
    }
  }

  Future<void> _checkLocationService() async {
    try {
      isLocationEnabled.value = await Geolocator.isLocationServiceEnabled();
      if (!isLocationEnabled.value) {
        locationError.value = 'location_services_disabled'.tr;
        Get.snackbar(
          'location_services'.tr,
          'enable_location_services_message'.tr,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e, stackTrace) {
      locationError.value = 'failed_to_check_location_service'.tr;
      DebugLogger.error('Error checking location service', e, stackTrace);
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        isLocationPermissionGranted.value = false;
        locationError.value = 'location_permission_permanently_denied'.tr;
        Get.snackbar(
          'location_permission'.tr,
          'location_access_permanently_denied_message'.tr,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      
      if (permission == LocationPermission.denied) {
        isLocationPermissionGranted.value = false;
        locationError.value = 'location_permission_denied'.tr;
        Get.snackbar(
          'location_permission'.tr,
          'location_access_required_message'.tr,
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      
      isLocationPermissionGranted.value = true;
      locationError.value = '';
    } catch (e, stackTrace) {
      locationError.value = 'error_requesting_location_permission'.tr;
      DebugLogger.error('Error requesting location permission', e, stackTrace);
    }
  }

  Future<void> getCurrentLocation({bool forceRefresh = false}) async {
    if (!isLocationPermissionGranted.value || !isLocationEnabled.value) {
      await _checkLocationService();
      await _requestLocationPermission();
      return;
    }

    if (!forceRefresh && currentPosition.value != null) {
      // Use cached location if available and not forcing refresh
      return;
    }

    try {
      isLoading.value = true;
      locationError.value = '';
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
      
      currentPosition.value = position;
      
      // Update user location in backend
      if (_authController.isAuthenticated) {
        await _authController.updateUserLocation(
          position.latitude,
          position.longitude,
        );
      }
      
      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);
      
      
    } catch (e, stackTrace) {
      locationError.value = 'failed_to_get_current_location'.tr;
      DebugLogger.error('Error getting current location', e, stackTrace);

      Get.snackbar(
        'location_error'.tr,
        'failed_to_get_location_message'.tr,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        currentAddress.value = _formatAddress(placemark);
        
        // Set selected city from current location
        if (placemark.locality?.isNotEmpty == true) {
          selectedCity.value = placemark.locality!;
          currentCity.value = placemark.locality!;
        } else if (placemark.administrativeArea?.isNotEmpty == true) {
          selectedCity.value = placemark.administrativeArea!;
          currentCity.value = placemark.administrativeArea!;
        }
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting address from coordinates', e, stackTrace);
    }
  }

  String _formatAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.name?.isNotEmpty == true) {
      addressParts.add(placemark.name!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      addressParts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      addressParts.add(placemark.administrativeArea!);
    }
    if (placemark.country?.isNotEmpty == true) {
      addressParts.add(placemark.country!);
    }
    
    return addressParts.join(', ');
  }

  Future<void> searchLocations(String query) async {
    if (query.trim().isEmpty || query.length < 2) {
      searchResults.clear();
      return;
    }

    try {
      isLoading.value = true;
      
      // Use Google Places API for location search
      final results = await _searchGooglePlaces(query.trim());
      searchResults.value = results;
      
    } catch (e, stackTrace) {
      DebugLogger.error('Error searching locations', e, stackTrace);
      Get.snackbar(
        'search_error'.tr,
        'failed_to_search_locations'.tr,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _searchGooglePlaces(String query) async {
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
      final countryCode = dotenv.env['DEFAULT_COUNTRY'] ?? 'in';

      if (apiKey == null || apiKey.isEmpty) {
        DebugLogger.warning('Google Places API key not found');
        return [];
      }

      final url = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': query,
        'types': '(cities)',
        'components': 'country:$countryCode',
        'key': apiKey,
      });

      // Add timeout and error handling
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        DebugLogger.error('Google Places API request failed: ${response.statusCode}');
        DebugLogger.error('Response body: ${response.body}');
        return [];
      }

      final data = json.decode(response.body);
      final status = data['status'];

      switch (status) {
        case 'OK':
          final predictions = data['predictions'] as List;
          return predictions.map((prediction) => {
            'id': prediction['place_id'],
            'name': prediction['description'],
            'city': prediction['structured_formatting']['main_text'],
            'region': prediction['structured_formatting']['secondary_text'],
            'type': 'google_places'
          }).toList();

        case 'ZERO_RESULTS':
          DebugLogger.info('Google Places API returned no results for query: $query');
          return [];

        case 'OVER_QUERY_LIMIT':
          DebugLogger.error('Google Places API quota exceeded for query: $query');
          DebugLogger.error('Response: ${response.body}');
          // Could implement retry logic with backoff here
          return [];

        case 'REQUEST_DENIED':
          DebugLogger.error('Google Places API request denied for query: $query');
          DebugLogger.error('Response: ${response.body}');
          // Could check API key validity here
          return [];

        case 'INVALID_REQUEST':
          DebugLogger.error('Invalid Google Places API request for query: $query');
          DebugLogger.error('Response: ${response.body}');
          return [];

        default:
          DebugLogger.warning('Unknown Google Places API status: $status for query: $query');
          DebugLogger.warning('Response: ${response.body}');
          return [];
      }
    } on TimeoutException catch (e) {
      DebugLogger.error('Google Places API request timed out for query: $query', e);
      return [];
    } catch (e, stackTrace) {
      DebugLogger.error('Error calling Google Places API for query: $query', e, stackTrace);
      return [];
    }
  }


  void selectLocation(Map<String, dynamic> location) {
    selectedCity.value = location['name'] ?? location['city'] ?? '';
    
    
    Get.snackbar(
      'location_selected'.tr,
      'location_selected_message'.tr + selectedCity.value,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  void selectCity(String cityName) {
    selectedCity.value = cityName;
    
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'unable_to_open_location_settings'.tr,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'unable_to_open_app_settings'.tr,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  double? get currentLatitude => currentPosition.value?.latitude;
  double? get currentLongitude => currentPosition.value?.longitude;
  
  bool get hasLocation => currentPosition.value != null;
  
  String get locationStatusText {
    if (!isLocationEnabled.value) return 'location_services_disabled'.tr;
    if (!isLocationPermissionGranted.value) return 'location_permission_denied'.tr;
    if (isLoading.value) return 'getting_location'.tr;
    if (hasLocation) return currentAddress.value.isNotEmpty ? currentAddress.value : 'location_found'.tr;
    return 'location_not_available'.tr;
  }

  Map<String, dynamic> get locationSummary => {
    'hasPermission': isLocationPermissionGranted.value,
    'serviceEnabled': isLocationEnabled.value,
    'hasLocation': hasLocation,
    'latitude': currentLatitude,
    'longitude': currentLongitude,
    'address': currentAddress.value,
    'selectedCity': selectedCity.value,
  };

  void clearSearchResults() {
    searchResults.clear();
  }

  void clearLocationError() {
    locationError.value = '';
  }

  // Distance calculation helper
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to kilometers
  }

  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()}m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceInKm.round()}km';
    }
  }

  // Google Places API methods with fallback
  Future<List<PlaceSuggestion>> getPlaceSuggestions(String query) async {
    if (query.trim().isEmpty || query.length < 2) {
      placeSuggestions.clear();
      return [];
    }

    try {
      isSearchingPlaces.value = true;

      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      final countryCode = dotenv.env['DEFAULT_COUNTRY'] ?? 'in';

      if (apiKey.isEmpty) {
        DebugLogger.error('CRITICAL: GOOGLE_PLACES_API_KEY is missing from your .env file. Location search will not work.');
        return await _fallbackLocationSearch(query);
      }

      final url = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': query,
        'types': '(cities)',
        'components': 'country:$countryCode',
        'key': apiKey,
      });

      // Add timeout and error handling
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        DebugLogger.error('Google Places API request failed: ${response.statusCode}');
        DebugLogger.error('Response body: ${response.body}');
        return await _fallbackLocationSearch(query);
      }

      final data = json.decode(response.body);
      final status = data['status'];

      switch (status) {
        case 'OK':
          final predictions = data['predictions'] as List;
          if (predictions.isEmpty) {
            DebugLogger.info('Google Places API returned no results for query: $query');
            return await _fallbackLocationSearch(query);
          }

          final suggestions = predictions.map((prediction) {
            return PlaceSuggestion(
              placeId: prediction['place_id'],
              description: prediction['description'],
              mainText: prediction['structured_formatting']?['main_text'] ?? '',
              secondaryText: prediction['structured_formatting']?['secondary_text'] ?? '',
            );
          }).toList();

          placeSuggestions.value = suggestions;
          return suggestions;

        case 'ZERO_RESULTS':
          DebugLogger.info('Google Places API returned no results for query: $query');
          return await _fallbackLocationSearch(query);

        case 'OVER_QUERY_LIMIT':
        case 'REQUEST_DENIED':
        case 'INVALID_REQUEST':
          DebugLogger.error('Google Places API error: $status for query: $query');
          DebugLogger.error('Response: ${response.body}');
          return await _fallbackLocationSearch(query);

        default:
          DebugLogger.warning('Unknown Google Places API status: $status for query: $query');
          return await _fallbackLocationSearch(query);
      }
    } on TimeoutException catch (e) {
      DebugLogger.error('Google Places API request timed out for query: $query', e);
      return await _fallbackLocationSearch(query);
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting place suggestions for query: $query', e, stackTrace);
      return await _fallbackLocationSearch(query);
    } finally {
      isSearchingPlaces.value = false;
    }
  }

  // Fallback location search when Google Places API fails
  Future<List<PlaceSuggestion>> _fallbackLocationSearch(String query) async {
    try {
      DebugLogger.info('Using fallback location search for: $query');

      // Use static Indian cities as fallback
      final fallbackCities = [
        {'name': 'Mumbai', 'state': 'Maharashtra', 'lat': 19.0760, 'lng': 72.8777},
        {'name': 'Delhi', 'state': 'Delhi', 'lat': 28.7041, 'lng': 77.1025},
        {'name': 'Bangalore', 'state': 'Karnataka', 'lat': 12.9716, 'lng': 77.5946},
        {'name': 'Hyderabad', 'state': 'Telangana', 'lat': 17.3850, 'lng': 78.4867},
        {'name': 'Chennai', 'state': 'Tamil Nadu', 'lat': 13.0827, 'lng': 80.2707},
        {'name': 'Kolkata', 'state': 'West Bengal', 'lat': 22.5726, 'lng': 88.3639},
        {'name': 'Pune', 'state': 'Maharashtra', 'lat': 18.5204, 'lng': 73.8567},
        {'name': 'Ahmedabad', 'state': 'Gujarat', 'lat': 23.0225, 'lng': 72.5714},
        {'name': 'Jaipur', 'state': 'Rajasthan', 'lat': 26.9124, 'lng': 75.7873},
        {'name': 'Surat', 'state': 'Gujarat', 'lat': 21.1702, 'lng': 72.8311},
      ];

      // Filter cities based on query
      final filteredCities = fallbackCities.where((city) {
        final name = city['name'] as String;
        final state = city['state'] as String;
        return name.toLowerCase().contains(query.toLowerCase()) ||
               state.toLowerCase().contains(query.toLowerCase());
      }).toList();

      if (filteredCities.isEmpty) {
        // Return all cities if no matches
        final suggestions = fallbackCities.map((city) {
          return PlaceSuggestion(
            placeId: '${city['name']}_${city['state']}',
            description: '${city['name']}, ${city['state']}, India',
            mainText: city['name'] as String,
            secondaryText: city['state'] as String,
          );
        }).toList();

        placeSuggestions.value = suggestions;
        return suggestions;
      }

      // Return filtered cities
      final suggestions = filteredCities.map((city) {
        return PlaceSuggestion(
          placeId: '${city['name']}_${city['state']}',
          description: '${city['name']}, ${city['state']}, India',
          mainText: city['name'] as String,
          secondaryText: city['state'] as String,
        );
      }).toList();

      placeSuggestions.value = suggestions;
      return suggestions;

    } catch (e, stackTrace) {
      DebugLogger.error('Error in fallback location search: $e', stackTrace);
      placeSuggestions.clear();
      return [];
    }
  }

  Future<LocationData?> getPlaceDetails(String placeId) async {
    try {
      isLoading.value = true;

      // Check if this is a fallback city (from our static list)
      if (placeId.contains('_')) {
        return await _getFallbackCityDetails(placeId);
      }

      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        DebugLogger.warning('Google Places API key not found, using fallback');
        return await _getFallbackCityDetails(placeId);
      }

      final url = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
        'place_id': placeId,
        'fields': 'name,geometry,address_components',
        'key': apiKey,
      });

      // Add timeout and error handling
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        DebugLogger.error('Google Places Details API request failed: ${response.statusCode}');
        DebugLogger.error('Response body: ${response.body}');
        return await _getFallbackCityDetails(placeId);
      }

      final data = json.decode(response.body);
      final status = data['status'];

      switch (status) {
        case 'OK':
          final result = data['result'];
          if (result != null) {
            final location = result['geometry']['location'];
            final addressComponents = result['address_components'] as List;

            String? city;
            String? locality;

            for (final component in addressComponents) {
              final types = component['types'] as List;
              if (types.contains('locality')) {
                locality = component['long_name'];
              }
              if (types.contains('administrative_area_level_2')) {
                city = component['long_name'];
              }
            }

            return LocationData(
              name: result['name'] ?? '',
              latitude: location['lat'].toDouble(),
              longitude: location['lng'].toDouble(),
              city: city,
              locality: locality,
            );
          }
          DebugLogger.warning('Google Places Details API returned null result for placeId: $placeId');
          return await _getFallbackCityDetails(placeId);

        case 'ZERO_RESULTS':
        case 'NOT_FOUND':
          DebugLogger.info('Google Places Details API returned no results for placeId: $placeId');
          return await _getFallbackCityDetails(placeId);

        case 'OVER_QUERY_LIMIT':
        case 'REQUEST_DENIED':
        case 'INVALID_REQUEST':
          DebugLogger.error('Google Places Details API error: $status for placeId: $placeId');
          return await _getFallbackCityDetails(placeId);

        default:
          DebugLogger.warning('Unknown Google Places Details API status: $status for placeId: $placeId');
          return await _getFallbackCityDetails(placeId);
      }
    } on TimeoutException catch (e) {
      DebugLogger.error('Google Places Details API request timed out for placeId: $placeId', e);
      return await _getFallbackCityDetails(placeId);
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting place details for placeId: $placeId', e, stackTrace);
      return await _getFallbackCityDetails(placeId);
    } finally {
      isLoading.value = false;
    }
  }

  // Get details for fallback cities
  Future<LocationData?> _getFallbackCityDetails(String placeId) async {
    try {
      DebugLogger.info('Using fallback city details for: $placeId');

      final fallbackCities = [
        {'name': 'Mumbai', 'state': 'Maharashtra', 'lat': 19.0760, 'lng': 72.8777},
        {'name': 'Delhi', 'state': 'Delhi', 'lat': 28.7041, 'lng': 77.1025},
        {'name': 'Bangalore', 'state': 'Karnataka', 'lat': 12.9716, 'lng': 77.5946},
        {'name': 'Hyderabad', 'state': 'Telangana', 'lat': 17.3850, 'lng': 78.4867},
        {'name': 'Chennai', 'state': 'Tamil Nadu', 'lat': 13.0827, 'lng': 80.2707},
        {'name': 'Kolkata', 'state': 'West Bengal', 'lat': 22.5726, 'lng': 88.3639},
        {'name': 'Pune', 'state': 'Maharashtra', 'lat': 18.5204, 'lng': 73.8567},
        {'name': 'Ahmedabad', 'state': 'Gujarat', 'lat': 23.0225, 'lng': 72.5714},
        {'name': 'Jaipur', 'state': 'Rajasthan', 'lat': 26.9124, 'lng': 75.7873},
        {'name': 'Surat', 'state': 'Gujarat', 'lat': 21.1702, 'lng': 72.8311},
      ];

      // Find the city by placeId
      final city = fallbackCities.cast<Map<String, Object>>().firstWhere(
        (city) => '${city['name']}_${city['state']}' == placeId,
        orElse: () => <String, Object>{},
      );

      if (city.isNotEmpty) {
        return LocationData(
          name: '${city['name']}, ${city['state']}, India',
          latitude: city['lat'] as double,
          longitude: city['lng'] as double,
          city: city['name'] as String,
          locality: city['name'] as String,
        );
      }

      DebugLogger.warning('Fallback city not found for placeId: $placeId');
      return null;

    } catch (e, stackTrace) {
      DebugLogger.error('Error getting fallback city details: $e', stackTrace);
      return null;
    }
  }

  void clearPlaceSuggestions() {
    placeSuggestions.clear();
  }

  @override
  void onClose() {
    // Clean up any location streams if using them
    super.onClose();
  }
}

// Place suggestion model
class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}