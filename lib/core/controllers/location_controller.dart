import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
      if (apiKey == null || apiKey.isEmpty) {
        DebugLogger.warning('Google Places API key not found');
        return [];
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeQueryComponent(query)}'
        '&types=(cities)'
        '&components=country:in'
        '&key=$apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          
          return predictions.map((prediction) => {
            'id': prediction['place_id'],
            'name': prediction['description'],
            'city': prediction['structured_formatting']['main_text'],
            'region': prediction['structured_formatting']['secondary_text'],
            'type': 'google_places'
          }).toList();
        } else {
          DebugLogger.warning('Google Places API error: ${data['status']}');
          return [];
        }
      } else {
        DebugLogger.error('Google Places API request failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      DebugLogger.error('Error calling Google Places API: $e');
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

  // Google Places API methods
  Future<List<PlaceSuggestion>> getPlaceSuggestions(String query) async {
    if (query.trim().isEmpty || query.length < 2) {
      placeSuggestions.clear();
      return [];
    }

    try {
      isSearchingPlaces.value = true;
      
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        DebugLogger.warning('Google Places API key not found');
        // Fallback to backend search
        await searchLocations(query);
        return [];
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&types=(cities)'
        '&components=country:in'
        '&key=$apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        
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
      } else {
        DebugLogger.error('Google Places API error: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting place suggestions', e, stackTrace);
      return [];
    } finally {
      isSearchingPlaces.value = false;
    }
  }

  Future<LocationData?> getPlaceDetails(String placeId) async {
    try {
      isLoading.value = true;
      
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        DebugLogger.warning('Google Places API key not found');
        return null;
      }

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,geometry,address_components'
        '&key=$apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      } else {
        DebugLogger.error('Google Places Details API error: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting place details', e, stackTrace);
    } finally {
      isLoading.value = false;
    }
    
    return null;
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