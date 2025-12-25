import 'dart:async';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/controllers/location_controller.dart';
import 'package:ghar360/core/data/models/page_state_model.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/data/providers/api_service.dart';
import 'package:ghar360/core/data/repositories/swipes_repository.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_mapper.dart';

class PageStateService extends GetxController {
  static PageStateService get instance => Get.find<PageStateService>();

  // Storage instance
  final _storage = GetStorage();
  final _swipesRepository = Get.find<SwipesRepository>();
  final _apiService = Get.find<ApiService>();
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

  // Search controllers (persistent per page type)
  final _controllers = <PageType, TextEditingController>{};

  // Debounce timers
  Timer? _exploreDebouncer;
  Timer? _discoverDebouncer;
  Timer? _likesDebouncer;

  // Persistence debounce timers (500ms to batch rapid state updates)
  Timer? _explorePersistDebouncer;
  Timer? _discoverPersistDebouncer;
  Timer? _likesPersistDebouncer;
  static const _persistDebounceMs = 500;

  // Stream subscriptions (to prevent memory leaks)
  StreamSubscription? _locationSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadSavedStates();
    // Apply globally saved purpose/type if present, then ensure sane defaults
    _applySavedGlobalFilters();
    // Ensure default purpose is set to 'buy' when unset for new users
    setPurposeForAllPages('buy', onlyIfUnset: true);
    _bootstrapInitialStates(); // <-- Add this call
    _setupListeners();
  }

  @override
  void onClose() {
    _exploreDebouncer?.cancel();
    _discoverDebouncer?.cancel();
    _likesDebouncer?.cancel();
    // Cancel persistence debouncers
    _explorePersistDebouncer?.cancel();
    _discoverPersistDebouncer?.cancel();
    _likesPersistDebouncer?.cancel();
    // Cancel location subscription to prevent memory leaks
    _locationSubscription?.cancel();
    // Dispose search controllers to prevent memory leaks
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.onClose();
  }

  void _loadSavedStates() {
    try {
      // Load saved states from local storage
      final savedExploreState = _storage.read('explore_state');
      if (savedExploreState != null) {
        // Migration: handle both old full-state format and new snapshot format
        exploreState.value = _loadStateFromStorage(savedExploreState, PageType.explore);
      }

      final savedDiscoverState = _storage.read('discover_state');
      if (savedDiscoverState != null) {
        discoverState.value = _loadStateFromStorage(savedDiscoverState, PageType.discover);
      }

      final savedLikesState = _storage.read('likes_state');
      if (savedLikesState != null) {
        likesState.value = _loadStateFromStorage(savedLikesState, PageType.likes);
      }

      DebugLogger.success('📂 Loaded saved page states');
    } catch (e) {
      DebugLogger.error('Error loading saved page states: $e');
    }
  }

  /// Loads a PageStateModel from storage, handling migration from old full-state format.
  PageStateModel _loadStateFromStorage(Map<String, dynamic> json, PageType fallbackType) {
    try {
      // Check if this is the new snapshot format (has 'pageType' as string, no 'properties')
      if (json.containsKey('pageType') &&
          json['pageType'] is String &&
          !json.containsKey('properties')) {
        // New lightweight snapshot format
        final snapshot = PageStateSnapshot.fromJson(json);
        return PageStateModel.fromSnapshot(snapshot);
      }
      // Old format: parse as full PageStateModel but discard properties (they're stale anyway)
      final fullModel = PageStateModel.fromJson(json);
      return fullModel.copyWith(properties: []); // Clear stale properties
    } catch (e) {
      DebugLogger.warning('Failed to parse saved state, using initial: $e');
      return PageStateModel.initial(fallbackType);
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
    // Save lightweight snapshots (NOT full properties list) with debouncing
    ever(exploreState, (state) {
      _debouncedPersist(PageType.explore, state);
    });

    ever(discoverState, (state) {
      _debouncedPersist(PageType.discover, state);
    });

    ever(likesState, (state) {
      _debouncedPersist(PageType.likes, state);
    });

    // Listen to location updates; update only current page to keep independence
    _locationSubscription?.cancel();
    _locationSubscription = _locationController.currentPosition.listen((position) async {
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

  /// Debounced persistence to avoid excessive disk writes on rapid state changes.
  void _debouncedPersist(PageType pageType, PageStateModel state) {
    switch (pageType) {
      case PageType.explore:
        _explorePersistDebouncer?.cancel();
        _explorePersistDebouncer = Timer(
          const Duration(milliseconds: _persistDebounceMs),
          () => _storage.write('explore_state', state.toSnapshot().toJson()),
        );
        break;
      case PageType.discover:
        _discoverPersistDebouncer?.cancel();
        _discoverPersistDebouncer = Timer(
          const Duration(milliseconds: _persistDebounceMs),
          () => _storage.write('discover_state', state.toSnapshot().toJson()),
        );
        break;
      case PageType.likes:
        _likesPersistDebouncer?.cancel();
        _likesPersistDebouncer = Timer(
          const Duration(milliseconds: _persistDebounceMs),
          () => _storage.write('likes_state', state.toSnapshot().toJson()),
        );
        break;
    }
  }

  // Load globally stored purpose/property_type and apply across pages
  void _applySavedGlobalFilters() {
    try {
      final String? globalPurpose = _storage.read('global_purpose');
      if (globalPurpose != null && globalPurpose.trim().isNotEmpty) {
        setPurposeForAllPages(globalPurpose.trim());
        DebugLogger.success('🎯 Applied saved global purpose: $globalPurpose');
      }

      final List<dynamic>? storedTypes = _storage.read('global_property_types');
      if (storedTypes != null) {
        final types = storedTypes.whereType<String>().toList();
        setPropertyTypeForAllPages(types);
        DebugLogger.success('🏷️ Applied saved global property types: ${types.join(', ')}');
      }
    } catch (e) {
      DebugLogger.warning('Failed to apply saved global filters: $e');
    }
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

      // Trigger data refresh just for current page (only for non-initial sources)
      if (source != 'initial' && source != 'hydrate') {
        _debounceRefresh(currentPageType.value);
      }
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
    final previous = _getStateForPage(pageType).filters;
    final purposeChanged = (filters.purpose ?? '') != (previous.purpose ?? '');
    final List<String> prevTypes = previous.propertyType ?? const [];
    final List<String> nextTypes = filters.propertyType ?? const [];
    final typeChanged = prevTypes.join(',') != nextTypes.join(',');

    switch (pageType) {
      case PageType.explore:
        exploreState.value = exploreState.value.copyWith(filters: filters);
        if (!(purposeChanged || typeChanged)) _debounceRefresh(pageType);
        break;
      case PageType.discover:
        discoverState.value = discoverState.value.copyWith(filters: filters);
        if (!(purposeChanged || typeChanged)) _debounceRefresh(pageType);
        break;
      case PageType.likes:
        likesState.value = likesState.value.copyWith(filters: filters);
        if (!(purposeChanged || typeChanged)) _debounceRefresh(pageType);
        break;
    }
    DebugLogger.info('🔍 Updated ${pageType.name} filters');

    // Persist and propagate global fields when they change
    if (purposeChanged) {
      final newPurpose = filters.purpose?.trim();
      if (newPurpose != null && newPurpose.isNotEmpty) {
        _storage.write('global_purpose', newPurpose);
        setPurposeForAllPages(newPurpose);
        DebugLogger.info('🌐 Propagated purpose="$newPurpose" to all pages');
      }
    }

    if (typeChanged) {
      _storage.write('global_property_types', nextTypes);
      setPropertyTypeForAllPages(nextTypes);
      DebugLogger.info('🌐 Propagated property_type=${nextTypes.join(', ')} to all pages');
    }

    if (purposeChanged || typeChanged) {
      _refreshAllPagesData();
    }
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

  // Search controller management (prevents leaks and cursor jumps)
  TextEditingController getOrCreateSearchController(PageType pageType, {String? seedText}) {
    return _controllers.putIfAbsent(pageType, () {
      final controller = TextEditingController(text: seedText ?? '');
      controller.addListener(() => updatePageSearch(pageType, controller.text));
      return controller;
    });
  }

  // Data loading
  Future<void> loadPageData(
    PageType pageType, {
    bool forceRefresh = false,
    bool backgroundRefresh = false,
  }) async {
    try {
      final state = _getStateForPage(pageType);
      if (state.isLoading || state.isRefreshing) return;

      final hasCached = state.properties.isNotEmpty;
      final isStale = state.isDataStale;

      // If there's no cached data at all, do a foreground load
      if (!hasCached) {
        _updatePageState(pageType, state.copyWith(isLoading: true, error: null));
        await _fetchAndUpdatePage(pageType, page: 1);
      } else {
        // We have cached data: return immediately and revalidate in background when asked or stale
        if (forceRefresh || backgroundRefresh || isStale) {
          notifyPageRefreshing(pageType, true);
          _updatePageState(pageType, state.copyWith(isRefreshing: true, error: null));
          // Use ETag only for time-based/background revalidation; skip for explicit forceRefresh to avoid mismatched keys
          final useEtag = !forceRefresh;
          unawaited(
            _fetchAndUpdatePage(pageType, page: 1, useEtag: useEtag).whenComplete(() {
              notifyPageRefreshing(pageType, false);
            }),
          );
        } else {
          // Fresh enough; nothing to do
          return;
        }
      }

      final updatedCount = _getStateForPage(pageType).properties.length;
      DebugLogger.success('✅ Loaded $updatedCount properties for ${pageType.name}');
    } catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to load ${pageType.name} data', e, stackTrace);
      final state = _getStateForPage(pageType);
      _updatePageState(
        pageType,
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          error: ErrorMapper.mapApiError(e, stackTrace),
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
        final response = await _apiService.getSwipesWithCacheValidation(
          lat: loc.latitude,
          lng: loc.longitude,
          radius: state.filters.radiusKm?.toInt(),
          q: state.searchQuery,
          propertyType: state.filters.propertyType,
          purpose: state.filters.purpose,
          priceMin: state.filters.priceMin,
          priceMax: state.filters.priceMax,
          bedroomsMin: state.filters.bedroomsMin,
          bedroomsMax: state.filters.bedroomsMax,
          bathroomsMin: state.filters.bathroomsMin,
          bathroomsMax: state.filters.bathroomsMax,
          areaMin: state.filters.areaMin,
          areaMax: state.filters.areaMax,
          amenities: state.filters.amenities,
          parkingSpacesMin: state.filters.parkingSpacesMin,
          floorNumberMin: state.filters.floorNumberMin,
          floorNumberMax: state.filters.floorNumberMax,
          ageMax: state.filters.ageMax,
          checkIn: state.filters.checkInDate?.toIso8601String().split('T').first,
          checkOut: state.filters.checkOutDate?.toIso8601String().split('T').first,
          guests: state.filters.guests,
          isLiked: isLikedSegment,
          sortBy: state.filters.sortBy?.toString().split('.').last,
          page: state.currentPage + 1,
          limit: 50,
        );

        final raw = response.data ?? {};
        final List<PropertyModel> pageProps = (raw['properties'] as List<dynamic>? ?? [])
            .map((e) => PropertyModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final totalPages = raw['total_pages'] ?? state.totalPages;
        final hasMore = raw['has_next'] ?? (state.currentPage + 1 < totalPages);

        final newProperties = [...state.properties, ...pageProps];
        _updatePageState(
          pageType,
          state.copyWith(
            properties: newProperties,
            currentPage: state.currentPage + 1,
            totalPages: totalPages,
            hasMore: hasMore,
            isLoadingMore: false,
          ),
        );
      } else {
        final response = await _apiService.searchPropertiesWithCacheValidation(
          filters: state.filters.copyWith(searchQuery: state.searchQuery),
          latitude: loc.latitude,
          longitude: loc.longitude,
          radiusKm: (state.filters.radiusKm ?? 10.0).clamp(5.0, 50.0),
          page: state.currentPage + 1,
          limit: pageType == PageType.discover ? 20 : 50,
          excludeSwiped: pageType == PageType.discover,
          useCache: true,
        );

        final unified = response.data;
        final newProperties = [...state.properties, ...?unified?.properties];
        _updatePageState(
          pageType,
          state.copyWith(
            properties: newProperties,
            currentPage: state.currentPage + 1,
            totalPages: unified?.totalPages ?? state.totalPages,
            hasMore: unified?.hasMore ?? state.hasMore,
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

  // Alias for controllers
  Future<void> loadMoreData(PageType pageType) => loadMorePageData(pageType);

  // Central swipe action to maintain unidirectional data flow
  Future<void> recordSwipe({required int propertyId, required bool isLiked}) async {
    try {
      // Maintain likes list optimistically
      if (isLiked) {
        final prop = _findPropertyInAnyList(propertyId);
        if (prop != null) addPropertyToLikes(prop);
      } else {
        removePropertyFromLikes(propertyId);
      }

      // Also remove from discover deck optimistically
      removePropertyFromDiscover(propertyId);

      // Background network sync
      unawaited(_swipesRepository.recordSwipe(propertyId: propertyId, isLiked: isLiked));
    } catch (e) {
      DebugLogger.error('Failed to record swipe: $e');
    }
  }

  PropertyModel? _findPropertyInAnyList(int propertyId) {
    for (final p in exploreState.value.properties) {
      if (p.id == propertyId) return p;
    }
    for (final p in discoverState.value.properties) {
      if (p.id == propertyId) return p;
    }
    for (final p in likesState.value.properties) {
      if (p.id == propertyId) return p;
    }
    return null;
  }

  // Internal: fetch page data (page 1) and update state, with optional ETag
  Future<void> _fetchAndUpdatePage(
    PageType pageType, {
    required int page,
    bool useEtag = false,
  }) async {
    final state = _getStateForPage(pageType);
    LocationData? loc = state.selectedLocation;
    loc ??= await _locationController.getInitialLocation();

    final ifNoneMatch = useEtag ? state.getAdditionalData<String>('etag') : null;

    if (pageType == PageType.likes) {
      final isLikedSegment =
          (state.getAdditionalData<String>('currentSegment') ?? 'liked') == 'liked';
      final resp = await _apiService.getSwipesWithCacheValidation(
        lat: loc.latitude,
        lng: loc.longitude,
        radius: state.filters.radiusKm?.toInt(),
        q: state.searchQuery,
        propertyType: state.filters.propertyType,
        purpose: state.filters.purpose,
        priceMin: state.filters.priceMin,
        priceMax: state.filters.priceMax,
        bedroomsMin: state.filters.bedroomsMin,
        bedroomsMax: state.filters.bedroomsMax,
        bathroomsMin: state.filters.bathroomsMin,
        bathroomsMax: state.filters.bathroomsMax,
        areaMin: state.filters.areaMin,
        areaMax: state.filters.areaMax,
        amenities: state.filters.amenities,
        parkingSpacesMin: state.filters.parkingSpacesMin,
        floorNumberMin: state.filters.floorNumberMin,
        floorNumberMax: state.filters.floorNumberMax,
        ageMax: state.filters.ageMax,
        checkIn: state.filters.checkInDate?.toIso8601String().split('T').first,
        checkOut: state.filters.checkOutDate?.toIso8601String().split('T').first,
        guests: state.filters.guests,
        isLiked: isLikedSegment,
        sortBy: state.filters.sortBy?.toString().split('.').last,
        page: 1,
        limit: 50,
        ifNoneMatch: ifNoneMatch,
      );

      if (resp.notModified) {
        _updatePageState(
          pageType,
          state.copyWith(isLoading: false, isRefreshing: false, error: null),
        );
        return;
      }

      final raw = resp.data ?? {};
      final List<PropertyModel> props = (raw['properties'] as List<dynamic>? ?? [])
          .map((e) => PropertyModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final totalPages = raw['total_pages'] ?? 1;
      final hasMore = raw['has_next'] ?? (1 < totalPages);

      _updatePageState(
        pageType,
        state
            .copyWith(
              properties: props,
              selectedLocation: loc,
              currentPage: 1,
              totalPages: totalPages,
              hasMore: hasMore,
              isLoading: false,
              isRefreshing: false,
              lastFetched: DateTime.now(),
              error: null,
            )
            .updateAdditionalData('etag', resp.etag),
      );
      return;
    }

    // Explore/Discover
    final resp = await _apiService.searchPropertiesWithCacheValidation(
      filters: state.filters.copyWith(searchQuery: state.searchQuery),
      latitude: loc.latitude,
      longitude: loc.longitude,
      radiusKm: (state.filters.radiusKm ?? 10.0).clamp(5.0, 50.0),
      page: 1,
      limit: pageType == PageType.discover ? 20 : 50,
      excludeSwiped: pageType == PageType.discover,
      useCache: true,
      ifNoneMatch: ifNoneMatch,
    );
    if (resp.notModified) {
      _updatePageState(
        pageType,
        state.copyWith(isLoading: false, isRefreshing: false, error: null),
      );
      return;
    }
    final unified = resp.data!;
    _updatePageState(
      pageType,
      state
          .copyWith(
            properties: unified.properties,
            selectedLocation: loc,
            currentPage: 1,
            totalPages: unified.totalPages,
            hasMore: unified.hasMore,
            isLoading: false,
            isRefreshing: false,
            lastFetched: DateTime.now(),
            error: null,
          )
          .updateAdditionalData('etag', resp.etag),
    );
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

  // Set property type across all pages; optionally only if unset/empty
  void setPropertyTypeForAllPages(List<String>? propertyTypes, {bool onlyIfUnset = false}) {
    void setFor(PageType page) {
      final state = _getStateForPage(page);
      final current = state.filters.propertyType ?? const [];
      if (onlyIfUnset && current.isNotEmpty) return;
      final updatedFilters = state.filters.copyWith(propertyType: propertyTypes ?? const []);
      _updatePageState(page, state.copyWith(filters: updatedFilters).resetData());
    }

    setFor(PageType.explore);
    setFor(PageType.discover);
    setFor(PageType.likes);
    DebugLogger.info(
      '🏷️ Set property types="${(propertyTypes ?? const []).join(', ')}" for all pages (onlyIfUnset=$onlyIfUnset)',
    );
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
