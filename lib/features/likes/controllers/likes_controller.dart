import 'dart:async';
import 'package:get/get.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/unified_filter_model.dart';
import '../../../core/data/repositories/swipes_repository.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/controllers/filter_service.dart';
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
  final ApiService _apiService = Get.find<ApiService>();

  // Current segment (Liked or Passed)
  final Rx<LikesSegment> currentSegment = LikesSegment.liked.obs;
  
  // Map to store property ID to swipe ID mapping for liked properties
  final RxMap<int, int> _propertyToSwipeIdMap = <int, int>{}.obs;

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

  // Background refresh state
  final RxBool isRefreshing = false.obs;

  // Constants
  static const int _limit = 50;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _setupSearchListener();
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    super.onClose();
  }

  void _setupSearchListener() {
    // Apply search filter whenever search query changes
    debounce(searchQuery, (_) {
      _applySearchFilter();
    }, time: const Duration(milliseconds: 300));
  }

  Future<void> _loadInitialData() async {
    // Load both liked and passed properties initially
    await Future.wait([
      _loadLikedProperties(page: 1, isInitial: true),
      _loadPassedProperties(page: 1, isInitial: true),
    ]);
  }

  // Segment switching
  void switchToSegment(LikesSegment segment) {
    if (currentSegment.value != segment) {
      currentSegment.value = segment;
      DebugLogger.api('📱 Switched to ${segment.name} segment');
      
      // Load data for segment if not loaded yet
      if (segment == LikesSegment.liked && likedState.value == LikesState.initial) {
        _loadLikedProperties(page: 1, isInitial: true);
      } else if (segment == LikesSegment.passed && passedState.value == LikesState.initial) {
        _loadPassedProperties(page: 1, isInitial: true);
      }
    }
  }

  // Load liked properties
  Future<void> _loadLikedProperties({
    required int page,
    bool isInitial = false,
    bool isLoadMore = false,
  }) async {
    if (!_likedHasMore && !isInitial) {
      DebugLogger.api('❤️ No more liked properties to load');
      return;
    }

    try {
      if (isInitial && !isRefreshing.value) {
        likedState.value = LikesState.loading;
      } else if (isLoadMore) {
        likedState.value = LikesState.loadingMore;
      }

      if (isInitial) {
        likedError.value = null;
        likedProperties.clear();
        _likedPage = 1;
        _likedHasMore = true;
      }

      DebugLogger.api('❤️ Loading liked properties: page $page');

      final propertiesWithSwipeIds = await _swipesRepository.getLikedPropertiesWithSwipeIds(
        filters: _buildFiltersWithSearch(),
        page: page,
        limit: _limit,
      );

      // Extract properties and populate swipe ID mapping
      final properties = propertiesWithSwipeIds.map((item) => item.property).toList();
      
      if (isInitial) {
        likedProperties.assignAll(properties);
        _propertyToSwipeIdMap.clear();
        // Populate swipe ID mapping
        for (final item in propertiesWithSwipeIds) {
          _propertyToSwipeIdMap[item.property.id] = item.swipeId;
        }
      } else {
        // Remove duplicates and add new properties
        final existingIds = likedProperties.map((p) => p.id).toSet();
        final newProperties = properties.where((p) => !existingIds.contains(p.id)).toList();
        likedProperties.addAll(newProperties);
        
        // Update swipe ID mapping for new properties
        for (final item in propertiesWithSwipeIds) {
          if (!existingIds.contains(item.property.id)) {
            _propertyToSwipeIdMap[item.property.id] = item.swipeId;
          }
        }
      }

      // Update pagination
      _likedHasMore = properties.length == _limit; // rely on length to continue
      if (properties.isNotEmpty) {
        _likedPage = page + 1;
      }

      // Update state
      if (likedProperties.isEmpty) {
        likedState.value = LikesState.empty;
      } else {
        likedState.value = LikesState.loaded;
      }

      // Apply search filter
      _applySearchFilter();

      DebugLogger.success('✅ Loaded ${properties.length} liked properties (total: ${likedProperties.length})');

    } catch (e) {
      DebugLogger.error('❌ Failed to load liked properties: $e');
      likedState.value = LikesState.error;
      likedError.value = e.toString();
    }
  }

  // Load passed properties
  Future<void> _loadPassedProperties({
    required int page,
    bool isInitial = false,
    bool isLoadMore = false,
  }) async {
    if (!_passedHasMore && !isInitial) {
      DebugLogger.api('👎 No more passed properties to load');
      return;
    }

    try {
      if (isInitial && !isRefreshing.value) {
        passedState.value = LikesState.loading;
      } else if (isLoadMore) {
        passedState.value = LikesState.loadingMore;
      }

      if (isInitial) {
        passedError.value = null;
        passedProperties.clear();
        _passedPage = 1;
        _passedHasMore = true;
      }

      DebugLogger.api('👎 Loading passed properties: page $page');

      final properties = await _swipesRepository.getPassedProperties(
        filters: _buildFiltersWithSearch(),
        page: page,
        limit: _limit,
      );

      if (isInitial) {
        passedProperties.assignAll(properties);
        // No aggregate counts required
      } else {
        // Remove duplicates and add new properties
        final existingIds = passedProperties.map((p) => p.id).toSet();
        final newProperties = properties.where((p) => !existingIds.contains(p.id)).toList();
        passedProperties.addAll(newProperties);
      }

      // Update pagination
      _passedHasMore = properties.length == _limit; // rely on length to continue
      if (properties.isNotEmpty) {
        _passedPage = page + 1;
      }

      // Update state
      if (passedProperties.isEmpty) {
        passedState.value = LikesState.empty;
      } else {
        passedState.value = LikesState.loaded;
      }

      // Apply search filter
      _applySearchFilter();

      DebugLogger.success('✅ Loaded ${properties.length} passed properties (total: ${passedProperties.length})');

    } catch (e) {
      DebugLogger.error('❌ Failed to load passed properties: $e');
      passedState.value = LikesState.error;
      passedError.value = e.toString();
    }
  }

  // Search functionality
  void updateSearchQuery(String query) {
    searchQuery.value = query;
    DebugLogger.api('🔍 Search query updated: "$query"');
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  // Helper method to build filters with search query
  UnifiedFilterModel _buildFiltersWithSearch() {
    final baseFilters = _filterService.currentFilter.value;
    
    // If we have a search query, we need to add it to city field
    if (searchQuery.value.isNotEmpty) {
      return baseFilters.copyWith(
        city: searchQuery.value,
      );
    }
    
    return baseFilters;
  }

  void _applySearchFilter() {
    // Mirror server results; keep lists as-is, since server handles filtering
    filteredLikedProperties.assignAll(likedProperties);
    filteredPassedProperties.assignAll(passedProperties);
  }

  // Client-side matching deprecated in favor of server-side filtering

  // Infinite scroll - load more
  Future<void> loadMoreCurrentSegment() async {
    if (currentSegment.value == LikesSegment.liked) {
      await loadMoreLiked();
    } else {
      await loadMorePassed();
    }
  }

  Future<void> loadMoreLiked() async {
    if (!_likedHasMore || likedState.value == LikesState.loadingMore) return;
    
    await _loadLikedProperties(page: _likedPage, isLoadMore: true);
  }

  Future<void> loadMorePassed() async {
    if (!_passedHasMore || passedState.value == LikesState.loadingMore) return;
    
    await _loadPassedProperties(page: _passedPage, isLoadMore: true);
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
    if (isRefreshing.value) return;
    try {
      isRefreshing.value = true;
      await _loadLikedProperties(page: 1, isInitial: true);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> refreshPassed() async {
    if (isRefreshing.value) return;
    try {
      isRefreshing.value = true;
      await _loadPassedProperties(page: 1, isInitial: true);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshLiked(),
      refreshPassed(),
    ]);
  }

  // Navigation
  void viewPropertyDetails(PropertyModel property) {
    Get.toNamed('/property-details', arguments: {'property': property});
  }

  // Remove property from likes using toggle API
  Future<void> removeFromLikes(PropertyModel property) async {
    try {
      DebugLogger.api('🗑️ Removing property from likes: ${property.title}');
      
      // Get the swipe ID for this property
      final swipeId = _propertyToSwipeIdMap[property.id];
      if (swipeId == null) {
        DebugLogger.error('❌ No swipe ID found for property ${property.id}');
        Get.snackbar(
          'Error',
          'Unable to remove property. Please try refreshing.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      // Optimistically remove from UI
      likedProperties.removeWhere((p) => p.id == property.id);
      filteredLikedProperties.removeWhere((p) => p.id == property.id);
      _propertyToSwipeIdMap.remove(property.id);
      
      // Call API to toggle swipe status (this will unlike the property)
      await _apiService.toggleSwipeStatus(swipeId);
      
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
      refreshLiked();
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

  void retryLiked() {
    likedError.value = null;
    _loadLikedProperties(page: 1, isInitial: true);
  }

  void retryPassed() {
    passedError.value = null;
    _loadPassedProperties(page: 1, isInitial: true);
  }

  // Getters for current segment
  List<PropertyModel> get currentProperties {
    if (currentSegment.value == LikesSegment.liked) {
      return searchQuery.value.isEmpty ? likedProperties : filteredLikedProperties;
    } else {
      return searchQuery.value.isEmpty ? passedProperties : filteredPassedProperties;
    }
  }

  LikesState get currentState {
    return currentSegment.value == LikesSegment.liked ? likedState.value : passedState.value;
  }

  String? get currentError {
    return currentSegment.value == LikesSegment.liked ? likedError.value : passedError.value;
  }

  bool get currentHasMore {
    return currentSegment.value == LikesSegment.liked ? _likedHasMore : _passedHasMore;
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

  // Called from DiscoverController for optimistic update
  void addOptimisticSwipe({
    required PropertyModel property,
    required bool isLiked,
    required int swipeId,
  }) {
    if (isLiked) {
      // Add to liked properties if not already present
      if (!likedProperties.any((p) => p.id == property.id)) {
        likedProperties.insert(0, property);
        _propertyToSwipeIdMap[property.id] = swipeId;
        _applySearchFilter(); // Re-apply search if active
        if (likedState.value == LikesState.empty) {
          likedState.value = LikesState.loaded;
        }
      }
    } else {
      // Add to passed properties if not already present
      if (!passedProperties.any((p) => p.id == property.id)) {
        passedProperties.insert(0, property);
        _applySearchFilter(); // Re-apply search if active
        if (passedState.value == LikesState.empty) {
          passedState.value = LikesState.loaded;
        }
      }
    }
  }

  // Helper getters
  bool get isCurrentLoading => currentState == LikesState.loading;
  bool get isCurrentEmpty => currentState == LikesState.empty && currentProperties.isEmpty;
  bool get hasCurrentError => currentState == LikesState.error;
  bool get isCurrentLoaded => currentState == LikesState.loaded;
  bool get isCurrentLoadingMore => currentState == LikesState.loadingMore;
  bool get hasCurrentProperties => currentProperties.isNotEmpty;
  bool get hasSearchQuery => searchQuery.value.isNotEmpty;
}