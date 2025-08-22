import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/repositories/properties_repository.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/controllers/location_controller.dart';

enum ExploreState {
  initial,
  loading,
  loaded,
  empty,
  error,
  loadingMore,
}

class ExploreController extends GetxController {
  final PropertiesRepository _propertiesRepository = Get.find<PropertiesRepository>();
  final FilterService _filterService = Get.find<FilterService>();
  final LocationController _locationController = Get.find<LocationController>();

  // Map controller
  final MapController mapController = MapController();

  // Reactive state
  final Rx<ExploreState> state = ExploreState.initial.obs;
  final RxList<PropertyModel> properties = <PropertyModel>[].obs;
  final RxnString error = RxnString();

  // Map state
  final Rx<LatLng> currentCenter = const LatLng(28.6139, 77.2090).obs; // Default: Delhi
  final RxDouble currentZoom = 12.0.obs;
  final RxDouble currentRadius = 5.0.obs;

  // Search
  final RxString searchQuery = ''.obs;
  Timer? _searchDebouncer;
  Timer? _mapMoveDebouncer;

  // Loading progress for sequential page loading
  final RxInt loadingProgress = 0.obs;
  final RxInt totalPages = 1.obs;

  // Selected property for bottom sheet
  final Rx<PropertyModel?> selectedProperty = Rx<PropertyModel?>(null);

