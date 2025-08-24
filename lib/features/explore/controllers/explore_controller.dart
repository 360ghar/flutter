import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/property_marker_model.dart';
import '../../../core/data/models/location_model.dart';
import '../../../core/data/providers/google_places_service.dart';
import '../../../core/data/repositories/properties_repository.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/controllers/location_controller.dart';

// Simple CameraPosition class for flutter_map compatibility
class CameraPosition {
  final LatLng target;
  final double zoom;
  
  const CameraPosition({
    required this.target,
    this.zoom = 12.0,
  });
}

// Simple LatLngBounds class for flutter_map compatibility
class LatLngBounds {
  final LatLng southWest;
  final LatLng northEast;
  
  const LatLngBounds(this.southWest, this.northEast);
}

enum ExploreState {
  initial,
  loading,
  loaded,
  empty,
  error,
  loadingMore,
}

class ExploreController extends GetxController {
  // Service dependencies
  late final PropertiesRepository _propertiesRepository;
  late final FilterService _filterService;
  late final LocationController _locationController;

  // Reactive state
  final Rx<ExploreState> state = ExploreState.initial.obs;
  final RxList<PropertyModel> properties = <PropertyModel>[].obs;
  final RxList<PropertyMarker> propertyMarkers = <PropertyMarker>[].obs;
  final Rxn<LatLng> mapCenter = Rxn<LatLng>();
  final Rxn<PropertyModel> selectedProperty = Rxn<PropertyModel>();
  final RxString errorMessage = ''.obs;

