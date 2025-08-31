import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/models/page_state_model.dart';
import '../data/models/property_model.dart';
import '../data/models/unified_filter_model.dart';
import '../data/repositories/properties_repository.dart';
import '../data/repositories/swipes_repository.dart';
import '../utils/app_exceptions.dart';
import '../utils/debug_logger.dart';
import 'auth_controller.dart';
import 'location_controller.dart';

class PageStateService extends GetxController {
  static PageStateService get instance => Get.find<PageStateService>();

  // Storage instance
  final _storage = GetStorage();
  final _propertiesRepository = Get.find<PropertiesRepository>();
  final _swipesRepository = Get.find<SwipesRepository>();
  final _locationController = Get.find<LocationController>();
  final _authController = Get.find<AuthController>();

  // Page states
  final Rx<PageStateModel> exploreState = PageStateModel.initial(PageType.explore).obs;
  final Rx<PageStateModel> discoverState = PageStateModel.initial(PageType.discover).obs;
  final Rx<PageStateModel> likesState = PageStateModel.initial(PageType.likes).obs;

  // Current active page
  final Rx<PageType> currentPageType = PageType.discover.obs;

  // Top bar refresh indicators (per page)
  final RxBool _exploreRefreshing = false.obs;
  final RxBool _discoverRefreshing = false.obs;
  final RxBool _likesRefreshing = false.obs;

  // Debounce timers
  Timer? _exploreDebouncer;
  Timer? _discoverDebouncer;
  Timer? _likesDebouncer;

  @override
  void onInit() {
    super.onInit();
    _loadSavedStates();
    _bootstrapInitialStates(); // <-- Add this call
    _setupListeners();
  }

  @override
  void onClose() {
    _exploreDebouncer?.cancel();
    _discoverDebouncer?.cancel();
    _likesDebouncer?.cancel();
    super.onClose();
  }

  void _loadSavedStates() {
    try {
      // Load saved states from local storage
      final savedExploreState = _storage.read('explore_state');
      if (savedExploreState != null) {
        exploreState.value = PageStateModel.fromJson(savedExploreState);
      }

      final savedDiscoverState = _storage.read('discover_state');
      if (savedDiscoverState != null) {
        discoverState.value = PageStateModel.fromJson(savedDiscoverState);
      }

      final savedLikesState = _storage.read('likes_state');
      if (savedLikesState != null) {
        likesState.value = PageStateModel.fromJson(savedLikesState);
      }

      DebugLogger.success('📂 Loaded saved page states');
    } catch (e) {
      DebugLogger.error('Error loading saved page states: $e');
    }
  }

  // Detects placeholder or non-human-friendly location names that should be reverse geocoded
  bool _isPlaceholderLocationName(String? name) {
    if (name == null) return true;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return true;
    final lower = trimmed.toLowerCase();
    return lower.startsWith('location (') ||
        lower == 'location coordinates' ||
        lower == 'current location' ||
        lower == 'current area' ||
        lower == 'selected area';
  }

  // Ensure loaded states have a proper human-friendly location name
  Future<void> _normalizeSavedLocations() async {
    try {
      Future<void> fixFor(PageType page) async {
        final state = _getStateForPage(page);
        final loc = state.selectedLocation;
        if (loc != null && _isPlaceholderLocationName(loc.name)) {
          final resolved = await _locationController.getAddressFromCoordinates(
            loc.latitude,
            loc.longitude,
          );
          final updated = state.copyWith(
            selectedLocation: LocationData(
              name: resolved,
              latitude: loc.latitude,
              longitude: loc.longitude,
            ),
            locationSource: state.locationSource ?? 'hydrate',
          );
          _updatePageState(page, updated);
        }
      }

      await Future.wait([
        fixFor(PageType.explore),
        fixFor(PageType.discover),
        fixFor(PageType.likes),
      ]);

      DebugLogger.success('🔤 Normalized saved location names where needed');
    } catch (e, st) {
      DebugLogger.warning('Failed to normalize saved locations: $e');
      DebugLogger.warning(st.toString());
    }
  }