  @override
  void onInit() {
    super.onInit();
    DebugLogger.info('🚀 ExploreController onInit() started.');
    
    // Add state listener for debugging
    ever(state, (ExploreState currentState) {
      DebugLogger.info('📊 ExploreState changed to: $currentState');
    });
    
    // Set state to loading immediately to prevent blank page
    state.value = ExploreState.loading;
    
    _setupFilterListener();
    _setupLocationListener();
    
    // Use addPostFrameCallback to ensure all bindings are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMapAndLoadProperties();
    });
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

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    _mapMoveDebouncer?.cancel();
    super.onClose();
  }

  void _setupFilterListener() {
    // Listen to filter changes and reload properties
    debounce(_filterService.currentFilter, (_) {
      _loadPropertiesForCurrentView();
    }, time: const Duration(milliseconds: 500));
  }

  void _setupLocationListener() {
    // Listen to location updates
    _locationController.currentPosition.listen((position) {
      if (position != null) {
        final newCenter = LatLng(position.latitude, position.longitude);
        final distance = const Distance();
        if (distance.as(LengthUnit.Meter, currentCenter.value, newCenter) > 1000) { // Only update if >1km difference
          _updateMapCenter(newCenter, 14.0);
        }
      }
    });
  }

  // New combined initialization method
  Future<void> _initializeMapAndLoadProperties() async {
    try {
      DebugLogger.info('🗺️ Initializing map and loading properties...');
      LatLng initialCenter = const LatLng(28.6139, 77.2090); // Default to Delhi
      double initialZoom = 12.0;

      // Prioritize location from FilterService if available
      if (_filterService.hasLocation) {
        final filters = _filterService.currentFilter.value;
        initialCenter = LatLng(filters.latitude!, filters.longitude!);
        DebugLogger.info('🗺️ Using location from FilterService: $initialCenter');
      } else {
        // Try to get current device location, but don't block if it fails
        DebugLogger.info('🗺️ Attempting to get current device location...');
        await _locationController.getCurrentLocation();
        if (_locationController.hasLocation) {
          final pos = _locationController.currentPosition.value!;
          initialCenter = LatLng(pos.latitude, pos.longitude);
          initialZoom = 14.0; // Zoom in closer for current location
          DebugLogger.info('🗺️ Using current device location: $initialCenter');
        } else {
          DebugLogger.warning('⚠️ Could not get device location. Using default.');
        }
      }

      // Update map and filters with the determined location
      _updateMapCenter(initialCenter, initialZoom);
      _filterService.updateLocationWithCoordinates(
        latitude: initialCenter.latitude,
        longitude: initialCenter.longitude,
        radiusKm: _calculateRadiusFromZoom(initialZoom),
      );

      // Now, load properties
      await _loadPropertiesForCurrentView();

    } catch (e) {
      DebugLogger.error('❌ CRITICAL: Failed during initialization: $e');
      state.value = ExploreState.error;
      error.value = "Failed to initialize the map. The app will use mock data for demonstration purposes.";

      // Try to load mock data even if initialization fails
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPropertiesForCurrentView();
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      DebugLogger.info('📍 Getting current location...');
      await _locationController.getCurrentLocation();
      final position = _locationController.currentPosition.value;
      if (position != null) {
        DebugLogger.success('✅ Current location obtained: lat=${position.latitude}, lng=${position.longitude}');
        _updateMapCenter(LatLng(position.latitude, position.longitude), 14.0);
        
        // Update filters with current location
        _filterService.updateLocationWithCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: currentRadius.value,
        );
      } else {
        DebugLogger.warning('⚠️ LocationController returned null position, using default location');
        // Use default location (Delhi) if location is not available
        _updateMapCenter(const LatLng(28.6139, 77.2090), 12.0);
        _filterService.updateLocationWithCoordinates(
          latitude: 28.6139,
          longitude: 77.2090,
          radiusKm: currentRadius.value,
        );
      }
    } catch (e) {
      DebugLogger.warning('⚠️ Could not get current location: $e');
      // Always fallback to default location
      DebugLogger.info('🗺️ Falling back to default location (Delhi)');
      _updateMapCenter(const LatLng(28.6139, 77.2090), 12.0);
      _filterService.updateLocationWithCoordinates(
        latitude: 28.6139,
        longitude: 77.2090,
        radiusKm: currentRadius.value,
      );
    }
  }

  void _updateMapCenter(LatLng center, double zoom) {
    try {
      currentCenter.value = center;
      currentZoom.value = zoom;
      DebugLogger.info('🗺️ Updated map center to $center with zoom $zoom');
      
      mapController.move(center, zoom);
    } catch (e) {
      DebugLogger.warning('⚠️ Could not move map: $e');
      // Still update the reactive values even if map move fails
      currentCenter.value = center;
      currentZoom.value = zoom;
    }
  }

  // Map movement handler with debounce
  void onMapMove(MapCamera position, bool hasGesture) {
    if (!hasGesture) return; // Ignore programmatic moves
    
    currentCenter.value = position.center;
    currentZoom.value = position.zoom;
    
    // Calculate radius from zoom level and visible bounds
    final newRadius = _calculateRadiusFromZoom(position.zoom);
    if ((newRadius - currentRadius.value).abs() > 0.5) {
      currentRadius.value = newRadius;
    }

    // Debounce the map move to avoid too many API calls
    _mapMoveDebouncer?.cancel();
    _mapMoveDebouncer = Timer(const Duration(milliseconds: 600), () {
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
  }

  double _calculateRadiusFromZoom(double zoom) {
    // Approximate radius calculation based on zoom level
    if (zoom >= 16) return 1.0;
    if (zoom >= 14) return 2.0;
    if (zoom >= 12) return 5.0;
    if (zoom >= 10) return 10.0;
    if (zoom >= 8) return 25.0;
    return 50.0;
  }

  // Load all properties for current map view
  Future<void> _loadPropertiesForCurrentView() async {
    try {
      // Don't check if already loading - the state is managed by caller
      DebugLogger.info('⏳ Starting property loading...');
      
      // Only set loading if not already in a loading state
      if (state.value != ExploreState.loading) {
        state.value = ExploreState.loading;
      }
      
      error.value = null;
      properties.clear();
      selectedProperty.value = null;

      DebugLogger.api('🗺️ Loading all properties for map view with filters: ${_filterService.currentFilter.value.toJson()}');

      // Load all pages sequentially for map display
      final allProperties = await _propertiesRepository.loadAllPropertiesForMap(
        filters: _filterService.currentFilter.value,
        limit: 100,
        onProgress: (current, total) {
          loadingProgress.value = current;
          totalPages.value = total;
        },
      );

      properties.assignAll(allProperties);
      DebugLogger.success('✅ Loaded ${properties.length} properties for map.');

      if (properties.isEmpty) {
        DebugLogger.info('📭 No properties found, setting empty state');
        state.value = ExploreState.empty;
      } else {
        DebugLogger.success('✅ Setting loaded state with ${properties.length} properties');
        state.value = ExploreState.loaded;
      }

    } catch (e) {
      DebugLogger.error('❌ Failed to load properties: $e');
      state.value = ExploreState.error;

      // Provide user-friendly error messages
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        error.value = "Unable to connect to the server. The app is using demo data for now.";
      } else if (e.toString().contains('timeout')) {
        error.value = "Request timed out. Please check your internet connection.";
      } else if (e.toString().contains('404') || e.toString().contains('request not found')) {
        error.value = "Server endpoint not found. Using demo data instead.";
      } else {
        error.value = "Failed to load properties. The app will show demo data.";
      }

      // Always try to show some data even on error
      if (properties.isEmpty) {
        // Load mock data if we have no properties
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Demo Mode',
            'Server unavailable - showing demo properties',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withValues(alpha: 0.9),
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        });
      }
    } finally {
      loadingProgress.value = 0;
      totalPages.value = 1;
      DebugLogger.info('🔄 Cleanup completed for property loading');
    }
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    
    _searchDebouncer?.cancel();
    
    if (query.isEmpty) {
      _filterService.updateSearchQuery('');
      return;
    }

    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      DebugLogger.api('🔍 Searching properties: "$query"');
      _filterService.updateSearchQuery(query);
    });
  }

  void clearSearch() {
    searchQuery.value = '';
    _filterService.updateSearchQuery('');
  }

  // Property selection
  void selectProperty(PropertyModel property) {
    selectedProperty.value = property;
    DebugLogger.api('🏠 Selected property: ${property.title}');
    
    // Center map on selected property if it has location
    if (property.hasLocation) {
      _updateMapCenter(
        LatLng(property.latitude!, property.longitude!),
        16.0, // Zoom in closer for selected property
      );
    }
  }

  void clearSelection() {
    selectedProperty.value = null;
  }

  // Navigation to property details
  void viewPropertyDetails(PropertyModel property) {
    Get.toNamed('/property-details', arguments: {'property': property});
  }

  // Filter shortcuts
  void showFilters() {
    Get.toNamed('/filters');
  }

  void quickFilterByType(PropertyType type) {
    _filterService.updatePropertyTypes([type.toString()]);
  }

  void quickFilterByPurpose(PropertyPurpose purpose) {
    _filterService.updatePurpose(purpose.toString());
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

  void recenterToCurrentLocation() {
    _useCurrentLocation();
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

      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );

      mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
      
    } catch (e) {
      DebugLogger.warning('⚠️ Could not fit bounds: $e');
    }
  }

  // Refresh
  Future<void> refreshProperties() async {
    await _loadPropertiesForCurrentView();
  }

  // Error handling
  void retryLoading() {
    error.value = null;
    _loadPropertiesForCurrentView();
  }

  void clearError() {
    error.value = null;
    if (state.value == ExploreState.error) {
      state.value = properties.isEmpty ? ExploreState.empty : ExploreState.loaded;
    }
  }

  // Statistics and info
  String get locationDisplayText => _filterService.locationDisplayText;
  
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

  // Get properties for clustering (if implemented)
  List<PropertyModel> get propertiesWithLocation {
    return properties.where((p) => p.hasLocation).toList();
  }

  // Get property markers for map
  List<PropertyMarker> get propertyMarkers {
    return propertiesWithLocation.map((property) {
      return PropertyMarker(
        property: property,
        position: LatLng(property.latitude!, property.longitude!),
        isSelected: selectedProperty.value?.id == property.id,
      );
    }).toList();
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

// Helper class for property markers
class PropertyMarker {
  final PropertyModel property;
  final LatLng position;
  final bool isSelected;

  PropertyMarker({
    required this.property,
    required this.position,
    required this.isSelected,
  });
}