  // Map state
  final Rx<LatLng> currentCenter = const LatLng(28.6139, 77.2090).obs; // Default: Delhi
  final RxDouble currentZoom = 10.0.obs; // More zoomed out for better visibility
  final RxDouble currentRadius = 100.0.obs;
  final Rx<CameraPosition> cameraPosition = const CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 10.0, // More zoomed out for better visibility
  ).obs;

  // Search and location
  final RxString searchQuery = ''.obs;
  final RxBool isSearchActive = false.obs;
  final RxList<LocationResult> searchResults = <LocationResult>[].obs;
  Timer? _searchDebouncer;
  Timer? _mapMoveDebouncer;

  // Selected property for bottom sheet and sync
  final RxInt selectedPropertyIndex = RxInt(-1);

  // Location and preferences
  final RxBool locationPermissionGranted = false.obs;
  final Rxn<CurrentLocation> currentLocation = Rxn<CurrentLocation>();
  final RxString currentLocationText = 'Delhi, India'.obs;

  // Loading states
  final RxBool isLoadingLocation = false.obs;
  final RxBool isLoadingProperties = false.obs;
  final RxInt loadingProgress = 0.obs;

  // Scroll controller for horizontal list
  final ScrollController horizontalScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    DebugLogger.info('🚀 ExploreController onInit() started.');

    // Initialize dependencies with error handling
    try {
      _propertiesRepository = Get.find<PropertiesRepository>();
      _filterService = Get.find<FilterService>();
      _locationController = Get.find<LocationController>();
      DebugLogger.success('✅ All dependencies initialized successfully');
    } catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to initialize dependencies', e, stackTrace);
      state.value = ExploreState.error;
      errorMessage.value = "Failed to initialize services. Please restart the app.";
      return;
    }

    // Set up reactive listeners
    ever(_filterService.currentFilter, (_) => fetchPropertiesForMap());

    // Initialize map and load properties
    _initializeMap();
  }

  @override
  void onReady() {
    super.onReady();
    DebugLogger.success('✅ ExploreController is ready! Current state: ${state.value}');

    // Perform additional validation
    if (state.value == ExploreState.initial) {
      DebugLogger.warning('⚠️ Controller is ready but still in initial state. This may indicate an initialization issue.');
    }
  }

  Future<void> _initializeMap() async {
    state.value = ExploreState.loading;
    try {
      // Wait for the location to become available
      await _locationController.getCurrentLocation();
      if (_locationController.currentPosition.value != null) {
        final position = _locationController.currentPosition.value!;
        mapCenter.value = LatLng(position.latitude, position.longitude);
        await fetchPropertiesForMap();
      } else {
        errorMessage.value = "Could not determine your location. Please enable location services.";
        state.value = ExploreState.error;
      }
    } catch (e) {
      DebugLogger.error("Initialization Error: ", e);
      errorMessage.value = "An error occurred while setting up the map.";
      state.value = ExploreState.error;
    }
  }

  Future<void> fetchPropertiesForMap() async {
    state.value = ExploreState.loading;
    selectedProperty.value = null; // Clear selection on new fetch

    try {
      final filter = _filterService.currentFilter.value;
      // Ensure location is in the filter for the repository call
      final enrichedFilter = filter.copyWith(
        latitude: mapCenter.value?.latitude,
        longitude: mapCenter.value?.longitude,
      );

      final fetchedProperties = await _propertiesRepository.loadAllPropertiesForMap(
        filters: enrichedFilter,
      );

      if (fetchedProperties.isEmpty) {
        state.value = ExploreState.empty;
        properties.clear();
        propertyMarkers.clear();
      } else {
        properties.assignAll(fetchedProperties);
        _updatePropertyMarkers();
        state.value = ExploreState.loaded;
      }
    } catch (e) {
      DebugLogger.error("Failed to fetch map properties: ", e);
      errorMessage.value = "Failed to load properties. Please try again.";
      state.value = ExploreState.error;
    }
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    _mapMoveDebouncer?.cancel();
    horizontalScrollController.dispose();
    super.onClose();
  }









  void _updateMapCenter(LatLng center, double zoom) {
    try {
      currentCenter.value = center;
      currentZoom.value = zoom;
      currentRadius.value = _calculateRadiusFromZoom(zoom);
      cameraPosition.value = CameraPosition(target: center, zoom: zoom);
      DebugLogger.info('🗺️ Updated map center to $center with zoom $zoom');
    } catch (e) {
      DebugLogger.warning('⚠️ Could not move map: $e');
      // Still update the reactive values even if map move fails
      currentCenter.value = center;
      currentZoom.value = zoom;
    }
  }

  // Google Maps camera move handler
  void onCameraMove(CameraPosition position) {
    currentCenter.value = position.target;
    currentZoom.value = position.zoom;
    currentRadius.value = _calculateRadiusFromZoom(position.zoom);

    // Debounce the map move to avoid too many API calls
    _mapMoveDebouncer?.cancel();
    _mapMoveDebouncer = Timer(const Duration(milliseconds: 600), () {
      _onMapMoveCompleted();
    });
  }

  // Called when camera stops moving
  void onCameraIdle() {
    _onMapMoveCompleted();
  }

  void _onMapMoveCompleted() {
    DebugLogger.api('🗺️ Map moved to ${currentCenter.value}, radius: ${currentRadius.value}km');

    // Update filters with new location
    _filterService.updateLocationWithCoordinates(
      latitude: currentCenter.value.latitude,
      longitude: currentCenter.value.longitude,
      radiusKm: currentRadius.value,
    );

    // Store location in backend (if API service available)
    // _apiService.storeUserLocation(
    //   latitude: currentCenter.value.latitude,
    //   longitude: currentCenter.value.longitude,
    // );
  }

  double _calculateRadiusFromZoom(double zoom) {
    // Approximate radius calculation based on zoom level - increased for better property coverage
    if (zoom >= 16) return 5.0;
    if (zoom >= 14) return 10.0;
    if (zoom >= 12) return 25.0;
    if (zoom >= 10) return 50.0;
    if (zoom >= 8) return 75.0;
    return 100.0;  // Maximum radius for wide area searches
  }

  // Load properties for current map view
  Future<void> _loadPropertiesForCurrentView() async {
    try {
      isLoadingProperties.value = true;
      DebugLogger.info('⏳ Starting property loading...');

      if (state.value != ExploreState.loading) {
        state.value = ExploreState.loading;
      }

      errorMessage.value = '';
      properties.clear();
      selectedProperty.value = null;

      DebugLogger.api('🗺️ Loading properties for map view');

      // Load properties using the regular getProperties method with location filters
      // Use the current center and radius for fetching properties
      final updatedFilters = _filterService.currentFilter.value.copyWith(
        latitude: currentCenter.value.latitude,
        longitude: currentCenter.value.longitude,
        radiusKm: currentRadius.value,
      );

      final propertiesList = await _propertiesRepository.loadAllPropertiesForMap(
        filters: updatedFilters,
      );

      properties.assignAll(propertiesList);
      DebugLogger.success('✅ Loaded ${properties.length} properties for map.');

      // Update markers
      _updatePropertyMarkers();

      if (properties.isEmpty) {
        DebugLogger.info('📭 No properties found, setting empty state');
        state.value = ExploreState.empty;
        errorMessage.value = "No properties found in this area. Try expanding your search or changing filters.";
      } else {
        DebugLogger.success('✅ Setting loaded state with ${properties.length} properties');
        state.value = ExploreState.loaded;
      }

    } catch (e) {
      DebugLogger.error('❌ Failed to load properties: $e');
      state.value = ExploreState.error;
      errorMessage.value = e.toString();
    } finally {
      isLoadingProperties.value = false;
      loadingProgress.value = 0;
      DebugLogger.info('🔄 Cleanup completed for property loading');
    }
  }



  void _updatePropertyMarkers() {
    final markers = properties
        .where((p) => p.hasLocation)
        .map((property) => PropertyMarker.fromProperty(
              property,
              isSelected: selectedProperty.value?.id == property.id,
            ))
        .toList();

    propertyMarkers.assignAll(markers);
  }

  void onPropertySelected(PropertyModel property) {
    selectedProperty.value = property;
    mapCenter.value = property.latLng; // Center map on selected property
    // Highlight the selected marker
    propertyMarkers.value = propertyMarkers.updateSelection(property.id);
  }

  void onMapMoved(LatLng newCenter) {
    // Optional: Implement logic to fetch properties for the new map area
    // For now, we just update the center
    mapCenter.value = newCenter;
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query;

    _searchDebouncer?.cancel();

    if (query.isEmpty) {
      isSearchActive.value = false;
      searchResults.clear();
      _filterService.updateSearchQuery('');
      return;
    }

    isSearchActive.value = true;

    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      DebugLogger.api('🔍 Searching places: "$query"');

      final results = await GooglePlacesService.searchPlaces(
        query,
        locationBias: currentCenter.value,
        radius: (currentRadius.value * 1000).toDouble(),
      );

      searchResults.assignAll(results);
    } catch (e) {
      DebugLogger.error('Error searching places: $e');
      searchResults.clear();
    }
  }

  Future<void> selectLocationResult(LocationResult result) async {
    try {
      isSearchActive.value = false;
      searchQuery.value = result.description;
      currentLocationText.value = result.description;

      if (result.hasCoordinates) {
        _updateMapCenter(result.coordinates!, 14.0);
      } else {
        // Geocode the address if coordinates not available
        final coordinates = await GooglePlacesService.geocodeAddress(result.description);
        if (coordinates != null) {
          _updateMapCenter(coordinates, 14.0);
        }
      }

      // Save location preference (if API service available)
      // await _saveLocationPreference(result.description);

    } catch (e) {
      DebugLogger.error('Error selecting location: $e');
    }
  }



  void clearSearch() {
    searchQuery.value = '';
    isSearchActive.value = false;
    searchResults.clear();
    _filterService.updateSearchQuery('');
  }

  // Property selection and sync
  void selectProperty(PropertyModel property) {
    selectedProperty.value = property;
    selectedPropertyIndex.value = properties.indexOf(property);

    // Update markers to highlight selected property
    _updatePropertyMarkers();

    DebugLogger.api('🏠 Selected property: ${property.title}');

    // Center map on selected property if it has location
    if (property.hasLocation) {
      _updateMapCenter(
        LatLng(property.latitude!, property.longitude!),
        16.0, // Zoom in closer for selected property
      );
    }

    // Scroll property list to selected property
    _scrollToProperty(selectedPropertyIndex.value);
  }

  void selectPropertyFromList(PropertyModel property, int index) {
    selectedProperty.value = property;
    selectedPropertyIndex.value = index;

    // Update markers to highlight selected property
    _updatePropertyMarkers();

    DebugLogger.api('🏠 Selected property from list: ${property.title}');

    // Center map on selected property if it has location
    if (property.hasLocation) {
      _updateMapCenter(
        LatLng(property.latitude!, property.longitude!),
        16.0,
      );
    }
  }

  void _scrollToProperty(int index) {
    if (index >= 0 && index < properties.length) {
      final offset = index * 300.0; // Approximate card width
      horizontalScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void clearSelection() {
    selectedProperty.value = null;
    selectedPropertyIndex.value = -1;
    _updatePropertyMarkers();
  }

  // Navigation to property details
  void viewPropertyDetails(PropertyModel property) {
    Get.toNamed('/property-details', arguments: {'property': property});
  }

  // Like/Dislike property (swipe action)
  Future<void> toggleLikeProperty(PropertyModel property) async {
    try {
      // Optimistic update
      property.liked = !property.liked;
      properties.refresh();

      // API call (if API service available)
      // final success = true; // Mock success for now
      // if (!success) {
      //   // Revert optimistic update on failure
      //   property.liked = !property.liked;
      //   properties.refresh();
      // }
    } catch (e) {
      DebugLogger.error('Error toggling like: $e');
      // Revert optimistic update on error
      property.liked = !property.liked;
      properties.refresh();
    }
  }

  // Filter shortcuts
  void showFilters() {
    Get.toNamed('/filters');
  }

  void quickFilterByType(String type) {
    _filterService.updatePropertyTypes([type]);
  }

  void quickFilterByPurpose(String purpose) {
    _filterService.updatePurpose(purpose);
  }

  // Map controls
  void zoomIn() {
    final newZoom = (currentZoom.value + 1).clamp(3.0, 18.0);
    _updateMapCenter(currentCenter.value, newZoom);
  }

  void zoomOut() {
    final newZoom = (currentZoom.value - 1).clamp(3.0, 18.0);
    _updateMapCenter(currentCenter.value, newZoom);
  }

  void recenterToCurrentLocation() async {
    if (currentLocation.value != null) {
      _updateMapCenter(currentLocation.value!.coordinates, 14.0);
    } else {
      // Try to get current location
      await _locationController.getCurrentLocation();
      if (_locationController.currentPosition.value != null) {
        final position = _locationController.currentPosition.value!;
        _updateMapCenter(LatLng(position.latitude, position.longitude), 14.0);
      }
    }
  }

  void fitBoundsToProperties() {
    if (properties.isEmpty) return;

    final propertiesWithLocation = properties.where((p) => p.hasLocation).toList();
    if (propertiesWithLocation.isEmpty) return;

    try {
      final lats = propertiesWithLocation.map((p) => p.latitude!).toList();
      final lngs = propertiesWithLocation.map((p) => p.longitude!).toList();

      final minLat = lats.reduce((a, b) => a < b ? a : b);
      final maxLat = lats.reduce((a, b) => a > b ? a : b);
      final minLng = lngs.reduce((a, b) => a < b ? a : b);
      final maxLng = lngs.reduce((a, b) => a > b ? a : b);

      // Calculate center and zoom to fit all properties
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final center = LatLng(centerLat, centerLng);
      
      // Calculate appropriate zoom level based on bounds
      final latDiff = maxLat - minLat;
      final lngDiff = maxLng - minLng;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
      
      double zoom = 12.0;
      if (maxDiff > 0.1) zoom = 8.0;
      else if (maxDiff > 0.05) zoom = 10.0;
      else if (maxDiff > 0.01) zoom = 12.0;
      else zoom = 14.0;

      _updateMapCenter(center, zoom);

    } catch (e) {
      DebugLogger.warning('⚠️ Could not fit bounds: $e');
    }
  }

  // Map initialization callback
  void onMapReady() {
    DebugLogger.success('✅ OpenStreetMap initialized');
    
    // Force a refresh after map is created
    Future.delayed(const Duration(milliseconds: 500), () {
      DebugLogger.info('🔄 Refreshing properties after map creation');
      _loadPropertiesForCurrentView();
    });
  }

  // Refresh


  // Error handling
  void retryLoading() {
    errorMessage.value = '';
    fetchPropertiesForMap();
  }

  void clearError() {
    errorMessage.value = '';
    if (state.value == ExploreState.error) {
      state.value = properties.isEmpty ? ExploreState.empty : ExploreState.loaded;
    }
  }

  // Statistics and info
  String get locationDisplayText => currentLocationText.value;

  String get propertiesCountText {
    if (properties.isEmpty) return 'No properties found';
    if (properties.length == 1) return '1 property';
    return '${properties.length} properties';
  }

  String get currentAreaText {
    if (currentRadius.value < 1) {
      return '${(currentRadius.value * 1000).round()}m radius';
    }
    return '${currentRadius.value.toStringAsFixed(1)}km radius';
  }

  // Helper getters
  bool get isLoading => state.value == ExploreState.loading;
  bool get isEmpty => state.value == ExploreState.empty;
  bool get hasError => state.value == ExploreState.error;
  bool get isLoaded => state.value == ExploreState.loaded;
  bool get hasProperties => properties.isNotEmpty;
  bool get hasSelection => selectedProperty.value != null;
  bool get isLoadingMore => state.value == ExploreState.loadingMore;
}