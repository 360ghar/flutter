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
    _setupFilterListener();
    _setupLocationListener();
    _initializeMap();
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

  Future<void> _initializeMap() async {
    try {
      // Try to use current location or saved location from filters
      if (_filterService.hasLocation) {
        final filters = _filterService.currentFilter.value;
        _updateMapCenter(LatLng(filters.latitude!, filters.longitude!), currentZoom.value);
      } else {
        await _useCurrentLocation();
      }
      
      _loadPropertiesForCurrentView();
    } catch (e) {
      DebugLogger.error('❌ Failed to initialize map: $e');
      _loadPropertiesForCurrentView(); // Load with default location
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      await _locationController.getCurrentLocation();
      final position = _locationController.currentPosition.value;
      if (position != null) {
        _updateMapCenter(LatLng(position.latitude, position.longitude), 14.0);
        
        // Update filters with current location
        _filterService.updateLocationWithCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: currentRadius.value,
        );
      }
    } catch (e) {
      DebugLogger.warning('⚠️ Could not get current location: $e');
    }
  }

  void _updateMapCenter(LatLng center, double zoom) {
    currentCenter.value = center;
    currentZoom.value = zoom;
    
    try {
      mapController.move(center, zoom);
    } catch (e) {
      DebugLogger.warning('⚠️ Could not move map: $e');
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
    if (state.value == ExploreState.loading) return;

    try {
      state.value = ExploreState.loading;
      error.value = null;
      properties.clear();
      selectedProperty.value = null;

      DebugLogger.api('🗺️ Loading all properties for map view');

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

      if (properties.isEmpty) {
        state.value = ExploreState.empty;
      } else {
        state.value = ExploreState.loaded;
        DebugLogger.success('✅ Loaded ${properties.length} properties for map');
      }

    } catch (e) {
      DebugLogger.error('❌ Failed to load properties: $e');
      state.value = ExploreState.error;
      error.value = e.toString();
    } finally {
      loadingProgress.value = 0;
      totalPages.value = 1;
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