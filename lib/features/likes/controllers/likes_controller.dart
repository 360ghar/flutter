import 'dart:async';
import 'package:get/get.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/page_state_model.dart';
import '../../../core/data/models/unified_filter_model.dart';
import '../../../core/data/repositories/swipes_repository.dart';

import '../../../core/controllers/filter_service.dart';
import '../../../core/controllers/page_state_service.dart';
import '../../../core/utils/debug_logger.dart';

enum LikesSegment { liked, passed }

enum LikesState {
  initial,
  loading,
  loaded,
  empty,
  error,
  loadingMore,
}

class LikesController extends GetxController {
  final SwipesRepository _swipesRepository = Get.find<SwipesRepository>();
  final FilterService _filterService = Get.find<FilterService>();
  final PageStateService _pageStateService = Get.find<PageStateService>();

  // Current segment (Liked or Passed)
  final Rx<LikesSegment> currentSegment = LikesSegment.liked.obs;
  
  // No longer need swipe ID mapping since properties have liked attribute

  // State management for liked properties
  final Rx<LikesState> likedState = LikesState.initial.obs;
  final RxList<PropertyModel> likedProperties = <PropertyModel>[].obs;
  int _likedPage = 1;
  bool _likedHasMore = true;

  // State management for passed properties
  final Rx<LikesState> passedState = LikesState.initial.obs;
  final RxList<PropertyModel> passedProperties = <PropertyModel>[].obs;
  int _passedPage = 1;
  bool _passedHasMore = true;

  // Search functionality
  final RxString searchQuery = ''.obs;
  final RxList<PropertyModel> filteredLikedProperties = <PropertyModel>[].obs;
  final RxList<PropertyModel> filteredPassedProperties = <PropertyModel>[].obs;
  Timer? _searchDebouncer;

  // Error handling
  final RxnString likedError = RxnString();
  final RxnString passedError = RxnString();

  // Pagination totals tracked via server pages; counts not required per spec

  // Constants
  static const int _limit = 50;

  // Page activation listener
  Worker? _pageActivationWorker;

  @override
  void onInit() {
    super.onInit();
    // Don't set current page here - let navigation handle it
    _setupSearchListener();
    // LAZY LOADING: Remove initial data loading from onInit
  }

  @override
  void onReady() {
    super.onReady();
    
    // Set up listener for page activation
    _pageActivationWorker = ever(_pageStateService.currentPageType, (pageType) {
      if (pageType == PageType.likes) {
        activatePage();
      }
    });
    
    // Initial activation if already on this page (with delay to ensure full initialization)
    if (_pageStateService.currentPageType.value == PageType.likes) {
      Future.delayed(const Duration(milliseconds: 100), () {
        activatePage();
      });
    }
  }

  void activatePage() {
    final ps = _pageStateService.likesState.value;
    // Keep controller's segment in sync with PageStateService
    final segStr = _pageStateService.currentLikesSegment;
    currentSegment.value = segStr == 'liked' ? LikesSegment.liked : LikesSegment.passed;

    // Ensure we have a location, then load current segment via PageStateService
    if (!ps.hasLocation) {
      _pageStateService.useCurrentLocationForPage(PageType.likes).whenComplete(() {
        _pageStateService.loadPageData(PageType.likes, forceRefresh: true);
      });
      return;
    }

    if (ps.properties.isEmpty && !ps.isLoading) {
      _pageStateService.loadPageData(PageType.likes, forceRefresh: true);
    } else if (ps.isDataStale) {
      _pageStateService.loadPageData(PageType.likes, backgroundRefresh: true);
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      await _pageStateService.loadPageData(PageType.likes, backgroundRefresh: true);
    } catch (e) {
      DebugLogger.error('❌ Background refresh failed: $e');
    }
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    _pageActivationWorker?.dispose();
    super.onClose();
  }

  void _setupSearchListener() {
    // Apply search filter whenever search query changes
    debounce(searchQuery, (_) {
      // Propagate to global filter so API gets 'q'
      _filterService.updateSearchQuery(searchQuery.value);
    }, time: const Duration(milliseconds: 300));
  }

  Future<void> _loadInitialData() async {
    // Load current segment only via PageStateService
    await _pageStateService.loadPageData(PageType.likes, forceRefresh: true);
  }

  // Segment switching
  void switchToSegment(LikesSegment segment) {
    if (currentSegment.value == segment) return;
    currentSegment.value = segment;
    DebugLogger.api('📱 Switched to ${segment.name} segment');
    _pageStateService.updateLikesSegment(segment == LikesSegment.liked ? 'liked' : 'passed');
  }

  // Deprecated loaders replaced by PageStateService handlers (kept to avoid breaking references)
  Future<void> _loadLikedProperties({
    required int page,
    bool isInitial = false,
    bool isLoadMore = false,
    bool backgroundRefresh = false,
  }) async {
    await _pageStateService.loadPageData(PageType.likes, forceRefresh: isInitial, backgroundRefresh: backgroundRefresh);
  }

