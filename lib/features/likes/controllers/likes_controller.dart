import 'dart:async';
import 'package:get/get.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/unified_filter_model.dart';
import '../../../core/data/repositories/swipes_repository.dart';
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

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _setupSearchListener();
  }

  @override
  void onReady() {
    super.onReady();
    // Always refresh when the controller becomes ready (user navigates to likes page)
    refreshAll();
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
      if (isInitial) {
        likedState.value = LikesState.loading;
        likedError.value = null;
        likedProperties.clear();
        _likedPage = 1;
        _likedHasMore = true;
      } else if (isLoadMore) {
        likedState.value = LikesState.loadingMore;
      }

      DebugLogger.api('❤️ Loading liked properties: page $page');

      final properties = await _swipesRepository.getLikedPropertiesWithSwipeIds(
        filters: _buildFiltersWithSearch(),
        page: page,
        limit: _limit,
      );

      if (isInitial) {
        likedProperties.assignAll(properties);
      } else {
        // Remove duplicates and add new properties
        final existingIds = likedProperties.map((p) => p.id).toSet();
        final newProperties = properties.where((p) => !existingIds.contains(p.id)).toList();
        likedProperties.addAll(newProperties);
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

      // Provide user-friendly error messages
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        likedError.value = "Unable to connect to server. Try again later.";
      } else if (e.toString().contains('404') || e.toString().contains('request not found')) {
        likedError.value = "Server endpoint not available. Using demo mode.";
        // In demo mode, provide some mock liked properties
        if (likedProperties.isEmpty) {
          _loadMockLikedProperties();
        }
      } else {
        likedError.value = "Failed to load liked properties. Please try again.";
      }
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
      if (isInitial) {
        passedState.value = LikesState.loading;
        passedError.value = null;
        passedProperties.clear();
        _passedPage = 1;
        _passedHasMore = true;
      } else if (isLoadMore) {
        passedState.value = LikesState.loadingMore;
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

      // Provide user-friendly error messages
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable')) {
        passedError.value = "Unable to connect to server. Try again later.";
      } else if (e.toString().contains('404') || e.toString().contains('request not found')) {
        passedError.value = "Server endpoint not available. Using demo mode.";
        // In demo mode, provide some mock passed properties
        if (passedProperties.isEmpty) {
          _loadMockPassedProperties();
        }
      } else {
        passedError.value = "Failed to load passed properties. Please try again.";
      }
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
    await _loadLikedProperties(page: 1, isInitial: true);
  }

  Future<void> refreshPassed() async {
    await _loadPassedProperties(page: 1, isInitial: true);
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

  // Remove property from likes by recording a "dislike" swipe
  Future<void> removeFromLikes(PropertyModel property) async {
    try {
      DebugLogger.api('🗑️ Removing property from likes: ${property.title}');

      // Optimistically remove from UI
      likedProperties.removeWhere((p) => p.id == property.id);
      filteredLikedProperties.removeWhere((p) => p.id == property.id);

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

  // Mock data for demo mode when backend is not available
  void _loadMockLikedProperties() {
    try {
      DebugLogger.warning('🎭 Loading mock liked properties for demo mode');

      // Create some mock liked properties
      final mockLikedProperties = [
        PropertyModel(
          id: 1,
          title: 'Luxury Apartment in Bandra',
          description: 'Beautiful 2BHK apartment with modern amenities',
          propertyType: PropertyType.apartment,
          purpose: PropertyPurpose.rent,
          basePrice: 45000.0,
          status: PropertyStatus.available,
          monthlyRent: 45000.0,
          bedrooms: 2,
          bathrooms: 2,
          areaSqft: 1200,
          fullAddress: 'Bandra West, Mumbai',
          city: 'Mumbai',
          locality: 'Bandra',
          latitude: 19.0596,
          longitude: 72.8295,
          isAvailable: true,
          viewCount: 15,
          likeCount: 8,
          interestCount: 5,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        PropertyModel(
          id: 3,
          title: 'Spacious Villa in Thane',
          description: 'Large family villa with garden',
          propertyType: PropertyType.house,
          purpose: PropertyPurpose.buy,
          basePrice: 8500000.0,
          status: PropertyStatus.available,
          bedrooms: 4,
          bathrooms: 4,
          areaSqft: 3000,
          fullAddress: 'Thane West',
          city: 'Thane',
          locality: 'Thane West',
          latitude: 19.2183,
          longitude: 72.9781,
          isAvailable: true,
          viewCount: 25,
          likeCount: 12,
          interestCount: 8,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ];

      likedProperties.assignAll(mockLikedProperties);
      likedState.value = LikesState.loaded;
      likedError.value = null;

      DebugLogger.success('✅ Loaded ${mockLikedProperties.length} mock liked properties');
    } catch (e) {
      DebugLogger.error('❌ Failed to load mock liked properties: $e');
    }
  }

  void _loadMockPassedProperties() {
    try {
      DebugLogger.warning('🎭 Loading mock passed properties for demo mode');

      // Create some mock passed properties
      final mockPassedProperties = [
        PropertyModel(
          id: 2,
          title: 'Cozy Studio in Andheri',
          description: 'Perfect for single professionals',
          propertyType: PropertyType.room,
          purpose: PropertyPurpose.rent,
          basePrice: 25000.0,
          status: PropertyStatus.available,
          monthlyRent: 25000.0,
          bedrooms: 1,
          bathrooms: 1,
          areaSqft: 600,
          fullAddress: 'Andheri East, Mumbai',
          city: 'Mumbai',
          locality: 'Andheri',
          latitude: 19.1136,
          longitude: 72.8697,
          isAvailable: true,
          viewCount: 8,
          likeCount: 2,
          interestCount: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      passedProperties.assignAll(mockPassedProperties);
      passedState.value = LikesState.loaded;
      passedError.value = null;

      DebugLogger.success('✅ Loaded ${mockPassedProperties.length} mock passed properties');
    } catch (e) {
      DebugLogger.error('❌ Failed to load mock passed properties: $e');
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