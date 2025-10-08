import 'package:get/get.dart';

import 'package:ghar360/core/controllers/page_state_service.dart';
import 'package:ghar360/core/data/models/page_state_model.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_mapper.dart';

// Controllers should never talk to repositories directly

enum DiscoverState { initial, loading, loaded, empty, error, prefetching }

class DiscoverController extends GetxController {
  final PageStateService _pageStateService = Get.find<PageStateService>();

  // Reactive state
  final Rx<DiscoverState> state = DiscoverState.initial.obs;
  final RxList<PropertyModel> deck = <PropertyModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final Rxn<AppException> error = Rxn<AppException>();

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  static const int _prefetchThreshold = 3;

  // Swipe tracking
  final RxInt totalSwipesInSession = 0.obs;
  final RxInt likesInSession = 0.obs;
  final RxInt passesInSession = 0.obs;

  // Loading states
  final RxBool isPrefetching = false.obs;

  // Page activation listener
  Worker? _pageActivationWorker;
  Worker? _pageStateSyncWorker;

  @override
  void onInit() {
    super.onInit();
    // Don't set current page here - let navigation handle it
    _setupFilterListener();
    // LAZY LOADING: Remove initial data loading from onInit
    _setupPageStateSync();
  }

  @override
  void onReady() {
    super.onReady();
    DebugLogger.info('🚀 DiscoverController.onReady() called');
    DebugLogger.info('📱 Current page type: ${_pageStateService.currentPageType.value}');

    // Set up listener for page activation
    _pageActivationWorker = ever(_pageStateService.currentPageType, (pageType) {
      DebugLogger.info('📱 Page type changed to: $pageType');
      if (pageType == PageType.discover) {
        activatePage();
      }
    });

    // Initial activation if already on this page (with delay to ensure full initialization)
    if (_pageStateService.currentPageType.value == PageType.discover) {
      DebugLogger.info('✅ Already on discover page, activating after delay');
      Future.delayed(const Duration(milliseconds: 100), () {
        activatePage();
      });
    } else {
      DebugLogger.info('ℹ️ Not on discover page yet, waiting for navigation');
    }
  }

  void activatePage() {
    DebugLogger.info('🚀 DiscoverController.activatePage() called');
    final state = _pageStateService.discoverState.value;
    DebugLogger.info(
      '📊 PageState: properties=${state.properties.length}, controllerState=${this.state.value}',
    );

    // If page state already has properties but controller is still initial, hydrate deck immediately
    if (state.properties.isNotEmpty && this.state.value == DiscoverState.initial) {
      DebugLogger.info('🧩 Hydrating deck from existing PageState properties');
      _hydrateDeckFromPageState(state);
      return;
    }

    if (state.properties.isEmpty && this.state.value == DiscoverState.initial) {
      DebugLogger.info('🌍 Initializing location and loading initial data');
      // Initialize location and load initial data
      _pageStateService.useCurrentLocationForPage(PageType.discover).whenComplete(() {
        DebugLogger.info('✅ Location initialization completed, loading deck');
        _loadInitialDeck();
      });
    } else if (state.isDataStale) {
      DebugLogger.info('🔄 Data is stale, refreshing in background');
      _refreshInBackground();
    } else {
      DebugLogger.info('ℹ️ No action needed - data exists and is fresh');
    }
  }

  void _setupPageStateSync() {
    // Keep controller deck/state in sync with PageStateService for discover page
    _pageStateSyncWorker = ever(_pageStateService.discoverState, (PageStateModel ps) {
      try {
        // If PageState has properties and our deck is empty or behind, hydrate/sync
        if (ps.properties.isNotEmpty) {
          final shouldHydrate = deck.isEmpty || deck.length != ps.properties.length;
          if (shouldHydrate) {
            DebugLogger.info('🔗 Syncing deck with PageState (${ps.properties.length} items)');
            _hydrateDeckFromPageState(ps);
          } else if (state.value == DiscoverState.initial) {
            // Ensure state is not stuck in initial
            state.value = DiscoverState.loaded;
          }
        }
      } catch (e) {
        DebugLogger.error('❌ Error syncing discover state: $e');
      }
    });
  }

  void _hydrateDeckFromPageState(PageStateModel ps) {
    deck.assignAll(ps.properties);
    currentIndex.value = 0;
    _currentPage = ps.currentPage;
    _totalPages = ps.totalPages;
    _hasMore = ps.hasMore;
    error.value = null;
    state.value = deck.isEmpty ? DiscoverState.empty : DiscoverState.loaded;
  }

  Future<void> _refreshInBackground() async {
    try {
      // Delegate to PageStateService for background refresh
      await _pageStateService.loadPageData(PageType.discover, backgroundRefresh: true);
    } catch (e) {
      DebugLogger.error('❌ Background refresh failed: $e');
      // Handle silently or with subtle notification
    }
  }