  /// Sets the initial location for all page states if they don't have one.
  Future<void> _bootstrapInitialStates() async {
    DebugLogger.info('🚀 Bootstrapping initial page states...');

    // Check if any page is missing a location. If all have one, we are done.
    if (exploreState.value.hasLocation &&
        discoverState.value.hasLocation &&
        likesState.value.hasLocation) {
      DebugLogger.success('✅ All page states already have a location. Bootstrap complete.');
      // Still normalize saved names if placeholders slipped in
      await _normalizeSavedLocations();
      return;
    }

    try {
      final initialLocation = await _locationController.getInitialLocation();

      // Update each page state if it doesn't have a location
      if (!exploreState.value.hasLocation) {
        await updateLocationForPage(PageType.explore, initialLocation, source: 'initial');
      }
      if (!discoverState.value.hasLocation) {
        await updateLocationForPage(PageType.discover, initialLocation, source: 'initial');
      }
      if (!likesState.value.hasLocation) {
        await updateLocationForPage(PageType.likes, initialLocation, source: 'initial');
      }
      // After bootstrapping, ensure names are user-friendly
      await _normalizeSavedLocations();
      DebugLogger.success('✅ Successfully bootstrapped initial location for all pages.');
    } catch (e, st) {
      DebugLogger.error('❌ Failed to bootstrap initial location', e, st);
      // You can show a global error snackbar here if needed
      Get.snackbar(
        'Location Error',
        'Could not determine your initial location. Please check your settings and try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _setupListeners() {
    // Save states whenever they change
    ever(exploreState, (state) {
      _storage.write('explore_state', state.toJson());
    });

    ever(discoverState, (state) {
      _storage.write('discover_state', state.toJson());
    });

    ever(likesState, (state) {
      _storage.write('likes_state', state.toJson());
    });

    // Listen to location updates; update only current page to keep independence
    _locationController.currentPosition.listen((position) async {
      if (position != null) {
        // Get real address from coordinates
        final locationName = await _locationController.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final loc = LocationData(
          name: locationName,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        await updateLocationForPage(currentPageType.value, loc, source: 'gps');
      }
    });
  }

  // Update location only for a specific page
  Future<void> updateLocationForPage(
    PageType pageType,
    LocationData location, {
    String source = 'manual',
  }) async {
    DebugLogger.info(
      '📍 Updating location for ${pageType.name}: ${location.name} (${location.latitude}, ${location.longitude}) from $source',
    );

    // Resolve human-friendly name if placeholder
    LocationData finalLocation = location;
    if (_isPlaceholderLocationName(location.name)) {
      try {
        final resolvedName = await _locationController.getAddressFromCoordinates(
          location.latitude,
          location.longitude,
        );
        finalLocation = LocationData(
          name: resolvedName,
          latitude: location.latitude,
          longitude: location.longitude,
        );
        DebugLogger.info('🧭 Resolved location name to "$resolvedName"');
      } catch (e, st) {
        DebugLogger.warning('Reverse geocoding failed, keeping provided name. $e');
        DebugLogger.warning(st.toString());
      }
    }

    final current = _getStateForPage(pageType);
    // Only update the selectedLocation. The filters object no longer holds lat/lng.
    final updated = current.copyWith(selectedLocation: finalLocation, locationSource: source);
    _updatePageState(pageType, updated);

    // Only trigger a data refresh if the source is not 'initial' or 'hydrate'
    if (source != 'initial' && source != 'hydrate') {
      DebugLogger.info('🔄 Debouncing refresh for ${pageType.name} after location update');
      _debounceRefresh(pageType);
    } else {
      DebugLogger.info('⏭️ Skipping refresh for initial/hydrate location update.');
    }
  }

  // Get current page state
  PageStateModel getCurrentPageState() {
    switch (currentPageType.value) {
      case PageType.explore:
        return exploreState.value;
      case PageType.discover:
        return discoverState.value;
      case PageType.likes:
        return likesState.value;
    }
  }

  void setCurrentPage(PageType pageType) {
    if (currentPageType.value == pageType) return;

    final oldPageType = currentPageType.value;
    currentPageType.value = pageType;
    DebugLogger.info('📱 Switched from ${oldPageType.name} to ${pageType.name} page');

    // Feature controllers' ever() workers handle their own activation logic.
  }

  // Location management
  Future<void> updateLocation(LocationData location, {String source = 'manual'}) async {
    try {
      // Update backend if authenticated
      if (_authController.isAuthenticated) {
        await _authController.updateUserLocation({
          'current_latitude': location.latitude,
          'current_longitude': location.longitude,
        });
      }
      // Update only current page to keep independent state per page
      await updateLocationForPage(currentPageType.value, location, source: source);

      DebugLogger.success('✅ Location updated: ${location.name}');

      // Trigger data refresh just for current page
      _debounceRefresh(currentPageType.value);
    } catch (e) {
      DebugLogger.error('Failed to update location: $e');
    }
  }

  Future<void> useCurrentLocation() async {
    try {
      await _locationController.getCurrentLocation();
      final position = _locationController.currentPosition.value;
      if (position != null) {
        // Get real address from coordinates
        final locationName = await _locationController.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final location = LocationData(
          name: locationName,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        await updateLocation(location, source: 'gps');
      }
    } catch (e) {
      DebugLogger.error('Failed to get current location: $e');
      Get.snackbar(
        'Location Error',
        'Unable to get your current location',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Page-specific current location (with IP fallback)
  Future<void> useCurrentLocationForPage(PageType pageType) async {
    try {
      await _locationController.getCurrentLocation();
      final position = _locationController.currentPosition.value;
      if (position != null) {
        // Get real address from coordinates
        final locationName = await _locationController.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final loc = LocationData(
          name: locationName,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        await updateLocationForPage(pageType, loc, source: 'gps');
        return;
      }

      // Fallback to IP-based location
      final ipLoc = await _locationController.getIpLocation();
      if (ipLoc != null) {
        await updateLocationForPage(pageType, ipLoc, source: 'ip');
        return;
      }
    } catch (e) {
      DebugLogger.warning('IP fallback failed for ${pageType.name}: $e');
    }
  }

  // Filter management for specific pages
  void updatePageFilters(PageType pageType, UnifiedFilterModel filters) {
    switch (pageType) {
      case PageType.explore:
        exploreState.value = exploreState.value.copyWith(filters: filters);
        _debounceRefresh(pageType);
        break;
      case PageType.discover:
        discoverState.value = discoverState.value.copyWith(filters: filters);
        _debounceRefresh(pageType);
        break;
      case PageType.likes:
        likesState.value = likesState.value.copyWith(filters: filters);
        _debounceRefresh(pageType);
        break;
    }
    DebugLogger.info('🔍 Updated ${pageType.name} filters');
  }

  // Search management (only for explore and likes)
  void updatePageSearch(PageType pageType, String query) {
    if (pageType == PageType.discover) return; // Discover doesn't have search

    switch (pageType) {
      case PageType.explore:
        exploreState.value = exploreState.value.copyWith(searchQuery: query);
        _debounceRefresh(pageType);
        break;
      case PageType.likes:
        likesState.value = likesState.value.copyWith(searchQuery: query);
        _debounceRefresh(pageType);
        break;
      default:
        break;
    }
    DebugLogger.info('🔍 Updated ${pageType.name} search: "$query"');
  }

  void clearPageSearch(PageType pageType) {
    updatePageSearch(pageType, '');
  }

  // Data loading
  Future<void> loadPageData(
    PageType pageType, {
    bool forceRefresh = false,
    bool backgroundRefresh = false,
  }) async {
    try {
      final state = _getStateForPage(pageType);
      if (state.isLoading) return;

      if (!forceRefresh &&
          !backgroundRefresh &&
          !state.isDataStale &&
          state.properties.isNotEmpty) {
        return;
      }

      if (!backgroundRefresh) {
        _updatePageState(pageType, state.copyWith(isLoading: true, error: null));
      } else {
        notifyPageRefreshing(pageType, true);
        _updatePageState(pageType, state.copyWith(isRefreshing: true, error: null));
      }

      // --- ROBUST LOCATION HANDLING ---
      LocationData? locationToUse = state.selectedLocation;
      if (locationToUse == null) {
        DebugLogger.warning('⚠️ No location set for ${pageType.name}. Bootstrapping location...');
        try {
          locationToUse = await _locationController.getInitialLocation();
        } catch (e) {
          final friendlyError = 'Location not available. Please enable location or choose a place.';
          _updatePageState(
            pageType,
            state.copyWith(
              isLoading: false,
              isRefreshing: false,
              error: AppError(error: friendlyError, stackTrace: StackTrace.current),
            ),
          );
          DebugLogger.error('❌ Failed to load ${pageType.name}: $friendlyError', e);
          notifyPageRefreshing(pageType, false);
          return;
        }
      }
      // --- END ROBUST LOCATION HANDLING ---

      if (pageType == PageType.likes) {
        final isLikedSegment =
            (state.getAdditionalData<String>('currentSegment') ?? 'liked') == 'liked';

        DebugLogger.api(
          '📊 [PAGE_STATE_SERVICE] About to call getSwipeHistoryProperties for likes',
        );
        DebugLogger.api('📊 [PAGE_STATE_SERVICE] isLikedSegment: $isLikedSegment');
        DebugLogger.api(
          '📊 [PAGE_STATE_SERVICE] Location: (${locationToUse.latitude}, ${locationToUse.longitude})',
        );
        DebugLogger.api('📊 [PAGE_STATE_SERVICE] Filters: ${state.filters.toJson()}');

        final response = await _swipesRepository.getSwipeHistoryProperties(
          filters: state.filters.copyWith(searchQuery: state.searchQuery),
          latitude: locationToUse.latitude,
          longitude: locationToUse.longitude,
          page: 1,
          limit: 50,
          isLiked: isLikedSegment,
        );
        DebugLogger.api('📊 [PAGE_STATE_SERVICE] getSwipeHistoryProperties completed successfully');

        _updatePageState(
          pageType,
          state.copyWith(
            properties: response.properties,
            selectedLocation: locationToUse, // Persist the location used
            currentPage: 1,
            totalPages: response.totalPages,
            hasMore: response.hasMore,
            isLoading: false,
            isRefreshing: false,
            lastFetched: DateTime.now(),
            error: null, // clear any previous error on success
          ),
        );
      } else {
        final response = await _propertiesRepository.getProperties(
          filters: state.filters.copyWith(searchQuery: state.searchQuery),
          page: 1,
          limit: pageType == PageType.discover ? 20 : 50,
          latitude: locationToUse.latitude,
          longitude: locationToUse.longitude,
          radiusKm: state.filters.radiusKm ?? 10.0,
          excludeSwiped: pageType == PageType.discover,
        );

        _updatePageState(
          pageType,
          state.copyWith(
            properties: response.properties,
            selectedLocation: locationToUse, // Persist the location used
            currentPage: 1,
            totalPages: response.totalPages,
            hasMore: response.hasMore,
            isLoading: false,
            isRefreshing: false,
            lastFetched: DateTime.now(),
            error: null, // clear any previous error on success
          ),
        );
      }

      final updatedCount = _getStateForPage(pageType).properties.length;
      DebugLogger.success('✅ Loaded $updatedCount properties for ${pageType.name}');
    } catch (e, stackTrace) {
      // Now we log with the full context
      DebugLogger.error('❌ Failed to load ${pageType.name} data', e, stackTrace);

      if (e.toString().contains('Null check operator used on a null value')) {
        DebugLogger.error(
          '🚨 [PAGE_STATE_SERVICE] NULL CHECK OPERATOR ERROR during ${pageType.name} data load!',
        );
        if (pageType == PageType.likes) {
          DebugLogger.error(
            '🚨 [PAGE_STATE_SERVICE] This error occurred in SwipesRepository.getSwipeHistoryProperties()',
          );
          DebugLogger.error(
            '🚨 [PAGE_STATE_SERVICE] Check the detailed API parsing logs above for the root cause',
          );
        }
      }

      final state = _getStateForPage(pageType);
      _updatePageState(
        pageType,
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: AppError(error: e, stackTrace: stackTrace),
        ),
      );
    } finally {
      notifyPageRefreshing(pageType, false);
    }
  }

  Future<void> loadMorePageData(PageType pageType) async {
    try {
      final state = _getStateForPage(pageType);
      if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

      _updatePageState(pageType, state.copyWith(isLoadingMore: true));

      final loc = state.selectedLocation;
      if (loc == null) {
        DebugLogger.warning(
          '⚠️ No location set for ${pageType.name} while loading more. Skipping.',
        );
        _updatePageState(pageType, state.copyWith(isLoadingMore: false));
        return;
      }

      if (pageType == PageType.likes) {
        final isLikedSegment =
            (state.getAdditionalData<String>('currentSegment') ?? 'liked') == 'liked';
        final response = await _swipesRepository.getSwipeHistoryProperties(
          filters: state.filters.copyWith(searchQuery: state.searchQuery),
          latitude: loc.latitude,
          longitude: loc.longitude,
          page: state.currentPage + 1,
          limit: 50,
          isLiked: isLikedSegment,
        );

        final newProperties = [...state.properties, ...response.properties];
        _updatePageState(
          pageType,
          state.copyWith(
            properties: newProperties,
            currentPage: state.currentPage + 1,
            totalPages: response.totalPages,
            hasMore: response.hasMore,
            isLoadingMore: false,
          ),
        );
      } else {
        final response = await _propertiesRepository.getProperties(
          filters: state.filters.copyWith(searchQuery: state.searchQuery),
          page: state.currentPage + 1,
          limit: pageType == PageType.discover ? 20 : 50,
          latitude: loc.latitude,
          longitude: loc.longitude,
          radiusKm: state.filters.radiusKm ?? 10.0,
          excludeSwiped: pageType == PageType.discover,
        );

        final newProperties = [...state.properties, ...response.properties];
        _updatePageState(
          pageType,
          state.copyWith(
            properties: newProperties,
            currentPage: state.currentPage + 1,
            totalPages: response.totalPages,
            hasMore: response.hasMore,
            isLoadingMore: false,
          ),
        );
      }

      final totalCount = _getStateForPage(pageType).properties.length;
      DebugLogger.success('✅ Loaded more properties for ${pageType.name} (total: $totalCount)');
    } catch (e) {
      DebugLogger.error('❌ Failed to load more ${pageType.name} data: $e');
      final state = _getStateForPage(pageType);
      _updatePageState(pageType, state.copyWith(isLoadingMore: false));
    }
  }

  // Reset methods
  void resetPageFilters(PageType pageType) {
    switch (pageType) {
      case PageType.explore:
        exploreState.value = exploreState.value.resetFilters();
        break;
      case PageType.discover:
        discoverState.value = discoverState.value.resetFilters();
        break;
      case PageType.likes:
        likesState.value = likesState.value.resetFilters();
        break;
    }
    loadPageData(pageType, forceRefresh: true);
    DebugLogger.info('🔄 Reset ${pageType.name} filters');
  }

  void resetAllFilters() {
    exploreState.value = exploreState.value.resetFilters();
    discoverState.value = discoverState.value.resetFilters();
    likesState.value = likesState.value.resetFilters();
    _refreshAllPagesData();
    DebugLogger.info('🔄 Reset all page filters');
  }

  // Set default purpose across all pages; optionally only if unset
  void setPurposeForAllPages(String purpose, {bool onlyIfUnset = false}) {
    void setFor(PageType page) {
      final state = _getStateForPage(page);
      if (onlyIfUnset && state.filters.purpose != null) return;
      final updatedFilters = state.filters.copyWith(purpose: purpose);
      _updatePageState(page, state.copyWith(filters: updatedFilters).resetData());
    }

    setFor(PageType.explore);
    setFor(PageType.discover);
    setFor(PageType.likes);
    DebugLogger.info('🎯 Set default purpose="$purpose" for all pages (onlyIfUnset=$onlyIfUnset)');
  }

  // Helper methods
  PageStateModel _getStateForPage(PageType pageType) {
    switch (pageType) {
      case PageType.explore:
        return exploreState.value;
      case PageType.discover:
        return discoverState.value;
      case PageType.likes:
        return likesState.value;
    }
  }

  void _updatePageState(PageType pageType, PageStateModel newState) {
    switch (pageType) {
      case PageType.explore:
        exploreState.value = newState;
        break;
      case PageType.discover:
        discoverState.value = newState;
        break;
      case PageType.likes:
        likesState.value = newState;
        break;
    }
  }

  void _debounceRefresh(PageType pageType) {
    switch (pageType) {
      case PageType.explore:
        _exploreDebouncer?.cancel();
        _exploreDebouncer = Timer(const Duration(milliseconds: 500), () {
          loadPageData(PageType.explore, forceRefresh: true);
        });
        break;
      case PageType.discover:
        _discoverDebouncer?.cancel();
        _discoverDebouncer = Timer(const Duration(milliseconds: 500), () {
          loadPageData(PageType.discover, forceRefresh: true);
        });
        break;
      case PageType.likes:
        _likesDebouncer?.cancel();
        _likesDebouncer = Timer(const Duration(milliseconds: 500), () {
          loadPageData(PageType.likes, forceRefresh: true);
        });
        break;
    }
  }

  void _refreshAllPagesData() {
    loadPageData(PageType.explore, forceRefresh: true);
    loadPageData(PageType.discover, forceRefresh: true);
    loadPageData(PageType.likes, forceRefresh: true);
  }

  // Additional utility methods for specific pages
  void updateLikesSegment(String segment) {
    // Store current segment in additional data and reset the list for fresh load
    likesState.value = likesState.value.updateAdditionalData('currentSegment', segment).resetData();
    // Immediately load new segment data
    loadPageData(PageType.likes, forceRefresh: true);
  }

  String get currentLikesSegment =>
      likesState.value.getAdditionalData<String>('currentSegment') ?? 'liked';

  // Mutations for likes page (optimistic UI updates)
  void removePropertyFromLikes(int propertyId) {
    final state = likesState.value;
    final updatedList = state.properties.where((p) => p.id != propertyId).toList();
    _updatePageState(PageType.likes, state.copyWith(properties: updatedList));
  }

  // Optimistically add a property to the current Likes segment list (Liked tab)
  void addPropertyToLikes(PropertyModel property) {
    // Only mutate the list when current segment is 'liked'
    if (currentLikesSegment != 'liked') return;
    final state = likesState.value;
    final exists = state.properties.any((p) => p.id == property.id);
    if (!exists) {
      final updatedList = [property, ...state.properties];
      _updatePageState(PageType.likes, state.copyWith(properties: updatedList));
    }
  }

  // Optimistically add a property to the current Likes segment list (Passed tab)
  void addPropertyToPassed(PropertyModel property) {
    // Only mutate the list when current segment is 'passed'
    if (currentLikesSegment != 'passed') return;
    final state = likesState.value;
    final exists = state.properties.any((p) => p.id == property.id);
    if (!exists) {
      final updatedList = [property, ...state.properties];
      _updatePageState(PageType.likes, state.copyWith(properties: updatedList));
    }
  }

  // Optimistically remove a property from Discover list
  void removePropertyFromDiscover(int propertyId) {
    final state = discoverState.value;
    final updatedList = state.properties.where((p) => p.id != propertyId).toList();
    _updatePageState(PageType.discover, state.copyWith(properties: updatedList));
  }

  // Sync preferences to backend
  Future<void> syncPreferencesToBackend() async {
    try {
      if (!_authController.isAuthenticated) return;

      final preferences = {
        'explore_filters': exploreState.value.filters.toJson(),
        'discover_filters': discoverState.value.filters.toJson(),
        'likes_filters': likesState.value.filters.toJson(),
        'location': getCurrentPageState().selectedLocation?.toJson(),
      };

      await _authController.updateUserPreferences(preferences);
      DebugLogger.success('✅ Synced preferences to backend');
    } catch (e) {
      DebugLogger.error('Failed to sync preferences: $e');
    }
  }

  // UI helpers: search visibility per-page
  bool isSearchVisible(PageType pageType) {
    final state = _getStateForPage(pageType);
    return state.getAdditionalData<bool>('searchVisible') ?? false;
  }

  void setSearchVisible(PageType pageType, bool visible) {
    final state = _getStateForPage(pageType);
    final updated = state.updateAdditionalData('searchVisible', visible);
    _updatePageState(pageType, updated);
  }

  void toggleSearch(PageType pageType) {
    setSearchVisible(pageType, !isSearchVisible(pageType));
  }

  // UI helpers: top bar refresh spinner per page
  void notifyPageRefreshing(PageType pageType, bool isRefreshing) {
    switch (pageType) {
      case PageType.explore:
        _exploreRefreshing.value = isRefreshing;
        break;
      case PageType.discover:
        _discoverRefreshing.value = isRefreshing;
        break;
      case PageType.likes:
        _likesRefreshing.value = isRefreshing;
        break;
    }
  }

  bool isPageRefreshing(PageType pageType) {
    switch (pageType) {
      case PageType.explore:
        return _exploreRefreshing.value;
      case PageType.discover:
        return _discoverRefreshing.value;
      case PageType.likes:
        return _likesRefreshing.value;
    }
  }
}
