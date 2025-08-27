import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:get_storage/get_storage.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/location_model.dart';
import '../../../core/data/models/page_state_model.dart';
import '../../../core/data/models/unified_filter_model.dart';
import '../../../core/data/repositories/properties_repository.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/controllers/page_state_service.dart';
import '../../../widgets/common/property_filter_widget.dart';

enum ExploreState { initial, loading, loaded, empty, error, loadingMore }

class ExploreController extends GetxController {
  final PropertiesRepository _propertiesRepository =
      Get.find<PropertiesRepository>();
  final FilterService _filterService = Get.find<FilterService>();
  final LocationController _locationController = Get.find<LocationController>();
  final PageStateService _pageStateService = Get.find<PageStateService>();

  // Map controller
  final MapController mapController = MapController();

  // Scroll controller for horizontal list
  final ScrollController horizontalScrollController = ScrollController();

  // Reactive state
  final Rx<ExploreState> state = ExploreState.initial.obs;
  final RxList<PropertyModel> properties = <PropertyModel>[].obs;
  final RxString errorMessage = ''.obs;

  // Map state
  final Rx<LatLng> mapCenter = const LatLng(28.6139, 77.2090).obs;
  final RxBool isMapReady = false.obs;
  
  // Error recovery
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;

  // Loading states
  final RxBool isLoadingProperties = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt loadingProgress = 0.obs;

  // Map state
  final Rx<LatLng> currentCenter = const LatLng(
    28.6139,
    77.2090,
  ).obs; // Default: Delhi
  final RxDouble currentZoom = 12.0.obs;
  final RxDouble currentRadius = 5.0.obs;


  // Search
  final RxString searchQuery = ''.obs;
  final RxBool isSearchActive = false.obs;
  final RxList<LocationResult> searchResults = <LocationResult>[].obs;
  Timer? _searchDebouncer;
  Timer? _mapMoveDebouncer;

  // Location state
  final RxBool hasLocation = false.obs;
  final RxString currentLocationText = 'Delhi, India'.obs;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxBool hasNextPage = true.obs;
  static const int pageSize = 20;

  // Selected property for bottom sheet
  final Rx<PropertyModel?> selectedProperty = Rx<PropertyModel?>(null);
  final RxInt selectedPropertyIndex = RxInt(-1);

  // Property markers as reactive list
  final RxList<PropertyMarker> propertyMarkers = <PropertyMarker>[].obs;

  // Liked properties tracking (since PropertyModel.liked is final)
  final RxMap<String, bool> likedProperties = <String, bool>{}.obs;

  // Explore filters - independent filter management for Explore page
  final Rx<UnifiedFilterModel> exploreFilters = UnifiedFilterModel.initial().obs;

  Future<void> _saveExploreLocation(LatLng location) async {
    try {
      final box = GetStorage();
      await box.write('explore_last_lat', location.latitude);
      await box.write('explore_last_lng', location.longitude);
      DebugLogger.info('💾 Saved explore location: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      DebugLogger.warning('Could not save explore location: $e');
    }
  }

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
      DebugLogger.info('📊 Has error: ${errorMessage.value.isNotEmpty}');
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
    DebugLogger.success(
      '✅ ExploreController is ready! Current state: ${state.value}',
    );

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
    super.onClose();
  }

  void activatePage() {
    DebugLogger.info('🎯 ExploreController.activatePage() called');
    final pageState = _pageStateService.exploreState.value;
    DebugLogger.info('📋 PageState properties: ${pageState.properties.length}');
    DebugLogger.info('📋 Controller state: ${state.value}');
    DebugLogger.info('📋 Controller properties: ${properties.length}');
    DebugLogger.info('📋 Is data stale: ${pageState.isDataStale}');
    
    // More robust condition check - initialize if no properties or if initial state
    if ((pageState.properties.isEmpty && properties.isEmpty) || state.value == ExploreState.initial) {
      DebugLogger.info('🎯 Initializing map and loading properties (first load)');
      _initializeMapAndLoadProperties();
    } else if (pageState.isDataStale) {
      DebugLogger.info('🔄 Data is stale, refreshing in background');
      _refreshInBackground();
        } else {
      DebugLogger.info('✅ Page already has data, syncing controller with page state');
      // Sync controller properties with page state if they differ
      if (properties.length != pageState.properties.length) {
        properties.assignAll(pageState.properties);
        state.value = pageState.properties.isEmpty ? ExploreState.empty : ExploreState.loaded;
      }
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      DebugLogger.info('🔄 Starting background refresh');
      await _loadPropertiesForCurrentView(backgroundRefresh: true);
      DebugLogger.success('✅ Background refresh completed successfully');
    } catch (e, stackTrace) {
      DebugLogger.error('❌ Background refresh failed: $e');
      DebugLogger.error('Background refresh stack trace: $stackTrace');
      // Handle silently or with subtle notification
    }
  }