  void _setupFilterListener() {
    // Discover page refresh is managed by PageStateService when filters/location change.
    // We only observe for logging to avoid feedback loops.
    debounce<PageStateModel>(_pageStateService.discoverState, (ps) {
      DebugLogger.info(
        '🔔 Discover page-state changed: loading=${ps.isLoading}, refreshing=${ps.isRefreshing}, props=${ps.properties.length}',
      );
      // No direct reload here; sync worker will hydrate when data arrives.
    }, time: const Duration(milliseconds: 500));
  }

  Future<void> _loadInitialDeck() async {
    DebugLogger.info('🃏 _loadInitialDeck() called, current state: ${state.value}');
    if (state.value == DiscoverState.loading) {
      DebugLogger.warning('⚠️ Already loading, skipping');
      return;
    }

    try {
      DebugLogger.info('🔄 Starting initial deck load');
      _pageStateService.notifyPageRefreshing(PageType.discover, true);
      state.value = DiscoverState.loading;
      error.value = null;

      await _loadMoreProperties();

      DebugLogger.info('📦 Load completed, deck size: ${deck.length}');
      if (deck.isEmpty) {
        DebugLogger.warning('📭 Deck is empty, setting state to empty');
        state.value = DiscoverState.empty;
      } else {
        DebugLogger.success('✅ Deck loaded successfully with ${deck.length} properties');
        state.value = DiscoverState.loaded;
        currentIndex.value = 0;
      }
    } catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to load initial deck', e, stackTrace);
      state.value = DiscoverState.error;
      error.value = ErrorMapper.mapApiError(e, stackTrace);
    } finally {
      _pageStateService.notifyPageRefreshing(PageType.discover, false);
      // If PageStateService has data, ensure hydration to avoid desync
      final ps = _pageStateService.discoverState.value;
      if (ps.properties.isNotEmpty && deck.isEmpty) {
        DebugLogger.info('🧩 Post-load hydration from PageStateService as deck is empty');
        _hydrateDeckFromPageState(ps);
      }
    }
  }

  Future<void> _loadMoreProperties() async {
    if (!_hasMore) {
      DebugLogger.api('📚 No more properties to load (page $_currentPage/$_totalPages)');
      return;
    }

    try {
      DebugLogger.api('📚 Triggering PageStateService to load more properties');
      await _pageStateService.loadMoreData(PageType.discover);
      // Hydrate from updated PageState
      _hydrateDeckFromPageState(_pageStateService.discoverState.value);
    } catch (e) {
      DebugLogger.error('❌ Failed to load more properties: $e');
      rethrow;
    }
  }

  // Pagination is derived from PageStateService via hydration

  // Swipe actions
  Future<void> swipeRight(PropertyModel property) async {
    await _handleSwipe(property, true);
    _recordSwipeStats(true);
  }

  Future<void> swipeLeft(PropertyModel property) async {
    await _handleSwipe(property, false);
    _recordSwipeStats(false);
  }

  Future<void> _handleSwipe(PropertyModel property, bool isLiked) async {
    try {
      DebugLogger.api('👆 Swiping ${isLiked ? 'RIGHT (LIKE)' : 'LEFT (PASS)'}: ${property.title}');

      // Optimistic update - move to next card immediately
      _moveToNextCard();

      // Delegate swipe mutation + backend sync to PageStateService
      _recordSwipeAsync(property.id, isLiked);

      // Check if we need to prefetch more properties
      _checkForPrefetch();
    } catch (e) {
      DebugLogger.error('❌ Failed to handle swipe: $e');
      // Could implement rollback logic here if needed
    }
  }

  void _moveToNextCard() {
    if (currentIndex.value < deck.length - 1) {
      currentIndex.value++;
    } else {
      // No more cards - check if we can load more
      if (_hasMore && state.value != DiscoverState.loading) {
        _loadInitialDeck(); // Reload deck
      } else {
        state.value = DiscoverState.empty;
      }
    }
  }

  void _recordSwipeAsync(int propertyId, bool isLiked) {
    // Delegate recording to PageStateService for unidirectional flow
    _pageStateService
        .recordSwipe(propertyId: propertyId, isLiked: isLiked)
        .catchError(
          (e) => DebugLogger.error('❌ Failed to record swipe for property $propertyId: $e'),
        );
  }

  void _recordSwipeStats(bool isLiked) {
    totalSwipesInSession.value++;
    if (isLiked) {
      likesInSession.value++;
    } else {
      passesInSession.value++;
    }
  }

  void _checkForPrefetch() {
    final remainingCards = deck.length - currentIndex.value - 1;

    if (remainingCards <= _prefetchThreshold && _hasMore && !isPrefetching.value) {
      _prefetchMoreProperties();
    }
  }

  Future<void> _prefetchMoreProperties() async {
    if (isPrefetching.value || !_hasMore) return;

    try {
      isPrefetching.value = true;
      state.value = DiscoverState.prefetching;
      _pageStateService.notifyPageRefreshing(PageType.discover, true);

      DebugLogger.api('🔄 Prefetching more properties...');
      await _loadMoreProperties();

      if (state.value == DiscoverState.prefetching) {
        state.value = DiscoverState.loaded;
      }
    } catch (e) {
      DebugLogger.error('❌ Prefetch failed: $e');
      // Don't change state on prefetch failure
    } finally {
      isPrefetching.value = false;
      _pageStateService.notifyPageRefreshing(PageType.discover, false);
    }
  }

  // Reset and reload deck (when filters change)
  Future<void> _resetAndLoadDeck({bool backgroundRefresh = false}) async {
    if (backgroundRefresh) {
      DebugLogger.api('🔄 Background refresh for discover deck via PageStateService');
      await _pageStateService.loadPageData(PageType.discover, backgroundRefresh: true);
      _hydrateDeckFromPageState(_pageStateService.discoverState.value);
    } else {
      DebugLogger.api('🔄 Resetting deck due to filter change');

      deck.clear();
      currentIndex.value = 0;
      _currentPage = 1;
      _totalPages = 1;
      _hasMore = true;

      // Prefer centralized loading through PageStateService, then hydrate
      try {
        state.value = DiscoverState.loading;
        error.value = null;
        _pageStateService.notifyPageRefreshing(PageType.discover, true);
        await _pageStateService.loadPageData(PageType.discover, forceRefresh: true);
        _hydrateDeckFromPageState(_pageStateService.discoverState.value);
      } catch (e) {
        DebugLogger.error('❌ Failed to reset and load deck via PageStateService: $e');
        // Fallback to direct loading
        await _loadInitialDeck();
      } finally {
        _pageStateService.notifyPageRefreshing(PageType.discover, false);
      }
    }
  }

  // Manual refresh
  Future<void> refreshDeck() async {
    totalSwipesInSession.value = 0;
    likesInSession.value = 0;
    passesInSession.value = 0;

    await _resetAndLoadDeck();
  }

  // Undo last swipe (if supported by API)
  Future<void> undoLastSwipe() async {
    try {
      // This would require API support and tracking last swiped property
      DebugLogger.api('⏪ Undoing last swipe...');

      // For now, just go back one card if possible
      if (currentIndex.value > 0) {
        currentIndex.value--;
        Get.snackbar(
          'Undone!',
          'Moved back to previous property',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      DebugLogger.error('❌ Failed to undo swipe: $e');
      Get.snackbar(
        'Error',
        'Could not undo last swipe',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Get current property
  PropertyModel? get currentProperty {
    if (deck.isEmpty || currentIndex.value >= deck.length) {
      return null;
    }
    return deck[currentIndex.value];
  }

  // Get next few properties for preview
  List<PropertyModel> get nextProperties {
    final start = currentIndex.value + 1;
    final end = (start + 3).clamp(0, deck.length);
    return deck.sublist(start, end);
  }

  // Statistics
  int get remainingCards => deck.length - currentIndex.value - 1;
  double get progressPercentage {
    if (deck.isEmpty) return 0.0;
    return (currentIndex.value / deck.length).clamp(0.0, 1.0);
  }

  String get sessionStats {
    if (totalSwipesInSession.value == 0) {
      return 'Start swiping to see stats';
    }

    final likeRate = (likesInSession.value / totalSwipesInSession.value * 100).round();
    return '${totalSwipesInSession.value} swipes • ${likesInSession.value} likes • $likeRate% like rate';
  }

  // Navigation to property details
  void viewPropertyDetails(PropertyModel property) {
    Get.toNamed('/property-details', arguments: {'property': property});
  }

  // Quick filter shortcuts
  Future<void> showNearbyProperties() async {
    await _pageStateService.useCurrentLocation();
  }

  void filterByPropertyType(String type) {
    final currentFilters = _pageStateService.getCurrentPageState().filters;
    final updatedFilters = currentFilters.copyWith(propertyType: [type]);
    _pageStateService.updatePageFilters(PageType.discover, updatedFilters);
  }

  void filterByPurpose(String purpose) {
    final currentFilters = _pageStateService.getCurrentPageState().filters;
    final updatedFilters = currentFilters.copyWith(purpose: purpose);
    _pageStateService.updatePageFilters(PageType.discover, updatedFilters);
  }

  // Error handling
  void retryLoading() {
    error.value = null;
    _loadInitialDeck();
  }

  void clearError() {
    error.value = null;
    if (state.value == DiscoverState.error) {
      state.value = deck.isEmpty ? DiscoverState.empty : DiscoverState.loaded;
    }
  }

  @override
  void onClose() {
    _pageActivationWorker?.dispose();
    _pageStateSyncWorker?.dispose();
    super.onClose();
  }

  // Helper getters
  bool get isLoading => state.value == DiscoverState.loading;
  bool get isEmpty => state.value == DiscoverState.empty;
  bool get hasError => state.value == DiscoverState.error;
  bool get isLoaded => state.value == DiscoverState.loaded;
  bool get hasProperties => deck.isNotEmpty;
  bool get canSwipe => hasProperties && currentProperty != null;
}
