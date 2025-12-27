import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:http/http.dart' as http;

class LocationController extends GetxController {
  late final AuthController _authController;

  final Rxn<Position> currentPosition = Rxn<Position>();
  final RxBool isLocationEnabled = false.obs;
  final RxBool isLocationPermissionGranted = false.obs;
  final RxBool isLoading = false.obs;
  final RxString locationError = ''.obs;

  final RxString currentAddress = ''.obs;

  Future<void>? _permissionRequestInFlight;
  Future<void>? _streamStartInFlight;
  StreamSubscription<Position>? _positionStreamSubscription;

  Position? _lastBackendSyncPosition;
  DateTime? _lastBackendSyncAt;
  Position? _lastGeocodePosition;
  DateTime? _lastGeocodeAt;

  static const Duration _currentPositionStaleThreshold = Duration(minutes: 2);
  static const Duration _lastKnownMaxAge = Duration(minutes: 10);
  static const Duration _currentPositionTimeout = Duration(seconds: 12);
  static const Duration _backendSyncMinInterval = Duration(minutes: 2);
  static const double _backendSyncMinDistanceMeters = 250;
  static const Duration _geocodeMinInterval = Duration(minutes: 2);
  static const double _geocodeMinDistanceMeters = 100;
  static const int _streamDistanceFilterMeters = 25;

