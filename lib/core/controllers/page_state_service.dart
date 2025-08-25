import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/models/page_state_model.dart';
import '../data/models/unified_filter_model.dart';
import '../data/repositories/properties_repository.dart';
import '../utils/debug_logger.dart';
import 'location_controller.dart';
import 'auth_controller.dart';

class PageStateService extends GetxController {
  static PageStateService get instance => Get.find<PageStateService>();

  // Storage instance
  final _storage = GetStorage();
  final _propertiesRepository = Get.find<PropertiesRepository>();
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
    _locationController.currentPosition.listen((position) {
      if (position != null) {
        final loc = LocationData(
          name: 'Current Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );
        updateLocationForPage(currentPageType.value, loc, source: 'gps');
      }
    });
  }

  // Update location only for a specific page
  void updateLocationForPage(PageType pageType, LocationData location, {String source = 'manual'}) {
    final current = _getStateForPage(pageType);
    final updated = current.copyWith(
      selectedLocation: location,
      locationSource: source,
      filters: current.filters.copyWith(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    );
    _updatePageState(pageType, updated);
    _debounceRefresh(pageType);
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
    currentPageType.value = pageType;
    DebugLogger.info('📱 Switched to ${pageType.name} page');
  }

  void notifyPageActivated(PageType pageType) {
    setCurrentPage(pageType);
    final state = _getStateForPage(pageType);
    if (!state.isLoading && state.isDataStale) {
      loadPageData(pageType, backgroundRefresh: true);
    }
  }

  // Location management
  Future<void> updateLocation(LocationData location, {String source = 'manual'}) async {
    try {
      // Update backend if authenticated
      if (_authController.isAuthenticated) {
        await _authController.updateUserLocation(location.latitude, location.longitude);
      }
      // Update only current page to keep independent state per page
      updateLocationForPage(currentPageType.value, location, source: source);

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
        final location = LocationData(
          name: 'Current Location',
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
        final loc = LocationData(
          name: 'Current Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );
        updateLocationForPage(pageType, loc, source: 'gps');
        return;
      }

      // Fallback to IP-based location
      final ipLoc = await _locationController.getIpLocation();
      if (ipLoc != null) {
        updateLocationForPage(pageType, ipLoc, source: 'ip');
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
        exploreState.value = exploreState.value.copyWith(filters: filters).resetData();
        _debounceRefresh(pageType);
        break;
      case PageType.discover:
        discoverState.value = discoverState.value.copyWith(filters: filters).resetData();
        _debounceRefresh(pageType);
        break;
      case PageType.likes:
        likesState.value = likesState.value.copyWith(filters: filters).resetData();
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
        exploreState.value = exploreState.value.copyWith(searchQuery: query).resetData();
        _debounceRefresh(pageType);
        break;
      case PageType.likes:
        likesState.value = likesState.value.copyWith(searchQuery: query).resetData();
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
  Future<void> loadPageData(PageType pageType, {bool forceRefresh = false, bool backgroundRefresh = false}) async {
    try {
      final state = _getStateForPage(pageType);
      if (state.isLoading) return;

      // Skip if data is fresh and not forcing refresh
      if (!forceRefresh && !backgroundRefresh && !state.isDataStale && state.properties.isNotEmpty) {
        return;
      }

      // Set appropriate loading state
      if (!backgroundRefresh) {
        _updatePageState(pageType, state.copyWith(isLoading: true, error: null));
      } else {
        _updatePageState(pageType, state.copyWith(isRefreshing: true, error: null));
      }

      final response = await _propertiesRepository.getProperties(
        filters: state.filters.copyWith(searchQuery: state.searchQuery),
        page: 1,
        limit: pageType == PageType.discover ? 20 : 50,
      );

      _updatePageState(pageType, state.copyWith(
        properties: response.properties,
        currentPage: 1,
        totalPages: response.totalPages,
        hasMore: response.hasMore,
        isLoading: false,
        isRefreshing: false,
        lastFetched: DateTime.now(),
      ));

      DebugLogger.success('✅ Loaded ${response.properties.length} properties for ${pageType.name}');
    } catch (e) {
      DebugLogger.error('❌ Failed to load ${pageType.name} data: $e');
      final state = _getStateForPage(pageType);
      _updatePageState(pageType, state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMorePageData(PageType pageType) async {
    try {
      final state = _getStateForPage(pageType);
      if (state.isLoadingMore || !state.hasMore) return;

      _updatePageState(pageType, state.copyWith(isLoadingMore: true));

      final response = await _propertiesRepository.getProperties(
        filters: state.filters.copyWith(searchQuery: state.searchQuery),
        page: state.currentPage + 1,
        limit: pageType == PageType.discover ? 20 : 50,
      );

      final newProperties = [...state.properties, ...response.properties];
      
      _updatePageState(pageType, state.copyWith(
        properties: newProperties,
        currentPage: state.currentPage + 1,
        totalPages: response.totalPages,
        hasMore: response.hasMore,
        isLoadingMore: false,
      ));

      DebugLogger.success('✅ Loaded ${response.properties.length} more properties for ${pageType.name}');
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
    likesState.value = likesState.value.updateAdditionalData('currentSegment', segment);
  }

  String get currentLikesSegment => likesState.value.getAdditionalData<String>('currentSegment') ?? 'liked';

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
