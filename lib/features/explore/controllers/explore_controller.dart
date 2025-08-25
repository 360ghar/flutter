import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:get_storage/get_storage.dart';
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
  final RxDouble currentZoom = 12.0.obs; // Better initial zoom for property visibility
  final RxDouble currentRadius = 25.0.obs; // Better initial radius for focused search
  final Rx<CameraPosition> cameraPosition = const CameraPosition(
    target: LatLng(28.6139, 77.2090),
    zoom: 12.0,
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
  final RxBool isLoadingMore = false.obs;
  final RxInt loadingProgress = 0.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNextPage = true.obs;
  static const int pageSize = 20;

  // State persistence
  final RxBool isInitialized = false.obs;
  final RxBool isBackgroundRefresh = false.obs;

  // Map controls
  final RxBool isMapReady = false.obs;

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

    // Set up scroll listener for infinite scroll
    _setupScrollListener();

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
      // Try to restore saved location first
      final savedLocation = await _loadSavedLocation();

      if (savedLocation != null) {
        // Use saved location
        currentCenter.value = savedLocation;
        mapCenter.value = savedLocation;
        currentRadius.value = _calculateRadiusFromZoom(currentZoom.value);

        // Update filter service with saved location
        _filterService.updateLocationWithCoordinates(
          latitude: savedLocation.latitude,
          longitude: savedLocation.longitude,
          radiusKm: currentRadius.value,
        );

        // Load properties and trigger background refresh
        await _loadPropertiesForCurrentView();
        isInitialized.value = true;

        // Background refresh with current location
        _triggerBackgroundRefreshWithCurrentLocation();
      } else {
        // No saved location, get current location
        await _locationController.getCurrentLocation();
        if (_locationController.currentPosition.value != null) {
          final position = _locationController.currentPosition.value!;
          final initialCenter = LatLng(position.latitude, position.longitude);

          // Update all map-related state
          currentCenter.value = initialCenter;
          mapCenter.value = initialCenter;
          currentRadius.value = _calculateRadiusFromZoom(currentZoom.value);

          // Save location for future use
          await _saveCurrentLocation(initialCenter);

          // Update filter service with initial location
          _filterService.updateLocationWithCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusKm: currentRadius.value,
          );

          await _loadPropertiesForCurrentView();
          isInitialized.value = true;
        } else {
          // Fallback to default location with better zoom
          DebugLogger.warning('⚠️ Could not get current location, using default');
          final defaultCenter = const LatLng(28.6139, 77.2090);
          currentCenter.value = defaultCenter;
          mapCenter.value = defaultCenter;
          currentRadius.value = _calculateRadiusFromZoom(currentZoom.value);

          await _loadPropertiesForCurrentView();
          isInitialized.value = true;
        }
      }
    } catch (e) {
      DebugLogger.error("Initialization Error: ", e);
      errorMessage.value = "An error occurred while setting up the map.";
      state.value = ExploreState.error;
    }
  }

  Future<LatLng?> _loadSavedLocation() async {
    try {
      final box = GetStorage();
      final lat = box.read<double>('explore_last_lat');
      final lng = box.read<double>('explore_last_lng');

      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    } catch (e) {
      DebugLogger.warning('Could not load saved location: $e');
    }
    return null;
  }

  Future<void> _saveCurrentLocation(LatLng location) async {
    try {
      final box = GetStorage();
      await box.write('explore_last_lat', location.latitude);
      await box.write('explore_last_lng', location.longitude);
    } catch (e) {
      DebugLogger.warning('Could not save location: $e');
    }
  }

  void _triggerBackgroundRefreshWithCurrentLocation() {
    // Trigger background refresh when location becomes available
    ever(_locationController.currentPosition, (position) {
      if (position != null && isInitialized.value) {
        backgroundRefresh();
      }
    });
  }

  Future<void> fetchPropertiesForMap({bool isRefresh = false}) async {
    if (!isRefresh) {
      state.value = ExploreState.loading;
      selectedProperty.value = null; // Clear selection on new fetch
    }

    try {
      final filter = _filterService.currentFilter.value;
      // Ensure location is in the filter for the repository call
      final enrichedFilter = filter.copyWith(
        latitude: mapCenter.value?.latitude,
        longitude: mapCenter.value?.longitude,
      );

      final response = await _propertiesRepository.getProperties(
        filters: enrichedFilter,
        page: isRefresh ? 1 : currentPage.value,
        limit: pageSize,
      );

      final fetchedProperties = response.properties;

      if (fetchedProperties.isEmpty && properties.isEmpty) {
        state.value = ExploreState.empty;
        properties.clear();
        propertyMarkers.clear();
        hasNextPage.value = false;
        totalPages.value = response.totalPages;
      } else {
        if (isRefresh || currentPage.value == 1) {
          properties.assignAll(fetchedProperties);
        } else {
          properties.addAll(fetchedProperties);
        }

        _updatePropertyMarkers();

        // Update pagination info from response
        hasNextPage.value = response.hasMore;
        totalPages.value = response.totalPages;
        currentPage.value = response.page;

        state.value = ExploreState.loaded;
      }
    } catch (e) {
      DebugLogger.error("Failed to fetch map properties: ", e);
      errorMessage.value = "Failed to load properties. Please try again.";
      state.value = ExploreState.error;
    }
  }

  Future<void> loadMoreProperties() async {
    if (isLoadingMore.value || !hasNextPage.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    try {
      final filter = _filterService.currentFilter.value;
      final enrichedFilter = filter.copyWith(
        latitude: mapCenter.value?.latitude,
        longitude: mapCenter.value?.longitude,
      );

      final response = await _propertiesRepository.getProperties(
        filters: enrichedFilter,
        page: currentPage.value,
        limit: pageSize,
      );

      final fetchedProperties = response.properties;

      if (fetchedProperties.isNotEmpty) {
        properties.addAll(fetchedProperties);
        _updatePropertyMarkers();
        hasNextPage.value = response.hasMore;
        totalPages.value = response.totalPages;
        currentPage.value = response.page;
      } else {
        hasNextPage.value = false;
      }
    } catch (e) {
      DebugLogger.error("Failed to load more properties: ", e);
      currentPage.value--; // Revert page increment
    } finally {
      isLoadingMore.value = false;
    }
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    _mapMoveDebouncer?.cancel();
    horizontalScrollController.removeListener(_onScroll);
    horizontalScrollController.dispose();
    super.onClose();
  }

  void _setupScrollListener() {
    horizontalScrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (horizontalScrollController.position.pixels >=
        horizontalScrollController.position.maxScrollExtent * 0.8) {
      loadMoreProperties();
    }
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

  // Enhanced map event handlers
  void onMapMoved(LatLng newCenter) {
    DebugLogger.info('🗺️ Map moved to: ${newCenter.latitude}, ${newCenter.longitude}');

    // Update current center
    currentCenter.value = newCenter;
    mapCenter.value = newCenter;

    // Save location for future use
    _saveCurrentLocation(newCenter);

    // Cancel previous debounce
    _mapMoveDebouncer?.cancel();

    // Debounce the property loading to avoid too many API calls
    _mapMoveDebouncer = Timer(const Duration(milliseconds: 800), () {
      _onMapMoveCompleted();
    });
  }

  void onMapZoomChanged(double newZoom) {
    DebugLogger.info('🔍 Map zoom changed to: $newZoom');

    currentZoom.value = newZoom;
    currentRadius.value = _calculateRadiusFromZoom(newZoom);

    // Update camera position
    cameraPosition.value = CameraPosition(
      target: currentCenter.value,
      zoom: newZoom,
    );

    // Trigger property reload on zoom change
    _mapMoveDebouncer?.cancel();
    _mapMoveDebouncer = Timer(const Duration(milliseconds: 500), () {
      _onMapMoveCompleted();
    });
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
  Future<void> _loadPropertiesForCurrentView({bool isRefresh = false}) async {
    try {
      if (!isRefresh) {
        isLoadingProperties.value = true;
        DebugLogger.info('⏳ Starting property loading...');
      }

      if (!isRefresh && state.value != ExploreState.loading) {
        state.value = ExploreState.loading;
      }

      errorMessage.value = '';

      if (!isRefresh) {
        properties.clear();
        selectedProperty.value = null;
        currentPage.value = 1;
        hasNextPage.value = true;
      }

      DebugLogger.api('🗺️ Loading properties for map view');

      // Load properties using the regular getProperties method with location filters
      // Use the current center and radius for fetching properties
      final updatedFilters = _filterService.currentFilter.value.copyWith(
        latitude: currentCenter.value.latitude,
        longitude: currentCenter.value.longitude,
        radiusKm: currentRadius.value,
      );

      final response = await _propertiesRepository.getProperties(
        filters: updatedFilters,
        page: currentPage.value,
        limit: pageSize,
      );

      final propertiesList = response.properties;

      if (isRefresh) {
        properties.assignAll(propertiesList);
        currentPage.value = 1;
      } else {
        properties.addAll(propertiesList);
      }

      DebugLogger.success('✅ Loaded ${properties.length} properties for map.');

      // Update markers
      _updatePropertyMarkers();

      // Update pagination info from response
      hasNextPage.value = response.hasMore;
      totalPages.value = response.totalPages;
      currentPage.value = response.page;

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
    _updatePropertyMarkers();
  }

  void onPropertySelectedFromList(PropertyModel property, int index) {
    selectedProperty.value = property;
    selectedPropertyIndex.value = index;

    // Update markers to highlight selected property
    _updatePropertyMarkers();

    DebugLogger.api('🏠 Selected property from list: ${property.title}');

    // Center map on selected property if it has location
    if (property.hasLocation) {
      _updateMapCenter(
        LatLng(property.latitude!, property.longitude!),
        16.0, // Zoom in closer for selected property
      );
    }

    // Scroll to selected property in list (ensure it's visible)
    _scrollToProperty(index);
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
      DebugLogger.info('📍 Location selected: ${result.description}');

      isSearchActive.value = false;
      searchQuery.value = result.description;
      currentLocationText.value = result.description;

      LatLng? coordinates;

      if (result.hasCoordinates) {
        coordinates = result.coordinates!;
      } else {
        // Geocode the address if coordinates not available
        coordinates = await GooglePlacesService.geocodeAddress(result.description);
      }

      if (coordinates != null) {
        // Animate to the selected location
        _animateToLocation(coordinates, 14.0);

        // Update filter service with new location
        _filterService.updateLocationWithCoordinates(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          radiusKm: currentRadius.value,
        );

        // Load properties for the new location
        await _loadPropertiesForCurrentView();

        DebugLogger.success('✅ Successfully moved to selected location');
        Get.snackbar(
          'Location Updated',
          'Showing properties near ${result.description}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        DebugLogger.error('❌ Could not get coordinates for selected location');
        Get.snackbar(
          'Location Error',
          'Could not find coordinates for the selected location',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

    } catch (e) {
      DebugLogger.error('Error selecting location: $e');
      Get.snackbar(
        'Error',
        'Failed to select location. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Animation helper for smooth map transitions
  void _animateToLocation(LatLng location, double zoom) {
    DebugLogger.info('🎯 Animating to location: ${location.latitude}, ${location.longitude} with zoom $zoom');

    currentCenter.value = location;
    mapCenter.value = location;
    currentZoom.value = zoom;
    currentRadius.value = _calculateRadiusFromZoom(zoom);

    cameraPosition.value = CameraPosition(
      target: location,
      zoom: zoom,
    );
  }



  void clearSearch() {
    searchQuery.value = '';
    isSearchActive.value = false;
    searchResults.clear();
    _filterService.updateSearchQuery('');
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;
    await _performSearch(query);
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

  Future<void> recenterToCurrentLocation() async {
    try {
      DebugLogger.info('📍 Recentering to current location...');

      // Try to get current location
      await _locationController.getCurrentLocation();
      if (_locationController.currentPosition.value != null) {
        final position = _locationController.currentPosition.value!;
        final currentLoc = LatLng(position.latitude, position.longitude);

        _animateToLocation(currentLoc, 14.0);
        currentLocationText.value = 'Current Location';

        // Update filter service
        _filterService.updateLocationWithCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: currentRadius.value,
        );

        // Load properties for current location
        await _loadPropertiesForCurrentView();

        Get.snackbar(
          'Location Updated',
          'Centered on your current location',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Location Error',
          'Could not get your current location',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      DebugLogger.error('Error getting current location: $e');
      Get.snackbar(
        'Error',
        'Failed to get current location',
        snackPosition: SnackPosition.BOTTOM,
      );
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
    DebugLogger.success('✅ Map initialized successfully');
    isMapReady.value = true;

    // Force a refresh after map is created if needed
    if (properties.isEmpty && state.value != ExploreState.loading) {
      Future.delayed(const Duration(milliseconds: 500), () {
        DebugLogger.info('🔄 Refreshing properties after map creation');
        _loadPropertiesForCurrentView();
      });
    }
  }

  // Refresh functionality
  Future<void> refresh() async {
    DebugLogger.info('🔄 Manual refresh triggered');
    isBackgroundRefresh.value = false;
    await _loadPropertiesForCurrentView(isRefresh: true);
  }

  // Background refresh functionality
  Future<void> backgroundRefresh() async {
    if (isLoadingProperties.value || !isInitialized.value) return;

    DebugLogger.info('🔄 Background refresh triggered');
    isBackgroundRefresh.value = true;

    try {
      await _loadPropertiesForCurrentView(isRefresh: true);
      DebugLogger.success('✅ Background refresh completed');
    } catch (e) {
      DebugLogger.error('❌ Background refresh failed: $e');
    } finally {
      isBackgroundRefresh.value = false;
    }
  }

  // Error handling
  void retryLoading() {
    errorMessage.value = '';
    _loadPropertiesForCurrentView();
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
  bool get isLoadingMoreState => state.value == ExploreState.loadingMore;
}