  Future<void> _loadPassedProperties({
    required int page,
    bool isInitial = false,
    bool isLoadMore = false,
    bool backgroundRefresh = false,
  }) async {
    await _pageStateService.loadPageData(PageType.likes, forceRefresh: isInitial, backgroundRefresh: backgroundRefresh);
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    _filterService.updateSearchQuery(query);
    DebugLogger.api('🔍 Search query updated: "$query"');
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  // Helper method to build filters with search query
  UnifiedFilterModel _buildFiltersWithSearch() {
    // Use centralized filters that already hold searchQuery
    return _filterService.currentFilter;
  }

  void _applySearchFilter() {
    // Server handles filtering; no client-side filtering required
  }

  // Client-side matching deprecated in favor of server-side filtering

  // Infinite scroll - load more
  Future<void> loadMoreCurrentSegment() async {
    await _pageStateService.loadMorePageData(PageType.likes);
  }

  Future<void> loadMoreLiked() async {
    await _pageStateService.loadMorePageData(PageType.likes);
  }

  Future<void> loadMorePassed() async {
    await _pageStateService.loadMorePageData(PageType.likes);
  }

  // Refresh
  Future<void> refreshCurrentSegment() async {
    if (currentSegment.value == LikesSegment.liked) {
      await refreshLiked();
    } else {
      await refreshPassed();
    }
  }

  Future<void> refreshLiked() async {
    await _pageStateService.loadPageData(PageType.likes, forceRefresh: true);
  }

  Future<void> refreshPassed() async {
    await _pageStateService.loadPageData(PageType.likes, forceRefresh: true);
  }

  Future<void> refreshAll() async {
    await _pageStateService.loadPageData(PageType.likes, forceRefresh: true);
  }

  // Navigation
  void viewPropertyDetails(PropertyModel property) {
    Get.toNamed('/property-details', arguments: {'property': property});
  }

  // Remove property from likes by recording a "dislike" swipe
  Future<void> removeFromLikes(PropertyModel property) async {
    try {
      DebugLogger.api('🗑️ Removing property from likes: ${property.title}');
      // Optimistically update central page state
      _pageStateService.removePropertyFromLikes(property.id);
      // Record a "dislike" swipe to remove it from liked properties
      await _swipesRepository.recordSwipe(
        propertyId: property.id,
        isLiked: false, // This will unlike the property
      );

      DebugLogger.success('✅ Property successfully removed from likes');

      Get.snackbar(
        'Removed',
        '${property.title} removed from liked properties',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

    } catch (e) {
      DebugLogger.error('❌ Failed to remove from likes: $e');

      // Revert optimistic update
      Get.snackbar(
        'Error',
        'Failed to remove property. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Refresh to restore correct state
      await _pageStateService.loadPageData(PageType.likes, forceRefresh: true);
    }
  }

  // Error handling
  void retryCurrentSegment() {
    if (currentSegment.value == LikesSegment.liked) {
      retryLiked();
    } else {
      retryPassed();
    }
  }

  void retryLiked() => _pageStateService.loadPageData(PageType.likes, forceRefresh: true);

  void retryPassed() => _pageStateService.loadPageData(PageType.likes, forceRefresh: true);

  // Getters for current segment
  List<PropertyModel> get currentProperties {
    return _pageStateService.likesState.value.properties;
  }

  LikesState get currentState {
    final ps = _pageStateService.likesState.value;
    if (ps.isLoading) return LikesState.loading;
    if (ps.isLoadingMore) return LikesState.loadingMore;
    if (ps.error != null) return LikesState.error;
    if (ps.properties.isEmpty) return LikesState.empty;
    return LikesState.loaded;
  }

  String? get currentError {
    return _pageStateService.likesState.value.error;
  }

  bool get currentHasMore {
    return _pageStateService.likesState.value.hasMore;
  }

  // Statistics
  String get currentSegmentTitle {
    return currentSegment.value == LikesSegment.liked ? 'Liked Properties' : 'Passed Properties';
  }

  String get currentCountText {
    final count = currentProperties.length;
    return searchQuery.value.isNotEmpty ? '$count results' : (count == 1 ? '$count property' : '$count properties');
  }

  String get emptyStateMessage {
    if (searchQuery.value.isNotEmpty) {
      return 'No properties match your search';
    }
    
    return currentSegment.value == LikesSegment.liked 
        ? 'No liked properties yet.\nStart swiping to see properties you love!'
        : 'No passed properties yet.\nProperties you swipe left on will appear here.';
  }

  // Helper getters
  bool get isCurrentLoading => _pageStateService.likesState.value.isLoading;
  bool get isCurrentEmpty => !_pageStateService.likesState.value.isLoading && currentProperties.isEmpty && _pageStateService.likesState.value.error == null;
  bool get hasCurrentError => _pageStateService.likesState.value.error != null;
  bool get isCurrentLoaded => !isCurrentLoading && !isCurrentEmpty && !hasCurrentError;
  bool get isCurrentLoadingMore => _pageStateService.likesState.value.isLoadingMore;
  bool get hasCurrentProperties => currentProperties.isNotEmpty;
  bool get hasSearchQuery => searchQuery.value.isNotEmpty;
}
