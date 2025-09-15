import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/controllers/location_controller.dart';
import '../../../core/controllers/page_state_service.dart';
import '../../../core/data/models/page_state_model.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/unified_filter_model.dart';
import '../../../core/data/repositories/swipes_repository.dart';
import '../../../core/utils/app_exceptions.dart';
import '../../../core/utils/debug_logger.dart';
import 'package:ghar360/core/widgets/common/property_filter_widget.dart';

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
  final Rxn<AppError> error = Rxn<AppError>();

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

  @override
  void onInit() {
    super.onInit();
    DebugLogger.info('🚀 ExploreController onInit() started.');

    // Don't set current page here - let navigation handle it

    // Add state listener for debugging
    ever(state, (ExploreState currentState) {
      DebugLogger.info('📊 ExploreState changed to: $currentState');
      DebugLogger.info('📊 Properties count: ${properties.length}');
      DebugLogger.info('📊 Has error: ${error.value != null}');
    });

    // Add properties listener for debugging
    ever(properties, (List<PropertyModel> props) {
      DebugLogger.info('🏠 Properties list updated: ${props.length} properties');
      if (props.isNotEmpty) {
        final withLocation = props.where((p) => p.hasLocation).length;
        DebugLogger.info('🗺️ Properties with location: $withLocation/${props.length}');
      }
    });

    _setupFilterListener();
    _setupLocationListener();
    // LAZY LOADING: Remove initial data loading from onInit
  }

  @override
  void onReady() {
    super.onReady();
    DebugLogger.success('✅ ExploreController is ready! Current state: ${state.value}');

    // Set up listener for page activation
    _pageActivationWorker = ever(_pageStateService.currentPageType, (pageType) {
      DebugLogger.info('📱 Page type changed to: $pageType');
      if (pageType == PageType.explore) {
        DebugLogger.info('🎯 Explore page activated via page type listener');
        activatePage();
      }
    });

    // Initial activation if already on this page (with delay to ensure full initialization)
    final currentPageType = _pageStateService.currentPageType.value;
    DebugLogger.info('📋 Current page type on ready: $currentPageType');
    if (currentPageType == PageType.explore) {
      DebugLogger.info('⏰ Scheduling initial activation with delay');
      Future.delayed(const Duration(milliseconds: 100), () {
        DebugLogger.info('🎯 Initial activation triggered');
        activatePage();
      });
    } else {
      DebugLogger.info('⏸️ Skipping initial activation - not on explore page');
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
    DebugLogger.info('🎯 ExploreController.activatePage() called');
    final pageState = _pageStateService.exploreState.value;
    DebugLogger.info('📋 PageState properties: ${pageState.properties.length}');
    DebugLogger.info('📋 Controller state: ${state.value}');
    DebugLogger.info('📋 Controller properties: ${properties.length}');
    DebugLogger.info('📋 Is data stale: ${pageState.isDataStale}');

    // If initial or empty, initialize map center and trigger page data load
    if ((!pageState.hasLocation && state.value == ExploreState.initial) ||
        (pageState.properties.isEmpty && properties.isEmpty)) {
      DebugLogger.info('🎯 Initializing map and triggering page data load');
      _initializeMapAndLoadProperties();
      return;
    }

    // Data present or being loaded: sync properties and state
    DebugLogger.info('✅ Syncing controller with PageStateService');
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
        DebugLogger.api(
          '📊 [EXPLORE_CONTROLLER] Page state properties count: ${pageState.properties.length}',
        );
        DebugLogger.api('📊 [EXPLORE_CONTROLLER] Page state error: ${pageState.error}');
        DebugLogger.api('📊 [EXPLORE_CONTROLLER] Page state isLoading: ${pageState.isLoading}');

        final isCurrentPage = _pageStateService.currentPageType.value == PageType.explore;
        if (!isCurrentPage) return;

        DebugLogger.info('📊 [EXPLORE_CONTROLLER] Current page is explore, proceeding with sync');

        // Sync properties - this is where the null check operator error likely occurs
        DebugLogger.api(
          '📊 [EXPLORE_CONTROLLER] About to call properties.assignAll() with ${pageState.properties.length} properties',
        );

        // Check each property individually before assigning to identify the problematic one
        final safeProperties = <PropertyModel>[];
        for (int i = 0; i < pageState.properties.length; i++) {
          try {
            final property = pageState.properties[i];
            DebugLogger.debug(
              '📊 [EXPLORE_CONTROLLER] Checking property $i: ${property.id} - ${property.title}',
            );

            // Try accessing common getters that might cause null check errors
            property.mainImage; // This accesses images?.first.imageUrl
            property.formattedPrice; // This accesses pricing fields
            property.addressDisplay; // This accesses location fields

            DebugLogger.debug('📊 [EXPLORE_CONTROLLER] Property $i passed all getter checks');
            safeProperties.add(property);
          } catch (e, stackTrace) {
            DebugLogger.error(
              '🚨 [EXPLORE_CONTROLLER] FOUND THE PROBLEMATIC PROPERTY at index $i: $e',
            );
            DebugLogger.error('🚨 [EXPLORE_CONTROLLER] Property ID: ${pageState.properties[i].id}');
            DebugLogger.error(
              '🚨 [EXPLORE_CONTROLLER] Property title: ${pageState.properties[i].title}',
            );
            DebugLogger.error('🚨 [EXPLORE_CONTROLLER] Stack trace: $stackTrace');

            if (e.toString().contains('Null check operator used on a null value')) {
              DebugLogger.error(
                '🚨 [EXPLORE_CONTROLLER] NULL CHECK OPERATOR ERROR confirmed in property getter!',
              );
              DebugLogger.error('🚨 [EXPLORE_CONTROLLER] This is the root cause of the error!');
            }

            // Skip this problematic property and continue with others
          }
        }

        DebugLogger.api(
          '📊 [EXPLORE_CONTROLLER] Assigning ${safeProperties.length} safe properties out of ${pageState.properties.length} total',
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
      error.value = AppError(
        error: "Failed to initialize the map. Please check location services and try again.",
        stackTrace: stackTrace,
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
        final locationData = LocationData(
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
          LocationData(name: 'Delhi', latitude: 28.6139, longitude: 77.2090),
          source: 'fallback',
        );
      }
    } catch (e) {
      DebugLogger.warning('⚠️ Could not get current location: $e');
      // Always fallback to default location
      DebugLogger.info('🗺️ Falling back to default location (Delhi)');
      _updateMapCenter(const LatLng(28.6139, 77.2090), 12.0);
      final locationData = LocationData(
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
        LocationData(name: 'Delhi', latitude: 28.6139, longitude: 77.2090),
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
        DebugLogger.info('⏳ Map not ready yet; deferred camera move');
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
      DebugLogger.info('🗺️ Map moved programmatically to ${position.center}, ignoring');
      return; // Ignore programmatic moves
    }
    if (!isMapReady.value) {
      DebugLogger.info('⏳ Map move ignored; map not ready');
      return;
    }
    // Compute deltas before mutating reactive values
    final prevCenter = currentCenter.value;
    final prevZoom = currentZoom.value;
    final distanceMeters = const Distance().as(LengthUnit.Meter, prevCenter, position.center);
    final zoomDelta = (position.zoom - prevZoom).abs();

    DebugLogger.info(
      '🗺️ Map moved by user gesture to ${position.center}, zoom: ${position.zoom} (Δz=${zoomDelta.toStringAsFixed(2)}, Δd=${distanceMeters.toStringAsFixed(0)}m)',
    );
    currentCenter.value = position.center;
    currentZoom.value = position.zoom;

    // Debounce the map move to avoid too many API calls
    // Only proceed if movement is significant to reduce churn
    if (zoomDelta > 0.1 || distanceMeters > 100) {
      _mapMoveDebouncer?.cancel();
      _mapMoveDebouncer = Timer(const Duration(milliseconds: 600), () {
        DebugLogger.info('🔄 Map move debounce completed, updating location');
        _onMapMoveCompleted();
      });
    } else {
      DebugLogger.info('🧯 Ignoring minor map movement');
    }
  }

  Future<void> _onMapMoveCompleted() async {
    DebugLogger.api(
      '🗺️ Map move completed at ${currentCenter.value}, radius: ${currentRadius.value}km',
    );

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
    final updatedFilters = currentFilters.copyWith(propertyType: [type.toString()]);
    _pageStateService.updatePageFilters(PageType.explore, updatedFilters);
  }

  void quickFilterByPurpose(PropertyPurpose purpose) {
    final currentFilters = _pageStateService.getCurrentPageState().filters;
    final updatedFilters = currentFilters.copyWith(purpose: purpose.toString());
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

  // Get property markers for map with performance optimization
  List<PropertyMarker> get propertyMarkers {
    try {
      final propsWithLocation = propertiesWithLocation;
      DebugLogger.info('🗺️ Generating markers for ${propsWithLocation.length} properties');

      if (propsWithLocation.isEmpty) {
        DebugLogger.info('⚠️ No properties with location found');
        return [];
      }

      // Performance optimization: limit markers based on zoom level
      final zoom = currentZoom.value;
      int maxMarkers;

      if (zoom >= 15) {
        maxMarkers = 200; // Very close zoom - show more markers
      } else if (zoom >= 13) {
        maxMarkers = 100; // Medium zoom - moderate markers
      } else if (zoom >= 11) {
        maxMarkers = 50; // Far zoom - fewer markers
      } else {
        maxMarkers = 25; // Very far zoom - minimal markers
      }

      // Take a subset of properties if too many
      final propertiesSubset = propsWithLocation.length > maxMarkers
          ? propsWithLocation.take(maxMarkers).toList()
          : propsWithLocation;

      if (propsWithLocation.length > maxMarkers) {
        DebugLogger.info(
          '🎯 Performance optimization: showing ${propertiesSubset.length}/${propsWithLocation.length} markers at zoom ${zoom.toStringAsFixed(1)}',
        );
      }

      final markers = <PropertyMarker>[];

      for (final property in propertiesSubset) {
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
            ),
          );
        } catch (e) {
          DebugLogger.error('❌ Error creating marker for property ${property.id}: $e');
          continue;
        }
      }

      DebugLogger.info(
        '🗺️ Generated ${markers.length} property markers from ${propertiesSubset.length} properties with location',
      );
      return markers;
    } catch (e) {
      DebugLogger.error('❌ Error generating property markers: $e');
      return [];
    }
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

  PropertyMarker({required this.property, required this.position, required this.isSelected});
}
