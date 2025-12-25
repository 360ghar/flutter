import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/controllers/location_controller.dart';
import 'package:ghar360/core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/models/page_state_model.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/data/repositories/swipes_repository.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_mapper.dart';
import 'package:ghar360/core/widgets/common/property_filter_widget.dart';
import 'package:latlong2/latlong.dart';

enum ExploreState { initial, loading, loaded, empty, error, loadingMore }

class ExploreController extends GetxController {
  final SwipesRepository _swipesRepository = Get.find<SwipesRepository>();
  final LocationController _locationController = Get.find<LocationController>();
  final PageStateService _pageStateService = Get.find<PageStateService>();

  // Map controller
  final MapController mapController = MapController();
  // Map readiness flag to prevent premature controller calls
  final RxBool isMapReady = false.obs;

  // Reactive state
  final Rx<ExploreState> state = ExploreState.initial.obs;
  final RxList<PropertyModel> properties = <PropertyModel>[].obs;
  final Rxn<AppException> error = Rxn<AppException>();

  // Local liked overrides to reflect immediate UI without mutating model
  final RxMap<int, bool> likedOverrides = <int, bool>{}.obs;

  Timer? _retryTimer;

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

  // Page activation listener
  Worker? _pageActivationWorker;

  // Memoized markers cache
  List<PropertyMarker>? _cachedPropertyMarkers;
  bool _markersDirty = true;
  // Revision to ensure Obx always consumes a reactive when markers change
  final RxInt markersRevision = 0.obs;

  @override
  void onInit() {
    super.onInit();
    DebugLogger.info('🚀 ExploreController onInit() started.');

    // Don't set current page here - let navigation handle it

    // Add state listener for debugging
    ever(state, (ExploreState currentState) {
      DebugLogger.debug('📊 ExploreState changed: $currentState (props: ${properties.length})');
    });

    // Add properties listener for debugging and cache invalidation
    ever(properties, (List<PropertyModel> props) {
      DebugLogger.debug('🏠 Properties updated: ${props.length}');
      _invalidateMarkers('properties changed');
    });

    // Invalidate markers cache when selection or zoom changes
    ever<PropertyModel?>(selectedProperty, (_) => _invalidateMarkers('selection changed'));
    ever<double>(currentZoom, (_) => _invalidateMarkers('zoom changed'));

    _setupFilterListener();
    _setupLocationListener();
    // LAZY LOADING: Remove initial data loading from onInit
  }

  @override
  void onReady() {
    super.onReady();
    DebugLogger.debug('✅ ExploreController ready: ${state.value}');

    // Set up listener for page activation
    _pageActivationWorker = ever(_pageStateService.currentPageType, (pageType) {
      if (pageType == PageType.explore) {
        activatePage();
      }
    });

    // Initial activation if already on this page (with delay to ensure full initialization)
    final currentPageType = _pageStateService.currentPageType.value;
    if (currentPageType == PageType.explore) {
      Future.delayed(const Duration(milliseconds: 100), () {
        activatePage();
      });
    }
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    _mapMoveDebouncer?.cancel();
    _retryTimer?.cancel();
    _pageActivationWorker?.dispose();
    mapController.dispose();
    super.onClose();
  }

  void activatePage() {
    DebugLogger.debug('🎯 ExploreController.activatePage()');
    final pageState = _pageStateService.exploreState.value;

    // If initial or empty, initialize map center and trigger page data load
    if ((!pageState.hasLocation && state.value == ExploreState.initial) ||
        (pageState.properties.isEmpty && properties.isEmpty)) {
      _initializeMapAndLoadProperties();
      return;
    }

    // Data present or being loaded: sync properties and state
    properties.assignAll(pageState.properties);
    if (pageState.isLoading) {
      state.value = ExploreState.loading;
    } else if (pageState.error != null) {
      state.value = ExploreState.error;
      error.value = pageState.error;
    } else {
      state.value = properties.isEmpty ? ExploreState.empty : ExploreState.loaded;
    }
  }

