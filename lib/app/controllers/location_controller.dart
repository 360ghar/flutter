import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../data/providers/api_service.dart';
import 'auth_controller.dart';

class LocationController extends GetxController {
  late final ApiService _apiService;
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

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
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
        locationError.value = 'Location services are disabled';
        Get.snackbar(
          'Location Services',
          'Please enable location services to use location features',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      locationError.value = 'Failed to check location service';
      print('Error checking location service: $e');
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
        locationError.value = 'Location permission permanently denied';
        Get.snackbar(
          'Location Permission',
          'Location access is permanently denied. Please enable it in settings.',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      
      if (permission == LocationPermission.denied) {
        isLocationPermissionGranted.value = false;
        locationError.value = 'Location permission denied';
        Get.snackbar(
          'Location Permission',
          'Location access is required for nearby properties and better recommendations.',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      
      isLocationPermissionGranted.value = true;
      locationError.value = '';
    } catch (e) {
      locationError.value = 'Error requesting location permission';
      print('Error requesting location permission: $e');
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
      
      
    } catch (e) {
      locationError.value = 'Failed to get current location';
      print('Error getting current location: $e');
      
      Get.snackbar(
        'Location Error',
        'Failed to get your current location. Please try again.',
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
        } else if (placemark.administrativeArea?.isNotEmpty == true) {
          selectedCity.value = placemark.administrativeArea!;
        }
      }
    } catch (e) {
      print('Error getting address from coordinates: $e');
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
      
      if (_authController.isAuthenticated) {
        final results = await _apiService.searchLocations(query.trim());
        searchResults.value = results;
      } else {
        // Fallback to local search or mock data
        searchResults.clear();
      }
    } catch (e) {
      print('Error searching locations: $e');
      Get.snackbar(
        'Search Error',
        'Failed to search locations',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }


  void selectLocation(Map<String, dynamic> location) {
    selectedCity.value = location['name'] ?? location['city'] ?? '';
    
    // Track location selection
    if (_authController.isAuthenticated) {
      _apiService.trackEvent('location_selected', {
        'location_id': location['id'],
        'location_name': location['name'] ?? location['city'],
        'selection_source': 'search',
      });
    }
    
    Get.snackbar(
      'Location Selected',
      'Selected: ${selectedCity.value}',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  void selectCity(String cityName) {
    selectedCity.value = cityName;
    
    // Track city selection
    if (_authController.isAuthenticated) {
      _apiService.trackEvent('city_selected', {
        'city_name': cityName,
        'selection_source': 'city_list',
      });
    }
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to open location settings',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to open app settings',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  double? get currentLatitude => currentPosition.value?.latitude;
  double? get currentLongitude => currentPosition.value?.longitude;
  
  bool get hasLocation => currentPosition.value != null;
  
  String get locationStatusText {
    if (!isLocationEnabled.value) return 'Location services disabled';
    if (!isLocationPermissionGranted.value) return 'Location permission denied';
    if (isLoading.value) return 'Getting location...';
    if (hasLocation) return currentAddress.value.isNotEmpty ? currentAddress.value : 'Location found';
    return 'Location not available';
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

  @override
  void onClose() {
    // Clean up any location streams if using them
    super.onClose();
  }
}