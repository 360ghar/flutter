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

      // Log the autocomplete API request
      DebugLogger.api('🔍 AUTOCOMPLETE API REQUEST:');
      DebugLogger.api('   URL: ${url.toString()}');
      DebugLogger.api('   Endpoint: /maps/api/place/autocomplete/json');
      DebugLogger.api('   Query Params: ${url.queryParameters}');
      DebugLogger.api('   Search Query: $query');
      DebugLogger.api('   Country Code: $countryCode');
      DebugLogger.api('   API Key Present: ${apiKey.isNotEmpty ? "Yes" : "No"}');

      // Add timeout and error handling
      final startTime = DateTime.now();
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log the autocomplete API response
      DebugLogger.api('📨 AUTOCOMPLETE API RESPONSE:');
      DebugLogger.api('   Status Code: ${response.statusCode}');
      DebugLogger.api('   Response Time: ${duration.inMilliseconds}ms');
      DebugLogger.api('   Response Body: ${response.body}');

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
        {'name': 'Lucknow', 'state': 'Uttar Pradesh', 'lat': 26.8467, 'lng': 80.9462},
        {'name': 'Kanpur', 'state': 'Uttar Pradesh', 'lat': 26.4499, 'lng': 80.3319},
        {'name': 'Nagpur', 'state': 'Maharashtra', 'lat': 21.1458, 'lng': 79.0882},
        {'name': 'Indore', 'state': 'Madhya Pradesh', 'lat': 22.7196, 'lng': 75.8577},
        {'name': 'Thane', 'state': 'Maharashtra', 'lat': 19.2183, 'lng': 72.9781},
        {'name': 'Bhopal', 'state': 'Madhya Pradesh', 'lat': 23.2599, 'lng': 77.4126},
        {'name': 'Visakhapatnam', 'state': 'Andhra Pradesh', 'lat': 17.6868, 'lng': 83.2185},
        {'name': 'Pimpri-Chinchwad', 'state': 'Maharashtra', 'lat': 18.6298, 'lng': 73.7997},
        {'name': 'Patna', 'state': 'Bihar', 'lat': 25.5941, 'lng': 85.1376},
        {'name': 'Vadodara', 'state': 'Gujarat', 'lat': 22.3072, 'lng': 73.1812},
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
        'fields': 'name,geometry,address_components,formatted_address',
        'key': apiKey,
      });

      // Log the exact API request being made
      DebugLogger.api('🔍 PLACE DETAILS API REQUEST:');
      DebugLogger.api('   URL: ${url.toString()}');
      DebugLogger.api('   Endpoint: /maps/api/place/details/json');
      DebugLogger.api('   Query Params: ${url.queryParameters}');
      DebugLogger.api('   Place ID: $placeId');
      DebugLogger.api('   API Key Present: ${apiKey.isNotEmpty ? "Yes" : "No"}');

      // Add timeout and error handling
      final startTime = DateTime.now();
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log the response details
      DebugLogger.api('📨 PLACE DETAILS API RESPONSE:');
      DebugLogger.api('   Status Code: ${response.statusCode}');
      DebugLogger.api('   Response Time: ${duration.inMilliseconds}ms');
      DebugLogger.api('   Headers: ${response.headers}');
      DebugLogger.api('   Response Body: ${response.body}');

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
            final formattedAddress = result['formatted_address'] ?? '';

            String? city;
            String? locality;
            String? state;

            for (final component in addressComponents) {
              final types = component['types'] as List;
              if (types.contains('locality')) {
                locality = component['long_name'];
              }
              if (types.contains('administrative_area_level_2') || types.contains('administrative_area_level_1')) {
                city = component['long_name'];
              }
              if (types.contains('administrative_area_level_1')) {
                state = component['long_name'];
              }
            }

            // Use locality as city if city is not found
            if (city == null && locality != null) {
              city = locality;
            }

            return LocationData(
              name: result['name'] ?? formattedAddress,
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
          DebugLogger.error('🚫 Google Places Details API OVER_QUERY_LIMIT: Daily quota exceeded for placeId: $placeId');
          DebugLogger.error('💡 Consider upgrading your Google Maps API plan or reducing API calls');
          return await _getFallbackCityDetails(placeId);

        case 'REQUEST_DENIED':
          DebugLogger.error('🚫 Google Places Details API REQUEST_DENIED: API key invalid or not authorized for placeId: $placeId');
          DebugLogger.error('💡 Check your GOOGLE_PLACES_API_KEY in .env file and ensure Places API is enabled');
          return await _getFallbackCityDetails(placeId);

        case 'INVALID_REQUEST':
          DebugLogger.error('🚫 Google Places Details API INVALID_REQUEST: Malformed request for placeId: $placeId');
          DebugLogger.error('💡 Check if placeId format is correct');
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
        {'name': 'Lucknow', 'state': 'Uttar Pradesh', 'lat': 26.8467, 'lng': 80.9462},
        {'name': 'Kanpur', 'state': 'Uttar Pradesh', 'lat': 26.4499, 'lng': 80.3319},
        {'name': 'Nagpur', 'state': 'Maharashtra', 'lat': 21.1458, 'lng': 79.0882},
        {'name': 'Indore', 'state': 'Madhya Pradesh', 'lat': 22.7196, 'lng': 75.8577},
        {'name': 'Thane', 'state': 'Maharashtra', 'lat': 19.2183, 'lng': 72.9781},
        {'name': 'Bhopal', 'state': 'Madhya Pradesh', 'lat': 23.2599, 'lng': 77.4126},
        {'name': 'Visakhapatnam', 'state': 'Andhra Pradesh', 'lat': 17.6868, 'lng': 83.2185},
        {'name': 'Pimpri-Chinchwad', 'state': 'Maharashtra', 'lat': 18.6298, 'lng': 73.7997},
        {'name': 'Patna', 'state': 'Bihar', 'lat': 25.5941, 'lng': 85.1376},
        {'name': 'Vadodara', 'state': 'Gujarat', 'lat': 22.3072, 'lng': 73.1812},
      ];

      // Find the city by placeId (for fallback cities)
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

      // If not found by placeId, try to extract city name from Google Places placeId
      // Google Places placeIds are long alphanumeric strings, not our fallback format
      if (!placeId.contains('_')) {
        // This is likely a Google Places API placeId, try to get coordinates using reverse geocoding
        return await _getCoordinatesFromGooglePlaceId(placeId);
      }

      DebugLogger.warning('Fallback city not found for placeId: $placeId');
      return null;

    } catch (e, stackTrace) {
      DebugLogger.error('Error getting fallback city details: $e', stackTrace);
      return null;
    }
  }

  // Get coordinates from Google Places placeId when fallback fails
  Future<LocationData?> _getCoordinatesFromGooglePlaceId(String placeId) async {
    try {
      DebugLogger.info('Attempting to get coordinates for Google Places placeId: $placeId');

      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        DebugLogger.error('No Google Places API key available for coordinate lookup');
        return null;
      }

      final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'place_id': placeId,
        'key': apiKey,
      });

      // Log the geocoding API request
      DebugLogger.api('🔍 GEOCODING API REQUEST:');
      DebugLogger.api('   URL: ${url.toString()}');
      DebugLogger.api('   Endpoint: /maps/api/geocode/json');
      DebugLogger.api('   Query Params: ${url.queryParameters}');
      DebugLogger.api('   Place ID: $placeId');
      DebugLogger.api('   API Key Present: ${apiKey.isNotEmpty ? "Yes" : "No"}');

      final startTime = DateTime.now();
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Log the geocoding API response
      DebugLogger.api('📨 GEOCODING API RESPONSE:');
      DebugLogger.api('   Status Code: ${response.statusCode}');
      DebugLogger.api('   Response Time: ${duration.inMilliseconds}ms');
      DebugLogger.api('   Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];

        if (status == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];
          final addressComponents = result['address_components'] as List;

          String? city;
          String? locality;

          for (final component in addressComponents) {
            final types = component['types'] as List;
            if (types.contains('locality')) {
              locality = component['long_name'];
            }
            if (types.contains('administrative_area_level_2') || types.contains('administrative_area_level_1')) {
              city = component['long_name'];
            }
          }

          // Use locality as city if city is not found
          if (city == null && locality != null) {
            city = locality;
          }

          return LocationData(
            name: result['formatted_address'] ?? 'Unknown Location',
            latitude: location['lat'].toDouble(),
            longitude: location['lng'].toDouble(),
            city: city,
            locality: locality,
          );
        }
      }

      DebugLogger.warning('Failed to get coordinates for Google Places placeId: $placeId');
      return null;

    } catch (e, stackTrace) {
      DebugLogger.error('Error getting coordinates from Google Places placeId: $e', stackTrace);
      return null;
    }
  }

  // Test API key validity and get usage information
  Future<Map<String, dynamic>> testApiKeyValidity() async {
    final result = {
      'isValid': false,
      'error': '',
      'quotaExceeded': false,
      'apiEnabled': false,
      'suggestions': <String>[],
    };

    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        result['error'] = 'GOOGLE_PLACES_API_KEY not found in .env file';
        result['suggestions'] = ['Add GOOGLE_PLACES_API_KEY to your .env.development file'];
        return result;
      }

      // Test with a simple query
      final url = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': 'Mumbai',
        'types': '(cities)',
        'components': 'country:in',
        'key': apiKey,
      });

      DebugLogger.info('🧪 Testing Google Places API key validity...');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      result['statusCode'] = response.statusCode;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];

        switch (status) {
          case 'OK':
            result['isValid'] = true;
            result['apiEnabled'] = true;
            result['suggestions'] = ['API key is valid and working correctly'];
            break;

          case 'OVER_QUERY_LIMIT':
            result['error'] = 'Daily quota exceeded';
            result['quotaExceeded'] = true;
            result['suggestions'] = [
              'Upgrade your Google Maps API plan',
              'Reduce API call frequency',
              'Enable billing for higher quotas'
            ];
            break;

          case 'REQUEST_DENIED':
            result['error'] = 'API key not authorized';
            result['suggestions'] = [
              'Enable Places API in Google Cloud Console',
              'Check API key restrictions',
              'Verify billing is enabled'
            ];
            break;

          case 'INVALID_REQUEST':
            result['error'] = 'Invalid API request';
            result['suggestions'] = [
              'Check API key format',
              'Verify Places API is enabled'
            ];
            break;

          default:
            result['error'] = 'Unknown API response: $status';
            result['suggestions'] = ['Check Google API status and your configuration'];
        }
      } else {
        result['error'] = 'HTTP ${response.statusCode}: ${response.body}';
        result['suggestions'] = ['Check network connectivity', 'Verify API key'];
      }

      DebugLogger.info('🧪 API Key Test Result: ${result}');

    } catch (e) {
      result['error'] = 'Exception: $e';
      result['suggestions'] = ['Check network connectivity', 'Verify .env configuration'];
      DebugLogger.error('❌ API Key Test Failed: $e');
    }

    return result;
  }

  // Enhanced fallback mechanism that can detect valid cities even when API fails
  Future<LocationData?> getEnhancedLocationDetails(String placeId, String originalQuery) async {
    try {
      DebugLogger.info('🔄 Starting enhanced location resolution for: $originalQuery (placeId: $placeId)');

      // First, try the standard API approach
      final apiResult = await getPlaceDetails(placeId);
      if (apiResult != null) {
        DebugLogger.success('✅ Standard API resolution successful');
        return apiResult;
      }

      DebugLogger.warning('⚠️ Standard API resolution failed, trying enhanced fallback');

      // Enhanced fallback: Check if the original query contains a valid city name
      final queryLower = originalQuery.toLowerCase();

      // Extended list of Indian cities with coordinates
      final cityCoordinates = {
        'mumbai': {'lat': 19.0760, 'lng': 72.8777, 'state': 'Maharashtra'},
        'delhi': {'lat': 28.7041, 'lng': 77.1025, 'state': 'Delhi'},
        'bangalore': {'lat': 12.9716, 'lng': 77.5946, 'state': 'Karnataka'},
        'bengaluru': {'lat': 12.9716, 'lng': 77.5946, 'state': 'Karnataka'},
        'hyderabad': {'lat': 17.3850, 'lng': 78.4867, 'state': 'Telangana'},
        'chennai': {'lat': 13.0827, 'lng': 80.2707, 'state': 'Tamil Nadu'},
        'kolkata': {'lat': 22.5726, 'lng': 88.3639, 'state': 'West Bengal'},
        'pune': {'lat': 18.5204, 'lng': 73.8567, 'state': 'Maharashtra'},
        'ahmedabad': {'lat': 23.0225, 'lng': 72.5714, 'state': 'Gujarat'},
        'jaipur': {'lat': 26.9124, 'lng': 75.7873, 'state': 'Rajasthan'},
        'surat': {'lat': 21.1702, 'lng': 72.8311, 'state': 'Gujarat'},
        'lucknow': {'lat': 26.8467, 'lng': 80.9462, 'state': 'Uttar Pradesh'},
        'kanpur': {'lat': 26.4499, 'lng': 80.3319, 'state': 'Uttar Pradesh'},
        'nagpur': {'lat': 21.1458, 'lng': 79.0882, 'state': 'Maharashtra'},
        'indore': {'lat': 22.7196, 'lng': 75.8577, 'state': 'Madhya Pradesh'},
        'thane': {'lat': 19.2183, 'lng': 72.9781, 'state': 'Maharashtra'},
        'bhopal': {'lat': 23.2599, 'lng': 77.4126, 'state': 'Madhya Pradesh'},
        'visakhapatnam': {'lat': 17.6868, 'lng': 83.2185, 'state': 'Andhra Pradesh'},
        'pimpri-chinchwad': {'lat': 18.6298, 'lng': 73.7997, 'state': 'Maharashtra'},
        'patna': {'lat': 25.5941, 'lng': 85.1376, 'state': 'Bihar'},
        'vadodara': {'lat': 22.3072, 'lng': 73.1812, 'state': 'Gujarat'},
        'gwalior': {'lat': 26.2183, 'lng': 78.1828, 'state': 'Madhya Pradesh'},
        'coimbatore': {'lat': 11.0168, 'lng': 76.9558, 'state': 'Tamil Nadu'},
        'kochi': {'lat': 9.9312, 'lng': 76.2673, 'state': 'Kerala'},
        'kozhikode': {'lat': 11.2588, 'lng': 75.7804, 'state': 'Kerala'},
        'trivandrum': {'lat': 8.5241, 'lng': 76.9366, 'state': 'Kerala'},
        'mysore': {'lat': 12.2958, 'lng': 76.6394, 'state': 'Karnataka'},
        'raipur': {'lat': 21.2514, 'lng': 81.6296, 'state': 'Chhattisgarh'},
        'jabalpur': {'lat': 23.1815, 'lng': 79.9864, 'state': 'Madhya Pradesh'},
        'udaipur': {'lat': 24.5854, 'lng': 73.7125, 'state': 'Rajasthan'},
        'jodhpur': {'lat': 26.2389, 'lng': 73.0243, 'state': 'Rajasthan'},
        'ajmer': {'lat': 26.4499, 'lng': 74.6399, 'state': 'Rajasthan'},
        'bikaner': {'lat': 28.0229, 'lng': 73.3119, 'state': 'Rajasthan'},
        'allahabad': {'lat': 25.4358, 'lng': 81.8463, 'state': 'Uttar Pradesh'},
        'prayagraj': {'lat': 25.4358, 'lng': 81.8463, 'state': 'Uttar Pradesh'},
        'varanasi': {'lat': 25.3176, 'lng': 82.9739, 'state': 'Uttar Pradesh'},
        'meerut': {'lat': 28.9845, 'lng': 77.7064, 'state': 'Uttar Pradesh'},
        'agra': {'lat': 27.1767, 'lng': 78.0081, 'state': 'Uttar Pradesh'},
        'ghaziabad': {'lat': 28.6692, 'lng': 77.4538, 'state': 'Uttar Pradesh'},
        'noida': {'lat': 28.5355, 'lng': 77.3910, 'state': 'Uttar Pradesh'},
        'faridabad': {'lat': 28.4089, 'lng': 77.3178, 'state': 'Haryana'},
        'gurugram': {'lat': 28.4595, 'lng': 77.0266, 'state': 'Haryana'},
        'gurgaon': {'lat': 28.4595, 'lng': 77.0266, 'state': 'Haryana'},
        'panipat': {'lat': 29.3909, 'lng': 76.9635, 'state': 'Haryana'},
        'ambala': {'lat': 30.3782, 'lng': 76.7767, 'state': 'Haryana'},
        'chandigarh': {'lat': 30.7333, 'lng': 76.7794, 'state': 'Chandigarh'},
        'ludhiana': {'lat': 30.9010, 'lng': 75.8573, 'state': 'Punjab'},
        'amritsar': {'lat': 31.6340, 'lng': 74.8723, 'state': 'Punjab'},
        'jalandhar': {'lat': 31.3260, 'lng': 75.5762, 'state': 'Punjab'},
        'patiala': {'lat': 30.3398, 'lng': 76.3869, 'state': 'Punjab'},
        'bathinda': {'lat': 30.2100, 'lng': 74.9455, 'state': 'Punjab'},
        'dehradun': {'lat': 30.3165, 'lng': 78.0322, 'state': 'Uttarakhand'},
        'haridwar': {'lat': 29.9457, 'lng': 78.1642, 'state': 'Uttarakhand'},
        'roorkee': {'lat': 29.8543, 'lng': 77.8880, 'state': 'Uttarakhand'},
        ' Haldwani': {'lat': 29.2183, 'lng': 79.5127, 'state': 'Uttarakhand'},
      };

      // Check if query contains a known city
      for (final entry in cityCoordinates.entries) {
        if (queryLower.contains(entry.key)) {
          final coords = entry.value;
          DebugLogger.success('✅ Found city coordinates using enhanced fallback: ${entry.key}');

          return LocationData(
            name: '${entry.key[0].toUpperCase() + entry.key.substring(1)} ${coords['state']}, India',
            latitude: coords['lat'] as double,
            longitude: coords['lng'] as double,
            city: entry.key[0].toUpperCase() + entry.key.substring(1),
            locality: entry.key[0].toUpperCase() + entry.key.substring(1),
          );
        }
      }

      // If no exact match, try partial matching
      for (final entry in cityCoordinates.entries) {
        if (entry.key.contains(queryLower) || queryLower.contains(entry.key)) {
          final coords = entry.value;
          DebugLogger.success('✅ Found partial city match using enhanced fallback: ${entry.key}');

          return LocationData(
            name: '${entry.key[0].toUpperCase() + entry.key.substring(1)} ${coords['state']}, India',
            latitude: coords['lat'] as double,
            longitude: coords['lng'] as double,
            city: entry.key[0].toUpperCase() + entry.key.substring(1),
            locality: entry.key[0].toUpperCase() + entry.key.substring(1),
          );
        }
      }

      DebugLogger.warning('❌ Enhanced fallback also failed for: $originalQuery');
      return null;

    } catch (e, stackTrace) {
      DebugLogger.error('❌ Error in enhanced location resolution: $e', stackTrace);
      return null;
    }
  }

  // Debug method to test location search for specific cities
  Future<void> debugLocationSearch(String cityName) async {
    DebugLogger.info('🔧 Starting location search debug for: $cityName');

    try {
      // Step 1: Test API key validity
      final apiTestResult = await testApiKeyValidity();
      DebugLogger.info('🧪 API Key Test Results:');
      DebugLogger.info('   Valid: ${apiTestResult['isValid']}');
      DebugLogger.info('   Error: ${apiTestResult['error']}');
      DebugLogger.info('   Suggestions: ${apiTestResult['suggestions']}');

      // Step 2: Test place suggestions
      DebugLogger.info('🔍 Testing place suggestions for: $cityName');
      final suggestions = await getPlaceSuggestions(cityName);
      DebugLogger.info('   Found ${suggestions.length} suggestions');

      for (var i = 0; i < suggestions.length; i++) {
        final suggestion = suggestions[i];
        DebugLogger.info('   Suggestion $i: ${suggestion.description} (placeId: ${suggestion.placeId})');

        // Step 3: Test place details for each suggestion
        DebugLogger.info('📍 Testing place details for suggestion $i');
        final details = await getPlaceDetails(suggestion.placeId);
        if (details != null) {
          DebugLogger.success('   ✅ Place details successful: ${details.name} (${details.latitude}, ${details.longitude})');
        } else {
          DebugLogger.error('   ❌ Place details failed for: ${suggestion.description}');

          // Step 4: Test enhanced fallback
          DebugLogger.info('🔄 Testing enhanced fallback for suggestion $i');
          final enhancedDetails = await getEnhancedLocationDetails(suggestion.placeId, suggestion.description);
          if (enhancedDetails != null) {
            DebugLogger.success('   ✅ Enhanced fallback successful: ${enhancedDetails.name} (${enhancedDetails.latitude}, ${enhancedDetails.longitude})');
          } else {
            DebugLogger.error('   ❌ Enhanced fallback also failed');
          }
        }
      }

      DebugLogger.success('🔧 Location search debug completed for: $cityName');

    } catch (e, stackTrace) {
      DebugLogger.error('❌ Error during location search debug: $e', stackTrace);
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