  // Called by the view when FlutterMap reports ready
  void onMapReady() {
    if (isMapReady.value) return;
    isMapReady.value = true;
    DebugLogger.success('✅ Explore map is ready.');

    // Immediately move camera to the location from PageStateService
    final pageState = _pageStateService.exploreState.value;
    if (pageState.hasLocation) {
      final center = LatLng(
        pageState.selectedLocation!.latitude,
        pageState.selectedLocation!.longitude,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          mapController.move(center, currentZoom.value);
          DebugLogger.info('🎯 Synced camera on map ready to $center');

          // Update reactive values to match the camera position
          currentCenter.value = center;
        } catch (e) {
          DebugLogger.warning('⚠️ Could not sync camera on map ready: $e');
          // Fallback to current reactive values
          try {
            mapController.move(currentCenter.value, currentZoom.value);
            DebugLogger.info('🔄 Fallback: Synced camera to current center ${currentCenter.value}');
          } catch (fallbackError) {
            DebugLogger.error('❌ Fallback camera move also failed: $fallbackError');
          }
        }
      });
    } else {
      // No location set yet, use current reactive values but ensure they're not default
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          // Check if current center is still the default location
          final defaultCenter = const LatLng(28.6139, 77.2090); // Default: Delhi
          if (currentCenter.value == defaultCenter) {
            DebugLogger.info(
              '📍 Map ready but still showing default location - waiting for user location',
            );
          }

          mapController.move(currentCenter.value, currentZoom.value);
          DebugLogger.info(
            '🎯 Synced camera on map ready to ${currentCenter.value} @ ${currentZoom.value}',
          );
        } catch (e) {
          DebugLogger.warning('⚠️ Could not sync camera on map ready: $e');
        }
      });
    }
  }

  void _setupFilterListener() {
    DebugLogger.info('🔧 Setting up filter listener');
    // React to page state changes by syncing local list/state
    debounce(_pageStateService.exploreState, (pageState) {
      try {
        DebugLogger.info(
          '🔍 [EXPLORE_CONTROLLER] Explore page state updated; syncing properties and UI',
        );

        final isCurrentPage = _pageStateService.currentPageType.value == PageType.explore;
        if (!isCurrentPage) return;

        // Filter out properties with broken getters to avoid null check errors in UI
        final safeProperties = <PropertyModel>[];
        for (int i = 0; i < pageState.properties.length; i++) {
          try {
            final property = pageState.properties[i];

            // Validate common getters that might cause null check errors
            property.mainImage; // This accesses images?.first.imageUrl
            property.formattedPrice; // This accesses pricing fields
            property.addressDisplay; // This accesses location fields

            safeProperties.add(property);
          } catch (e, stackTrace) {
            DebugLogger.error(
              '🚨 [EXPLORE_CONTROLLER] FOUND THE PROBLEMATIC PROPERTY at index $i: $e',
            );
            DebugLogger.debug('🚨 Stack trace: $stackTrace');
          }
        }

        DebugLogger.debug(
          '📊 [EXPLORE] Assigning ${safeProperties.length}/${pageState.properties.length} properties',
        );
        properties.assignAll(safeProperties);
      } catch (e, stackTrace) {
        DebugLogger.error('🚨 [EXPLORE_CONTROLLER] ERROR in debounce worker: $e');
        DebugLogger.error('🚨 [EXPLORE_CONTROLLER] Stack trace: $stackTrace');

        if (e.toString().contains('Null check operator used on a null value')) {
          DebugLogger.error(
            '🚨 [EXPLORE_CONTROLLER] NULL CHECK OPERATOR ERROR in debounce worker!',
          );
        }

        // Don't rethrow to prevent UI crashes, but log the error
        return;
      }

      // Preserve selection if still present, otherwise clear
      final sel = selectedProperty.value;
      if (sel != null && !properties.any((p) => p.id == sel.id)) {
        selectedProperty.value = null;
      }

      // Sync state
      // Keep radius in sync with filters from state
      final radiusFromState = (pageState.filters.radiusKm ?? 10.0).clamp(5.0, 50.0);
      if ((currentRadius.value - radiusFromState).abs() > 0.01) {
        currentRadius.value = radiusFromState;
        DebugLogger.info('📏 Synced map radius from state: ${currentRadius.value}km');
      }

      if (pageState.isLoading) {
        state.value = ExploreState.loading;
      } else if (pageState.error != null) {
        state.value = ExploreState.error;
        error.value = pageState.error;
      } else {
        // Clear any stale controller error when page state is healthy
        if (error.value != null) {
          error.value = null;
        }
        state.value = properties.isEmpty ? ExploreState.empty : ExploreState.loaded;
      }
    }, time: const Duration(milliseconds: 200));
  }

  void _setupLocationListener() {
    // Listen to location updates
    _locationController.currentPosition.listen((position) {
      if (position != null) {
        final newCenter = LatLng(position.latitude, position.longitude);
        final distance = const Distance();
        if (distance.as(LengthUnit.Meter, currentCenter.value, newCenter) > 1000) {
          // Only update if >1km difference
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

      // Prioritize location from PageStateService if available
      if (_pageStateService.exploreState.value.hasLocation) {
        final location = _pageStateService.exploreState.value.selectedLocation;
        if (location != null) {
          initialCenter = LatLng(location.latitude, location.longitude);
          DebugLogger.info(
            '🗺️ Using location from PageStateService: $initialCenter (lat: ${location.latitude}, lng: ${location.longitude})',
          );
        }
      } else {
        // Try to get current device location, but don't block if it fails
        DebugLogger.info('🗺️ Attempting to get current device location...');
        try {
          await _locationController.getCurrentLocation();
          if (_locationController.hasLocation) {
            final pos = _locationController.currentPosition.value;
            if (pos != null) {
              initialCenter = LatLng(pos.latitude, pos.longitude);
              initialZoom = 14.0; // Zoom in closer for current location
              DebugLogger.info(
                '🗺️ Using current device location: $initialCenter (lat: ${pos.latitude}, lng: ${pos.longitude})',
              );
            }
          } else {
            DebugLogger.warning(
              '⚠️ LocationController.hasLocation is false after getCurrentLocation call',
            );
          }
        } catch (locationError) {
          DebugLogger.warning(
            '⚠️ Device location failed: $locationError. Trying IP-based location...',
          );
        }

        // Try IP-based location if device location failed
        if (!_locationController.hasLocation) {
          try {
            final ipLoc = await _locationController.getIpLocation();
            if (ipLoc != null) {
              initialCenter = LatLng(ipLoc.latitude, ipLoc.longitude);
              initialZoom = 12.0;
              DebugLogger.info(
                '🗺️ Using IP-based location: $initialCenter (lat: ${ipLoc.latitude}, lng: ${ipLoc.longitude})',
              );
            } else {
              DebugLogger.warning('⚠️ IP-based location returned null. Using default.');
            }
          } catch (ipError) {
            DebugLogger.warning('⚠️ IP-based location failed: $ipError. Using default.');
          }
        }
      }

      DebugLogger.info(
        '🎯 Final initialization parameters: center=$initialCenter, zoom=$initialZoom',
      );

      // Update map and filters with the determined location
      _updateMapCenter(initialCenter, initialZoom);

      // Ensure we set the location; radius will be taken from state filters
      final locationData = LocationData(
        name: 'Initial Location',
        latitude: initialCenter.latitude,
        longitude: initialCenter.longitude,
      );
      await _pageStateService.updateLocation(locationData, source: 'initial');

      // Ensure Explore page state's location is set for repository queries
      await _pageStateService.updateLocationForPage(
        PageType.explore,
        LocationData(
          name: 'Current Area', // Will be reverse geocoded in PageStateService
          latitude: initialCenter.latitude,
          longitude: initialCenter.longitude,
        ),
        source: 'initial',
      );

      DebugLogger.info('🚀 Triggering page data load through PageStateService');
      state.value = ExploreState.loading;
      await _pageStateService.loadPageData(PageType.explore, forceRefresh: true);
      // Sync properties from page state
      properties.assignAll(_pageStateService.exploreState.value.properties);
      state.value = properties.isEmpty ? ExploreState.empty : ExploreState.loaded;
    } catch (e, stackTrace) {
      DebugLogger.error('❌ CRITICAL: Failed during initialization', e, stackTrace);
      state.value = ExploreState.error;
      error.value = ErrorMapper.mapApiError(
        'Failed to initialize the map. Please check location services and try again.',
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      DebugLogger.info('📍 Getting current location...');
      await _locationController.getCurrentLocation();
      final position = _locationController.currentPosition.value;
      if (position != null) {
        DebugLogger.success(
          '✅ Current location obtained: lat=${position.latitude}, lng=${position.longitude}',
        );
        _updateMapCenter(LatLng(position.latitude, position.longitude), 14.0);

        // Update filters with current location
        final locationData = LocationData(
          name: 'Current Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );
        await _pageStateService.updateLocation(locationData, source: 'gps');
        // Update radius if needed
        final currentFilters = _pageStateService.getCurrentPageState().filters;
        final updatedFilters = currentFilters.copyWith(radiusKm: currentRadius.value);
        _pageStateService.updatePageFilters(PageType.explore, updatedFilters);

        // Sync Explore page state location for subsequent loads
        await _pageStateService.updateLocationForPage(
          PageType.explore,
          LocationData(
            name: 'Current Location', // Will be reverse geocoded in PageStateService
            latitude: position.latitude,
            longitude: position.longitude,
          ),
          source: 'gps',
        );
      } else {
        DebugLogger.warning('⚠️ LocationController returned null position, using default location');
        // Use default location (Delhi) if location is not available
        _updateMapCenter(const LatLng(28.6139, 77.2090), 12.0);
        final locationData = const LocationData(
          name: 'Delhi, India',
          latitude: 28.6139,
          longitude: 77.2090,
        );
        await _pageStateService.updateLocation(locationData, source: 'default');
        // Update radius if needed
        final currentFilters = _pageStateService.getCurrentPageState().filters;
        final updatedFilters = currentFilters.copyWith(radiusKm: currentRadius.value);
        _pageStateService.updatePageFilters(PageType.explore, updatedFilters);

        await _pageStateService.updateLocationForPage(
          PageType.explore,
          const LocationData(name: 'Delhi', latitude: 28.6139, longitude: 77.2090),
          source: 'fallback',
        );
      }
    } catch (e) {
      DebugLogger.warning('⚠️ Could not get current location: $e');
      // Always fallback to default location
      DebugLogger.info('🗺️ Falling back to default location (Delhi)');
      _updateMapCenter(const LatLng(28.6139, 77.2090), 12.0);
      final locationData = const LocationData(
        name: 'Delhi, India',
        latitude: 28.6139,
        longitude: 77.2090,
      );
      await _pageStateService.updateLocation(locationData, source: 'default');
      // Update radius if needed
      final currentFilters = _pageStateService.getCurrentPageState().filters;
      final updatedFilters = currentFilters.copyWith(radiusKm: currentRadius.value);
      _pageStateService.updatePageFilters(PageType.explore, updatedFilters);

      await _pageStateService.updateLocationForPage(
        PageType.explore,
        const LocationData(name: 'Delhi', latitude: 28.6139, longitude: 77.2090),
        source: 'fallback',
      );
    }
  }

  void _updateMapCenter(LatLng center, double zoom) {
    try {
      // Always update reactive state first
      currentCenter.value = center;
      currentZoom.value = zoom;
      DebugLogger.info('🗺️ Updated reactive map center to $center with zoom $zoom');

      // Only move the controller once the map is ready/rendered
      if (isMapReady.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            mapController.move(center, zoom);
            DebugLogger.info('✅ Map controller moved successfully');
          } catch (e) {
            DebugLogger.warning('⚠️ Could not move map (post-frame): $e');
          }
        });
      } else {
        DebugLogger.debug('⏳ Map not ready; deferred camera move');
      }
    } catch (e) {
      DebugLogger.warning('⚠️ Could not move map: $e');
      // Still update the reactive values even if map move fails
      currentCenter.value = center;
      currentZoom.value = zoom;
    }
  }

  // Map movement handler with debounce
  void onMapMove(MapCamera position, bool hasGesture) {
    if (!hasGesture) {
      return; // Ignore programmatic moves
    }
    if (!isMapReady.value) {
      return;
    }
    // Compute deltas before mutating reactive values
    final prevCenter = currentCenter.value;
    final prevZoom = currentZoom.value;
    final distanceMeters = const Distance().as(LengthUnit.Meter, prevCenter, position.center);
    final zoomDelta = (position.zoom - prevZoom).abs();

    currentCenter.value = position.center;
    currentZoom.value = position.zoom;

    // Debounce the map move to avoid too many API calls
    // Only proceed if movement is significant to reduce churn
    if (zoomDelta > 0.1 || distanceMeters > 100) {
      _mapMoveDebouncer?.cancel();
      _mapMoveDebouncer = Timer(const Duration(milliseconds: 600), () {
        _onMapMoveCompleted();
      });
    }
  }

  Future<void> _onMapMoveCompleted() async {
    // Update filters with new location
    try {
      final locationData = LocationData(
        name: 'Map Location',
        latitude: currentCenter.value.latitude,
        longitude: currentCenter.value.longitude,
      );
      await _pageStateService.updateLocation(locationData, source: 'map');
      // Update radius if needed
      final currentFilters = _pageStateService.getCurrentPageState().filters;
      final updatedFilters = currentFilters.copyWith(radiusKm: currentRadius.value);
      _pageStateService.updatePageFilters(PageType.explore, updatedFilters);
      DebugLogger.success('✅ Filter location updated successfully');

      // Keep PageStateService in sync so map queries use correct location
      await _pageStateService.updateLocationForPage(
        PageType.explore,
        LocationData(
          name: 'Selected Area', // Will be reverse geocoded in PageStateService
          latitude: currentCenter.value.latitude,
          longitude: currentCenter.value.longitude,
        ),
        source: 'manual',
      );
    } catch (e) {
      DebugLogger.error('❌ Failed to update filter location: $e');
    }
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query;

    _searchDebouncer?.cancel();

    if (query.isEmpty) {
      _pageStateService.updatePageSearch(PageType.explore, '');
      return;
    }

    _searchDebouncer = Timer(const Duration(milliseconds: 300), () {
      DebugLogger.api('🔍 Searching properties: "$query"');
      _pageStateService.updatePageSearch(PageType.explore, query);
    });
  }

  void clearSearch() {
    searchQuery.value = '';
    _pageStateService.updatePageSearch(PageType.explore, '');
  }

  // Likes handling
  bool isPropertyLiked(PropertyModel property) {
    try {
      if (likedOverrides.containsKey(property.id)) {
        return likedOverrides[property.id] ?? property.liked;
      }
      return property.liked;
    } catch (_) {
      return property.liked;
    }
  }

  Future<void> toggleLike(PropertyModel property) async {
    final current = isPropertyLiked(property);
    final next = !current;

    // Optimistic update
    likedOverrides[property.id] = next;

    try {
      await _swipesRepository.recordSwipe(propertyId: property.id, isLiked: next);
      DebugLogger.success('✅ Updated like: ${property.title} -> $next');
    } catch (e) {
      DebugLogger.error('❌ Failed to toggle like: $e');
      // Revert on failure
      likedOverrides[property.id] = current;
      Get.snackbar(
        'Action failed',
        'Could not update like. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Property selection
  void selectProperty(PropertyModel property) {
    // Selection now only highlights marker/card; does not move camera
    selectedProperty.value = property;
    DebugLogger.api('🏠 Selected property (highlight only): ${property.title}');
  }

  // Explicit highlight from card scroll (no camera changes)
  void highlightPropertyFromCard(PropertyModel property) {
    if (selectedProperty.value?.id == property.id) return;
    selectedProperty.value = property;
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
    try {
      showPropertyFilterBottomSheet(Get.context!, pageType: 'explore');
    } catch (_) {
      // Fallback: no context available; ignore
    }
  }

  void quickFilterByType(PropertyType type) {
    final currentFilters = _pageStateService.getCurrentPageState().filters;
    // Use the JSON value (e.g., 'house') instead of enum toString() (e.g., 'PropertyType.house')
    final typeValue = type.name; // Dart 2.17+ enum name returns 'house', 'apartment', etc.
    final updatedFilters = currentFilters.copyWith(propertyType: [typeValue]);
    _pageStateService.updatePageFilters(PageType.explore, updatedFilters);
  }

  void quickFilterByPurpose(PropertyPurpose purpose) {
    final currentFilters = _pageStateService.getCurrentPageState().filters;
    // Use the JSON value (e.g., 'buy') instead of enum toString() (e.g., 'PropertyPurpose.buy')
    final purposeValue = purpose.name; // 'buy', 'rent', 'shortStay'
    final updatedFilters = currentFilters.copyWith(purpose: purposeValue);
    _pageStateService.updatePageFilters(PageType.explore, updatedFilters);
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

    if (!isMapReady.value) {
      DebugLogger.info('⏳ Map not ready; skipping fitBounds for now');
      return;
    }

    try {
      // Safe extraction of coordinates - filter out any null values
      final lats = propertiesWithLocation
          .map((p) => p.latitude)
          .where((lat) => lat != null)
          .cast<double>()
          .toList();
      final lngs = propertiesWithLocation
          .map((p) => p.longitude)
          .where((lng) => lng != null)
          .cast<double>()
          .toList();

      // Ensure we have valid coordinates before proceeding
      if (lats.isEmpty || lngs.isEmpty) {
        DebugLogger.warning('No valid coordinates found in propertiesWithLocation');
        return;
      }

      final minLat = lats.reduce((a, b) => a < b ? a : b);
      final maxLat = lats.reduce((a, b) => a > b ? a : b);
      final minLng = lngs.reduce((a, b) => a < b ? a : b);
      final maxLng = lngs.reduce((a, b) => a > b ? a : b);

      final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        } catch (e) {
          DebugLogger.warning('⚠️ fitBounds failed post-frame: $e');
        }
      });
    } catch (e) {
      DebugLogger.warning('⚠️ Could not fit bounds: $e');
    }
  }

  // Refresh
  Future<void> refreshProperties() async {
    DebugLogger.info('🔄 Manual refresh requested');
    await _pageStateService.loadPageData(PageType.explore, forceRefresh: true);
  }

  // Error handling
  void retryLoading() {
    DebugLogger.info('🔄 Manual retry loading requested');
    _retryTimer?.cancel(); // Cancel any ongoing retry
    error.value = null;
    state.value = ExploreState.initial; // Reset state to allow retry
    _pageStateService.loadPageData(PageType.explore, forceRefresh: true);
  }

  void clearError() {
    DebugLogger.info('🧹 Clearing error state');
    error.value = null;
    if (state.value == ExploreState.error) {
      final newState = properties.isEmpty ? ExploreState.empty : ExploreState.loaded;
      DebugLogger.info('📊 Changing state from error to: $newState');
      state.value = newState;
    }
  }

  // Statistics and info
  String get locationDisplayText => _pageStateService.getCurrentPageState().locationDisplayText;

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
    try {
      final result = properties
          .where((p) => p.hasLocation && p.latitude != null && p.longitude != null)
          .toList();
      DebugLogger.info('🗺️ propertiesWithLocation: ${result.length}/${properties.length}');
      return result;
    } catch (e) {
      DebugLogger.error('❌ Error in propertiesWithLocation: $e');
      return [];
    }
  }

  String _deriveMarkerLabel(PropertyModel property) {
    // Build an Indian-style compact price like ₹15k, ₹75L, ₹1.2Cr
    try {
      final price = property.getEffectivePrice();
      if (price <= 0) return '₹--';

      String withPrecision(double v) {
        // Keep one decimal under 10; otherwise, no decimals
        final str = (v < 10 ? v.toStringAsFixed(1) : v.toStringAsFixed(0));
        return str.endsWith('.0') ? str.substring(0, str.length - 2) : str;
      }

      if (price >= 10000000) {
        // Crore
        final val = price / 10000000.0;
        return '₹${withPrecision(val)}Cr';
      } else if (price >= 100000) {
        // Lakh
        final val = price / 100000.0;
        return '₹${withPrecision(val)}L';
      } else if (price >= 1000) {
        // Thousand
        final val = price / 1000.0;
        return '₹${withPrecision(val)}k';
      } else {
        return '₹${price.toStringAsFixed(0)}';
      }
    } catch (_) {
      // Fallback to model's formattedPrice if anything goes wrong
      return property.formattedPrice;
    }
  }

  // Get property markers for map with performance optimization
  List<PropertyMarker> get propertyMarkers {
    try {
      // Return cached markers when nothing relevant changed
      if (!_markersDirty && _cachedPropertyMarkers != null) {
        DebugLogger.debug('⚡ Returning cached property markers: ${_cachedPropertyMarkers!.length}');
        return _cachedPropertyMarkers!;
      }

      final propsWithLocation = propertiesWithLocation;
      DebugLogger.info('🗺️ Generating markers for ${propsWithLocation.length} properties');

      if (propsWithLocation.isEmpty) {
        DebugLogger.info('⚠️ No properties with location found');
        _cachedPropertyMarkers = const <PropertyMarker>[];
        _markersDirty = false;
        return _cachedPropertyMarkers!;
      }

      final markers = <PropertyMarker>[];

      for (final property in propsWithLocation) {
        try {
          // Additional null safety checks
          final lat = property.latitude;
          final lng = property.longitude;

          if (lat == null || lng == null) {
            DebugLogger.warning(
              '⚠️ Property ${property.id} has null coordinates: lat=$lat, lng=$lng',
            );
            continue;
          }

          markers.add(
            PropertyMarker(
              property: property,
              position: LatLng(lat, lng),
              isSelected: selectedProperty.value?.id == property.id,
              label: _deriveMarkerLabel(property),
            ),
          );
        } catch (e) {
          DebugLogger.error('❌ Error creating marker for property ${property.id}: $e');
          continue;
        }
      }

      DebugLogger.info('🗺️ Generated ${markers.length} property markers.');
      _cachedPropertyMarkers = markers;
      _markersDirty = false;
      return _cachedPropertyMarkers!;
    } catch (e) {
      DebugLogger.error('❌ Error generating property markers: $e');
      _cachedPropertyMarkers = const <PropertyMarker>[];
      _markersDirty = false;
      return _cachedPropertyMarkers!;
    }
  }

  void _invalidateMarkers(String reason) {
    _markersDirty = true;
    DebugLogger.debug('🧠 propertyMarkers cache invalidated: $reason');
    // Bump revision so Obx builders reliably consume a reactive
    markersRevision.value++;
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
  final String label;

  PropertyMarker({
    required this.property,
    required this.position,
    required this.isSelected,
    required this.label,
  });
}