  // Google Places suggestions
  final RxList<PlaceSuggestion> placeSuggestions = <PlaceSuggestion>[].obs;
  final RxBool isSearchingPlaces = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authController = Get.find<AuthController>();
    // Defer location permission prompts and resolution to first use
  }

  // IP-based location fallback
  Future<LocationData?> getIpLocation() async {
    try {
      // Prefer ipapi.co which returns lat/lon/city reliably
      final uri = Uri.parse('https://ipapi.co/json/');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final double? lat = (data['latitude'] is num)
            ? (data['latitude'] as num).toDouble()
            : double.tryParse((data['latitude'] ?? '').toString());
        final double? lon = (data['longitude'] is num)
            ? (data['longitude'] as num).toDouble()
            : double.tryParse((data['longitude'] ?? '').toString());
        final String? city = (data['city'] as String?)?.trim();
        final String? region = (data['region'] as String?)?.trim();

        if (lat != null && lon != null) {
          DebugLogger.success('✅ IP-based location: $city, $region ($lat,$lon)');
          return LocationData(
            name: city != null && region != null ? '$city, $region' : (city ?? 'IP-based Location'),
            latitude: lat,
            longitude: lon,
          );
        }
      } else {
        DebugLogger.warning('IP location HTTP ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException catch (e) {
      DebugLogger.error('IP location request timed out', e);
    } catch (e, st) {
      DebugLogger.error('Failed to get IP-based location', e, st);
    }
    return null;
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

  Future<void> _requestLocationPermission() {
    final inFlight = _permissionRequestInFlight;
    if (inFlight != null) return inFlight;

    final future = _requestLocationPermissionInternal();
    _permissionRequestInFlight = future;
    return future.whenComplete(() {
      if (identical(_permissionRequestInFlight, future)) {
        _permissionRequestInFlight = null;
      }
    });
  }

  Future<void> _requestLocationPermissionInternal() async {
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

  Future<bool> _ensureLocationReady() async {
    await _checkLocationService();
    await _requestLocationPermission();
    return isLocationEnabled.value && isLocationPermissionGranted.value;
  }

  bool _isPositionFresh(Position position, Duration maxAge) {
    final timestamp = position.timestamp;
    return DateTime.now().difference(timestamp) <= maxAge;
  }

  double _distanceMeters(Position a, Position b) {
    return Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  bool _shouldRefreshGeocode(Position position) {
    if (currentAddress.value.isEmpty) return true;
    if (_lastGeocodeAt == null || _lastGeocodePosition == null) return true;
    final age = DateTime.now().difference(_lastGeocodeAt!);
    if (age >= _geocodeMinInterval) return true;
    return _distanceMeters(_lastGeocodePosition!, position) >= _geocodeMinDistanceMeters;
  }

  Future<void> _refreshAddressForPosition(Position position, {bool force = false}) async {
    if (!force && !_shouldRefreshGeocode(position)) return;
    await _getAddressFromCoordinates(position.latitude, position.longitude);
    _lastGeocodeAt = DateTime.now();
    _lastGeocodePosition = position;
  }

  bool _shouldSyncBackend(Position position) {
    if (!_authController.isAuthenticated) return false;
    if (_lastBackendSyncAt == null || _lastBackendSyncPosition == null) return true;
    final age = DateTime.now().difference(_lastBackendSyncAt!);
    if (age >= _backendSyncMinInterval) return true;
    return _distanceMeters(_lastBackendSyncPosition!, position) >= _backendSyncMinDistanceMeters;
  }

  Future<void> _syncBackendLocation(Position position) async {
    if (!_shouldSyncBackend(position)) return;
    try {
      await _authController.updateUserLocation({
        'current_latitude': position.latitude,
        'current_longitude': position.longitude,
      });
      _lastBackendSyncAt = DateTime.now();
      _lastBackendSyncPosition = position;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to update backend location', e, stackTrace);
    }
  }

  Future<void> _applyPosition(
    Position position, {
    bool allowBackendSync = true,
    bool forceGeocode = false,
  }) async {
    currentPosition.value = position;
    if (allowBackendSync) {
      await _syncBackendLocation(position);
    }
    await _refreshAddressForPosition(position, force: forceGeocode);
  }

  Future<Position?> _getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e, stackTrace) {
      DebugLogger.warning('Failed to read last known position', e, stackTrace);
      return null;
    }
  }

  Future<Position?> _getCurrentPositionWithTimeout() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(_currentPositionTimeout);
    } on TimeoutException catch (e) {
      DebugLogger.warning('Current position request timed out', e);
      return null;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to get current position', e, stackTrace);
      return null;
    }
  }

  Future<void> _startPositionStream() {
    if (_positionStreamSubscription != null) return Future.value();
    if (!isLocationPermissionGranted.value || !isLocationEnabled.value) {
      return Future.value();
    }

    final inFlight = _streamStartInFlight;
    if (inFlight != null) return inFlight;

    final future = _startPositionStreamInternal();
    _streamStartInFlight = future;
    return future.whenComplete(() {
      if (identical(_streamStartInFlight, future)) {
        _streamStartInFlight = null;
      }
    });
  }

  Future<void> _startPositionStreamInternal() async {
    try {
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: _streamDistanceFilterMeters,
            ),
          ).listen(
            (position) {
              unawaited(_applyPosition(position));
            },
            onError: (error) {
              DebugLogger.warning('Location stream error: $error');
            },
          );
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to start location stream', e, stackTrace);
    }
  }

  Future<void> getCurrentLocation({bool forceRefresh = false}) async {
    final ready = await _ensureLocationReady();
    if (!ready) return;

    final cached = currentPosition.value;
    if (!forceRefresh &&
        cached != null &&
        _isPositionFresh(cached, _currentPositionStaleThreshold)) {
      await _startPositionStream();
      return;
    }

    try {
      isLoading.value = true;
      locationError.value = '';

      Position? resolved;

      final lastKnown = await _getLastKnownPosition();
      if (lastKnown != null) {
        final lastKnownFresh = _isPositionFresh(lastKnown, _lastKnownMaxAge);
        if (lastKnownFresh || cached == null) {
          await _applyPosition(lastKnown, allowBackendSync: false);
          resolved = lastKnown;
        }
      }

      final current = await _getCurrentPositionWithTimeout();
      if (current != null) {
        await _applyPosition(current, forceGeocode: true);
        resolved = current;
      }

      if (resolved == null && currentPosition.value == null) {
        locationError.value = 'failed_to_get_current_location'.tr;
        Get.snackbar(
          'location_error'.tr,
          'failed_to_get_location_message'.tr,
          snackPosition: SnackPosition.TOP,
        );
      }
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

    await _startPositionStream();
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final address = await getAddressFromCoordinates(latitude, longitude);
      currentAddress.value = address;
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting address from coordinates', e, stackTrace);
    }
  }

  // Public method for reverse geocoding that other services can use
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return _formatAddress(placemark);
      }
      return 'Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})'; // Better fallback
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting address from coordinates', e, stackTrace);
      return 'Location Coordinates'; // A better fallback than hardcoded text
    }
  }

  /// Fetches the best possible initial location for the user.
  /// Priority: High-accuracy GPS -> IP-based location.
  /// Throws an exception if no location can be determined.
  Future<LocationData> getInitialLocation() async {
    DebugLogger.info('Getting initial user location...');

    final ready = await _ensureLocationReady();
    Position? resolved;

    if (ready) {
      try {
        isLoading.value = true;

        final lastKnown = await _getLastKnownPosition();
        if (lastKnown != null) {
          final lastKnownFresh = _isPositionFresh(lastKnown, _lastKnownMaxAge);
          if (lastKnownFresh || currentPosition.value == null) {
            await _applyPosition(lastKnown, allowBackendSync: false);
            resolved = lastKnown;
          }
        }

        final current = await _getCurrentPositionWithTimeout();
        if (current != null) {
          await _applyPosition(current, forceGeocode: true);
          resolved = current;
        }
      } catch (e, st) {
        DebugLogger.warning('Failed to get high-accuracy location: $e', e, st);
      } finally {
        isLoading.value = false;
      }
    } else {
      DebugLogger.warning('GPS permissions not granted or service disabled. Falling back...');
    }

    final position = resolved ?? currentPosition.value;
    if (position != null) {
      final locationName = currentAddress.value.isNotEmpty
          ? currentAddress.value
          : await getAddressFromCoordinates(position.latitude, position.longitude);
      await _startPositionStream();
      return LocationData(
        name: locationName,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    if (ready) {
      await _startPositionStream();
    }

    DebugLogger.info('Attempting IP-based location fallback...');
    final ipLocation = await getIpLocation();
    if (ipLocation != null) {
      DebugLogger.success('IP-based location fallback successful: ${ipLocation.name}');
      return ipLocation;
    }

    DebugLogger.error('Critical: Could not determine any user location.');
    throw Exception(
      'Unable to determine user location. Please check network and location settings.',
    );
  }

  String _formatAddress(Placemark placemark) {
    // Improved formatting logic for better location names
    final city = placemark.locality;
    final state = placemark.administrativeArea;
    final area = placemark.subLocality;
    final street = placemark.street;

    // Priority order: Area+City+State, City+State, Street+City, or any available info
    if (area != null && area.isNotEmpty && city != null && city.isNotEmpty) {
      return '$area, $city';
    }
    if (city != null && city.isNotEmpty && state != null && state.isNotEmpty) {
      return '$city, $state';
    }
    if (city != null && city.isNotEmpty) {
      return city;
    }
    if (street != null && street.isNotEmpty) {
      return street;
    }

    // Fallback to any available information
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

    return addressParts.isNotEmpty ? addressParts.join(', ') : 'Location';
  }

  void selectLocation(Map<String, dynamic> location) {
    final locationName = location['name'] ?? location['city'] ?? '';

    Get.snackbar(
      'location_selected'.tr,
      'location_selected_message'.tr + locationName,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  void selectCity(String cityName) {
    // This method now only logs the selection
    DebugLogger.info('City selected: $cityName');
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
      Get.snackbar('error'.tr, 'unable_to_open_app_settings'.tr, snackPosition: SnackPosition.TOP);
    }
  }

  double? get currentLatitude => currentPosition.value?.latitude;
  double? get currentLongitude => currentPosition.value?.longitude;

  bool get hasLocation => currentPosition.value != null;

  String get locationStatusText {
    if (!isLocationEnabled.value) return 'location_services_disabled'.tr;
    if (!isLocationPermissionGranted.value) {
      return 'location_permission_denied'.tr;
    }
    if (isLoading.value) return 'getting_location'.tr;
    if (hasLocation) {
      return currentAddress.value.isNotEmpty ? currentAddress.value : 'location_found'.tr;
    }
    return 'location_not_available'.tr;
  }

  Map<String, dynamic> get locationSummary => {
    'hasPermission': isLocationPermissionGranted.value,
    'serviceEnabled': isLocationEnabled.value,
    'hasLocation': hasLocation,
    'latitude': currentLatitude,
    'longitude': currentLongitude,
    'address': currentAddress.value,
  };

  // clearSearchResults removed (no longer used)

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
        placeSuggestions.clear();
        return [];
      }

      final countryCode = dotenv.env['DEFAULT_COUNTRY'] ?? 'in';

      // Gurgaon/Gurugram coordinates: 28.4595, 77.0266
      final url = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': query,
        'location': '28.4595,77.0266',
        'radius': '25000', // 25km radius to cover entire Gurgaon area
        'components': 'country:$countryCode',
        'strictbounds': 'true', // Restrict results to the specified area only
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
          placeSuggestions.clear();
          return [];

        case 'OVER_QUERY_LIMIT':
          DebugLogger.error('Google Places API quota exceeded for query: $query');
          DebugLogger.error('Response: ${response.body}');
          placeSuggestions.clear();
          return [];

        case 'REQUEST_DENIED':
          DebugLogger.error('Google Places API request denied for query: $query');
          DebugLogger.error('Response: ${response.body}');
          placeSuggestions.clear();
          return [];

        case 'INVALID_REQUEST':
          DebugLogger.error('Invalid Google Places API request for query: $query');
          DebugLogger.error('Response: ${response.body}');
          placeSuggestions.clear();
          return [];

        default:
          DebugLogger.warning('Unknown Google Places API status: $status for query: $query');
          DebugLogger.warning('Response: ${response.body}');
          placeSuggestions.clear();
          return [];
      }
    } on TimeoutException catch (e) {
      DebugLogger.error('Google Places API request timed out for query: $query', e);
      placeSuggestions.clear();
      return [];
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting place suggestions for query: $query', e, stackTrace);
      placeSuggestions.clear();
      return [];
    } finally {
      isSearchingPlaces.value = false;
    }
  }

  Future<LocationData?> getPlaceDetails(String placeId, {String? preferredName}) async {
    try {
      isLoading.value = true;

      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        DebugLogger.warning('Google Places API key not found');
        return null;
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
        return null;
      }

      final data = json.decode(response.body);
      final status = data['status'];

      switch (status) {
        case 'OK':
          final result = data['result'];
          if (result != null) {
            final location = result['geometry']['location'];
            final addressComponents = result['address_components'] as List;

            // Use preferred name if provided (from autocomplete selection)
            String displayName;
            if (preferredName != null && preferredName.isNotEmpty) {
              displayName = preferredName;
              DebugLogger.info('🏷️ Using preferred name from selection: $displayName');
            } else {
              // Fallback to formatted address for GPS/other sources
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

              // Use city and locality to create a display name
              displayName = result['name'] ?? '';
              if (locality != null && city != null) {
                displayName = '$locality, $city';
              } else if (city != null) {
                displayName = city;
              } else if (locality != null) {
                displayName = locality;
              }
              DebugLogger.info('🗺️ Using formatted address: $displayName');
            }

            return LocationData(
              name: displayName,
              latitude: location['lat'].toDouble(),
              longitude: location['lng'].toDouble(),
            );
          }
          DebugLogger.warning(
            'Google Places Details API returned null result for placeId: $placeId',
          );
          return null;

        case 'ZERO_RESULTS':
          DebugLogger.info('Google Places Details API returned no results for placeId: $placeId');
          return null;

        case 'OVER_QUERY_LIMIT':
          DebugLogger.error('Google Places Details API quota exceeded for placeId: $placeId');
          DebugLogger.error('Response: ${response.body}');
          return null;

        case 'REQUEST_DENIED':
          DebugLogger.error('Google Places Details API request denied for placeId: $placeId');
          DebugLogger.error('Response: ${response.body}');
          return null;

        case 'INVALID_REQUEST':
          DebugLogger.error('Invalid Google Places Details API request for placeId: $placeId');
          DebugLogger.error('Response: ${response.body}');
          return null;

        case 'NOT_FOUND':
          DebugLogger.warning('Place not found for placeId: $placeId');
          DebugLogger.warning('Response: ${response.body}');
          return null;

        default:
          DebugLogger.warning(
            'Unknown Google Places Details API status: $status for placeId: $placeId',
          );
          DebugLogger.warning('Response: ${response.body}');
          return null;
      }
    } on TimeoutException catch (e) {
      DebugLogger.error('Google Places Details API request timed out for placeId: $placeId', e);
      return null;
    } catch (e, stackTrace) {
      DebugLogger.error('Error getting place details for placeId: $placeId', e, stackTrace);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  void clearPlaceSuggestions() {
    placeSuggestions.clear();
  }

  @override
  void onClose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
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