  void _setupFilterListener() {
    DebugLogger.info('🔧 Setting up filter listener');
    // Listen to page state changes and reload properties
    debounce(_pageStateService.exploreState, (pageState) {
      DebugLogger.info('🔍 Page state changed via filter listener');
      DebugLogger.info('📊 New page state - properties: ${pageState.properties.length}, loading: ${pageState.isLoading}, filters: ${pageState.activeFiltersCount}');
      
      final isCurrentPage = _pageStateService.currentPageType.value == PageType.explore;
      final isLoading = pageState.isLoading || state.value == ExploreState.loading;
      
      DebugLogger.info('📋 Filter listener check - current page: $isCurrentPage, is loading: $isLoading');
      
      // Only reload if:
      // 1. Not currently loading
      // 2. Page is active
      // 3. Controller is not in initial state (to avoid conflicts with activatePage)
      if (!isLoading && isCurrentPage && state.value != ExploreState.initial) {
        DebugLogger.info('🚀 Triggering property reload via filter listener');
        _loadPropertiesForCurrentView();
      } else {
        DebugLogger.info('⏸️ Skipping filter listener reload - loading: $isLoading, current page: $isCurrentPage, state: ${state.value}');
      }
    }, time: const Duration(milliseconds: 500));
  }

  void _setupLocationListener() {
    // Listen to location updates
    _locationController.currentPosition.listen((position) {
      if (position != null) {
        final newCenter = LatLng(position.latitude, position.longitude);
        final distance = const Distance();
        if (distance.as(LengthUnit.Meter, currentCenter.value, newCenter) >
            1000) {
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
        final location = _pageStateService.exploreState.value.selectedLocation!;
        initialCenter = LatLng(location.latitude, location.longitude);
        DebugLogger.info(
          '🗺️ Using location from PageStateService: $initialCenter (lat: ${location.latitude}, lng: ${location.longitude})',
        );
      } else {
        // Try to get current device location, but don't block if it fails
        DebugLogger.info('🗺️ Attempting to get current device location...');
        try {
          await _locationController.getCurrentLocation();
          if (_locationController.hasLocation) {
            final pos = _locationController.currentPosition.value!;
            initialCenter = LatLng(pos.latitude, pos.longitude);
            initialZoom = 14.0; // Zoom in closer for current location
            DebugLogger.info('🗺️ Using current device location: $initialCenter (lat: ${pos.latitude}, lng: ${pos.longitude})');
        } else {
            DebugLogger.warning(
              '⚠️ LocationController.hasLocation is false after getCurrentLocation call',
            );
          }
        } catch (locationError) {
          DebugLogger.warning('⚠️ Device location failed: $locationError. Trying IP-based location...');
        }
        
        // Try IP-based location if device location failed
        if (!_locationController.hasLocation) {
          try {
            final ipLoc = await _locationController.getIpLocation();
            if (ipLoc != null) {
              initialCenter = LatLng(ipLoc.latitude, ipLoc.longitude);
              initialZoom = 12.0;
              DebugLogger.info('🗺️ Using IP-based location: $initialCenter (lat: ${ipLoc.latitude}, lng: ${ipLoc.longitude})');
            } else {
              DebugLogger.warning('⚠️ IP-based location returned null. Using default.');
            }
          } catch (ipError) {
            DebugLogger.warning('⚠️ IP-based location failed: $ipError. Using default.');
          }
        }
      }

      DebugLogger.info('🎯 Final initialization parameters: center=$initialCenter, zoom=$initialZoom');
      
      // Update map and filters with the determined location
      _updateMapCenter(initialCenter, initialZoom);
      
      final radiusKm = _calculateRadiusFromZoom(initialZoom);
      DebugLogger.info('📍 Updating filters with location - radius: ${radiusKm}km');
      _filterService.updateLocationWithCoordinates(
        latitude: initialCenter.latitude,
        longitude: initialCenter.longitude,
        radiusKm: radiusKm,
      );

      DebugLogger.info('🚀 Starting property loading...');
      // Now, load properties
      await _loadPropertiesForCurrentView();
    } catch (e, stackTrace) {
      DebugLogger.error('❌ CRITICAL: Failed during initialization: $e');
      DebugLogger.error('Stack trace: $stackTrace');
      state.value = ExploreState.error;
      errorMessage.value =
          "Failed to initialize the map. Please check location services and try again.";
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
        _filterService.updateLocationWithCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: currentRadius.value,
        );
      } else {
        DebugLogger.warning(
          '⚠️ LocationController returned null position, using default location',
        );
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
      DebugLogger.info('🗺️ Updated reactive map center to $center with zoom $zoom');

      // Try to move the map controller
      mapController.move(center, zoom);
      DebugLogger.info('✅ Map controller moved successfully');
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

    DebugLogger.info('🗺️ Map moved by user gesture to ${position.center}, zoom: ${position.zoom}');
    currentCenter.value = position.center;
    currentZoom.value = position.zoom;

    // Calculate radius from zoom level and visible bounds
    final newRadius = _calculateRadiusFromZoom(position.zoom);
    if ((newRadius - currentRadius.value).abs() > 0.5) {
      currentRadius.value = newRadius;
      DebugLogger.info('📍 Updated search radius to ${newRadius}km');
    }

    // Debounce the map move to avoid too many API calls
    _mapMoveDebouncer?.cancel();
    _mapMoveDebouncer = Timer(const Duration(milliseconds: 600), () {
      DebugLogger.info('🔄 Map move debounce completed, updating location');
      _onMapMoveCompleted();
    });
  }

  void _onMapMoveCompleted() {
    DebugLogger.api(
      '🗺️ Map move completed at ${currentCenter.value}, radius: ${currentRadius.value}km',
    );

    // Update filters with new location
    try {
    _filterService.updateLocationWithCoordinates(
      latitude: currentCenter.value.latitude,
      longitude: currentCenter.value.longitude,
      radiusKm: currentRadius.value,
    );
      DebugLogger.success('✅ Filter location updated successfully');
    } catch (e) {
      DebugLogger.error('❌ Failed to update filter location: $e');
    }
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
  Future<void> _loadPropertiesForCurrentView({
    bool backgroundRefresh = false,
  }) async {
    try {
      DebugLogger.info(
        backgroundRefresh
            ? '🔄 Background refreshing properties...'
            : '⏳ Starting property loading...',
      );
      DebugLogger.info('📊 Current controller state: ${state.value}');
      DebugLogger.info('🏠 Current properties count: ${properties.length}');
      
      _pageStateService.notifyPageRefreshing(PageType.explore, true);

      // Only set loading if not background refresh
      if (!backgroundRefresh && state.value != ExploreState.loading) {
        state.value = ExploreState.loading;
        isLoadingProperties.value = true;
        DebugLogger.info('📊 Set state to loading');
      }

      errorMessage.value = '';
      if (!backgroundRefresh) {
        properties.clear();
        selectedProperty.value = null;
        DebugLogger.info('🧹 Cleared existing properties and selection');
      }

      final currentFilters = _filterService.currentFilter;
      DebugLogger.api(
        '🗺️ Loading all properties for map view with filters: ${currentFilters.toJson()}',
      );
      DebugLogger.info('📍 Filter has location: ${_filterService.hasLocation}');
      if (_pageStateService.exploreState.value.hasLocation) {
        final location = _pageStateService.exploreState.value.selectedLocation!;
        DebugLogger.info('📍 Filter location: lat=${location.latitude}, lng=${location.longitude}, radius=${currentFilters.radiusKm}');
      }

      // Load all pages sequentially for map display
      final allProperties = await _propertiesRepository.loadAllPropertiesForMap(
        latitude: currentCenter.value.latitude,
        longitude: currentCenter.value.longitude,
        filters: currentFilters,
        limit: 100,
        onProgress: (current, total) {
          loadingProgress.value = current;
          totalPages.value = total;
          DebugLogger.info('📈 Loading progress: $current/$total pages');
        },
      );

      DebugLogger.success('🎉 Repository returned ${allProperties.length} properties');

      if (backgroundRefresh) {
        // For background refresh, merge new data with existing data
        final newProperties = allProperties
            .where(
              (newProp) => !properties.any(
                (existingProp) => existingProp.id == newProp.id,
              ),
            )
            .toList();
        properties.insertAll(0, newProperties);
        DebugLogger.success(
          '✅ Background refresh: added ${newProperties.length} new properties (total: ${properties.length})',
        );
        // Update property markers after background refresh
        _updatePropertyMarkers();
      } else {
        properties.assignAll(allProperties);
        DebugLogger.success(
          '✅ Assigned ${allProperties.length} properties to controller list. Controller now has ${properties.length} properties',
        );
      }

      // Update property markers after properties are loaded
      _updatePropertyMarkers();

      if (properties.isEmpty) {
        DebugLogger.info('📭 No properties found, setting empty state');
        state.value = ExploreState.empty;
      } else {
        if (!backgroundRefresh) {
          DebugLogger.success(
            '✅ Setting loaded state with ${properties.length} properties',
          );
        state.value = ExploreState.loaded;
      }

        // Log marker information
        final withLocation = properties.where((p) => p.hasLocation).length;
        DebugLogger.info('🗺️ Properties with location for markers: $withLocation/${properties.length}');
      }
      
      // Reset retry count on successful load
      _retryCount = 0;
    } catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to load properties: $e');
      DebugLogger.error('Stack trace: $stackTrace');
      
      // Increment retry count
      _retryCount++;
      
      if (_retryCount <= _maxRetries && !backgroundRefresh) {
        DebugLogger.info('🔄 Attempting retry $_retryCount/$_maxRetries after error');
        
        // Exponential backoff: wait 2^retryCount seconds
        final retryDelay = Duration(seconds: (2 * _retryCount).clamp(2, 8));
        DebugLogger.info('⏰ Retrying in ${retryDelay.inSeconds} seconds');
        
        _retryTimer?.cancel();
        _retryTimer = Timer(retryDelay, () {
          DebugLogger.info('🔄 Executing retry attempt $_retryCount');
          _loadPropertiesForCurrentView(backgroundRefresh: backgroundRefresh);
        });
      } else {
        // Max retries reached or background refresh failed
        DebugLogger.error('❌ Max retries reached or background refresh failed');
        state.value = ExploreState.error;
        errorMessage.value = _buildUserFriendlyError(e);
        _retryCount = 0; // Reset for next attempt
      }
    } finally {
      loadingProgress.value = 0;
      totalPages.value = 1;
      isLoadingProperties.value = false;
      DebugLogger.info('🔄 Cleanup completed for property loading');
      _pageStateService.notifyPageRefreshing(PageType.explore, false);
    }
  }

  // Search functionality
  Future<void> updateSearchQuery(String query) async {
    searchQuery.value = query;

    _searchDebouncer?.cancel();

    if (query.isEmpty) {
      _locationController.clearPlaceSuggestions();
      searchResults.clear();
      _filterService.updateSearchQuery('');
      return;
    }

    // First, search for locations/places
    _searchDebouncer = Timer(const Duration(milliseconds: 300), () async {
      DebugLogger.api('🔍 Searching locations: "$query"');

      try {
        await _locationController.getPlaceSuggestions(query);
        // Update searchResults with location suggestions
        searchResults.assignAll(_locationController.placeSuggestions.map((suggestion) {
          return LocationResult(
            placeId: suggestion.placeId,
            description: suggestion.description,
            displayText: suggestion.mainText,
            structuredFormatting: suggestion.secondaryText,
            coordinates: null, // Will be fetched when selected
          );
        }));

        DebugLogger.success('✅ Found ${searchResults.length} location suggestions');
      } catch (e) {
        DebugLogger.error('❌ Error searching locations: $e');
        searchResults.clear();
      }
    });
  }

  void clearSearch() {
    searchQuery.value = '';
    searchResults.clear();
    _locationController.clearPlaceSuggestions();
    _filterService.updateSearchQuery('');
  }

  // Property selection
  void selectProperty(PropertyModel property) {
    selectedProperty.value = property;
    DebugLogger.api('🏠 Selected property: ${property.title}');

    // Update markers to show selection
    _updatePropertyMarkers();

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
    _updatePropertyMarkers();
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

    final propertiesWithLocation = properties
        .where((p) => p.hasLocation)
        .toList();
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

      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    } catch (e) {
      DebugLogger.warning('⚠️ Could not fit bounds: $e');
    }
  }

  // Refresh
  Future<void> refreshProperties() async {
    DebugLogger.info('🔄 Manual refresh requested');
    await _loadPropertiesForCurrentView();
  }

  @override
  Future<void> refresh() async {
    DebugLogger.info('🔄 Manual refresh triggered');
    await _loadPropertiesForCurrentView();
  }

  Future<void> fetchPropertiesForMap() async {
    await refresh();
  }

  Future<void> loadMoreProperties() async {
    if (isLoadingMore.value || !hasNextPage.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    try {
      DebugLogger.api('🔄 Loading more properties (page ${currentPage.value})');

      final currentFilters = _filterService.currentFilter;

      final response = await _propertiesRepository.getProperties(
        latitude: currentCenter.value.latitude,
        longitude: currentCenter.value.longitude,
        filters: currentFilters,
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
        DebugLogger.success('✅ Loaded ${fetchedProperties.length} more properties');
      } else {
        hasNextPage.value = false;
        DebugLogger.info('📭 No more properties to load');
      }
    } catch (e, stackTrace) {
      DebugLogger.error("❌ Failed to load more properties", e, stackTrace);
      currentPage.value--; // Revert page increment
    } finally {
      isLoadingMore.value = false;
      state.value = ExploreState.loaded;
    }
  }

  Future<void> performSearch(String query) async {
    if (query.isEmpty) return;
    await updateSearchQuery(query);
  }

  // Search mode management
  void activateSearchMode() {
    DebugLogger.info('🔍 Activating search mode');
    isSearchActive.value = true;
    searchQuery.value = '';
    searchResults.clear();
  }

  void deactivateSearchMode() {
    DebugLogger.info('🔍 Deactivating search mode');
    isSearchActive.value = false;
    searchQuery.value = '';
    searchResults.clear();
    _locationController.clearPlaceSuggestions();
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
        // Use LocationController to get place details
        final locationController = Get.find<LocationController>();
        final locationData = await locationController.getPlaceDetails(result.placeId);

        if (locationData != null) {
          coordinates = LatLng(locationData.latitude, locationData.longitude);
        }
      }

      if (coordinates != null) {
        // Animate to the selected location
        _animateToLocation(coordinates, 14.0);

        // Update explore filters with new location
        exploreFilters.value = exploreFilters.value.copyWith();

        // Save the location
        _saveExploreLocation(coordinates);
        hasLocation.value = true;

        // Load properties for the new location
        await refresh();

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

    } catch (e, stackTrace) {
      DebugLogger.error('❌ Error selecting location', e, stackTrace);
      Get.snackbar(
        'Error',
        'Failed to select location. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
  }

  // Error handling
  void retryLoading() {
    DebugLogger.info('🔄 Manual retry loading requested');
    _retryTimer?.cancel(); // Cancel any ongoing retry
    _retryCount = 0; // Reset retry count for manual retry
    errorMessage.value = '';
    state.value = ExploreState.initial; // Reset state to allow retry
    _loadPropertiesForCurrentView();
  }

  void clearError() {
    DebugLogger.info('🧹 Clearing error state');
    errorMessage.value = '';
    if (state.value == ExploreState.error) {
      final newState = properties.isEmpty
          ? ExploreState.empty
          : ExploreState.loaded;
      DebugLogger.info('📊 Changing state from error to: $newState');
      state.value = newState;
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
  
  // Helper method to build user-friendly error messages
  String _buildUserFriendlyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection issue. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('location') || errorString.contains('gps')) {
      return 'Location services issue. Please enable location services and try again.';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else if (errorString.contains('permission') || errorString.contains('403')) {
      return 'Permission denied. Please check your account status.';
      } else {
      return 'Something went wrong. Please try again.';
    }
  }

  // Get properties for clustering (if implemented)
  List<PropertyModel> get propertiesWithLocation {
    try {
      final result = properties.where((p) => p.hasLocation && p.latitude != null && p.longitude != null).toList();
      DebugLogger.info('🗺️ propertiesWithLocation: ${result.length}/${properties.length}');
      return result;
    } catch (e) {
      DebugLogger.error('❌ Error in propertiesWithLocation: $e');
      return [];
    }
  }

  // Update property markers for map with performance optimization
  void _updatePropertyMarkers() {
    try {
      final propsWithLocation = propertiesWithLocation;
      DebugLogger.info('🗺️ Generating markers for ${propsWithLocation.length} properties');

      if (propsWithLocation.isEmpty) {
        DebugLogger.info('⚠️ No properties with location found');
        propertyMarkers.clear();
        return;
      }

      // Performance optimization: limit markers based on zoom level
      final zoom = currentZoom.value;
      int maxMarkers;

      if (zoom >= 15) {
        maxMarkers = 200; // Very close zoom - show more markers
      } else if (zoom >= 13) {
        maxMarkers = 100; // Medium zoom - moderate markers
      } else if (zoom >= 11) {
        maxMarkers = 50;  // Far zoom - fewer markers
      } else {
        maxMarkers = 25;  // Very far zoom - minimal markers
      }

      // Take a subset of properties if too many
      final propertiesSubset = propsWithLocation.length > maxMarkers
          ? propsWithLocation.take(maxMarkers).toList()
          : propsWithLocation;

      if (propsWithLocation.length > maxMarkers) {
        DebugLogger.info('🎯 Performance optimization: showing ${propertiesSubset.length}/${propsWithLocation.length} markers at zoom ${zoom.toStringAsFixed(1)}');
      }

      final markers = <PropertyMarker>[];

      for (final property in propertiesSubset) {
        try {
          // Additional null safety checks
          final lat = property.latitude;
          final lng = property.longitude;

          if (lat == null || lng == null) {
            DebugLogger.warning('⚠️ Property ${property.id} has null coordinates: lat=$lat, lng=$lng');
            continue;
          }

          markers.add(PropertyMarker(
            property: property,
            position: LatLng(lat, lng),
            isSelected: selectedProperty.value?.id == property.id,
            isLiked: likedProperties[property.id.toString()] ?? false,
          ));
    } catch (e) {
          DebugLogger.error('❌ Error creating marker for property ${property.id}: $e');
          continue;
        }
      }

      propertyMarkers.assignAll(markers);
      DebugLogger.info('🗺️ Generated ${markers.length} property markers from ${propertiesSubset.length} properties with location');
    } catch (e) {
      DebugLogger.error('❌ Error generating property markers: $e');
      propertyMarkers.clear();
    }
  }

  // Map event handlers
  void onMapZoomChanged(double zoom) {
    DebugLogger.info('🔍 Map zoom changed to: $zoom');
    currentZoom.value = zoom;
    currentRadius.value = _calculateRadiusFromZoom(zoom);
  }

  void onMapMoved(LatLng center) {
    DebugLogger.info('🗺️ Map moved to: ${center.latitude}, ${center.longitude}');
    currentCenter.value = center;
    mapCenter.value = center;

    // Debounce the property loading to avoid too many API calls
    _mapMoveDebouncer?.cancel();
    _mapMoveDebouncer = Timer(const Duration(milliseconds: 800), () {
      DebugLogger.info('🔄 Map move debounce completed, updating location');
      _onMapMoveCompleted();
    });
  }

  void onMapReady() {
    DebugLogger.success('✅ Map initialized successfully');
    isMapReady.value = true;
  }

  // Property selection methods
  void onPropertySelected(PropertyModel property) {
    selectedProperty.value = property;
    DebugLogger.api('🏠 Selected property: ${property.title}');

    // Update markers to show selection
    _updatePropertyMarkers();

    // Center map on selected property if it has location
    if (property.hasLocation) {
      _updateMapCenter(
        LatLng(property.latitude!, property.longitude!),
        16.0, // Zoom in closer for selected property
      );
    }
  }

  void onPropertySelectedFromList(PropertyModel property, int index) {
    selectedProperty.value = property;
    selectedPropertyIndex.value = index;

    // Update markers to show selection
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

  Future<void> toggleLikeProperty(PropertyModel property) async {
    try {
      final propertyId = property.id.toString();
      final currentLiked = likedProperties[propertyId] ?? false;

      // Optimistic update using our tracking map
      likedProperties[propertyId] = !currentLiked;
      properties.refresh();

      // API call (if API service available)
      // final success = true; // Mock success for now
      // if (!success) {
      //   // Revert optimistic update on failure
      //   likedProperties[propertyId] = currentLiked;
      //   properties.refresh();
      // }
    } catch (e) {
      DebugLogger.error('Error toggling like: $e');
      // Revert optimistic update on error
      final propertyId = property.id.toString();
      final currentLiked = likedProperties[propertyId] ?? false;
      likedProperties[propertyId] = currentLiked;
      properties.refresh();
    }
  }

  // Helper getters
  bool get isLoading => state.value == ExploreState.loading;
  bool get isEmpty => state.value == ExploreState.empty;
  bool get hasError => state.value == ExploreState.error;
  bool get isLoaded => state.value == ExploreState.loaded;
  bool get hasProperties => properties.isNotEmpty;
  bool get hasSelection => selectedProperty.value != null;

}

// Helper class for property markers
class PropertyMarker {
  final PropertyModel property;
  final LatLng position;
  final bool isSelected;
  final bool isLiked;

  PropertyMarker({
    required this.property,
    required this.position,
    required this.isSelected,
    this.isLiked = false,
  });
}


