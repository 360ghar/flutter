import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/unified_property_response.dart';
import '../../../core/data/repositories/properties_repository.dart';
import '../../../core/data/repositories/swipes_repository.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/utils/app_colors.dart';
import '../../likes/controllers/likes_controller.dart';

enum DiscoverState {
  initial,
  loading,
  loaded,
  empty,
  error,
  prefetching,
}

class DiscoverController extends GetxController {
  final PropertiesRepository _propertiesRepository = Get.find<PropertiesRepository>();
  final SwipesRepository _swipesRepository = Get.find<SwipesRepository>();
  final FilterService _filterService = Get.find<FilterService>();
  final LocationController _locationController = Get.find<LocationController>();
  final AuthController _authController = Get.find<AuthController>();

  // Reactive state
  final Rx<DiscoverState> state = DiscoverState.initial.obs;
  final RxList<PropertyModel> deck = <PropertyModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxnString error = RxnString();

  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;
  static const int _limit = 20;
  static const int _prefetchThreshold = 3;

  // Swipe tracking
  final RxInt totalSwipesInSession = 0.obs;
  final RxInt likesInSession = 0.obs;
  final RxInt passesInSession = 0.obs;

  // Loading states
  final RxBool isPrefetching = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupFilterListener();
    _loadInitialDeck();
  }

  void _setupFilterListener() {
    // Listen to filter changes and reload deck
    debounce(_filterService.currentFilter, (_) {
      _resetAndLoadDeck();
    }, time: const Duration(milliseconds: 500));
  }

  Future<void> _loadInitialDeck() async {
    if (state.value == DiscoverState.loading) return;

    try {
      state.value = DiscoverState.loading;
      error.value = null;

      await _loadMoreProperties();

      if (deck.isEmpty) {
        state.value = DiscoverState.empty;
      } else {
        state.value = DiscoverState.loaded;
        currentIndex.value = 0;
      }
    } catch (e) {
      DebugLogger.error('❌ Failed to load initial deck: $e');
      state.value = DiscoverState.error;

      // Provide more user-friendly error messages
      if (e.toString().contains('404') || e.toString().contains('request not found')) {
        error.value = 'Backend server is not running or API endpoints are incorrect. Please check your backend configuration.';
      } else if (e.toString().contains('Connection refused') || e.toString().contains('Failed host lookup')) {
        error.value = 'Unable to connect to the server. Please make sure your backend server is running.';
      } else if (e.toString().contains('timeout')) {
        error.value = 'Request timed out. The server might be overloaded or unreachable.';
      } else {
        error.value = 'Failed to load properties. Please check your connection and try again.';
      }
    }
  }

  Future<void> _loadMoreProperties() async {
    if (!_hasMore) {
      DebugLogger.api('📚 No more properties to load (page $_currentPage/$_totalPages)');
      return;
    }

    try {
      DebugLogger.api('📚 Loading more properties: page $_currentPage');

      final response = await _propertiesRepository.getProperties(
        filters: _filterService.currentFilter.value,
        page: _currentPage,
        limit: _limit,
        useCache: true,
      );

      _updatePaginationInfo(response);
      
      // Add new properties to deck (avoiding duplicates)
      final newProperties = response.properties.where((newProp) {
        return !deck.any((existingProp) => existingProp.id == newProp.id);
      }).toList();

      deck.addAll(newProperties);
      DebugLogger.success('✅ Added ${newProperties.length} new properties to deck (total: ${deck.length})');

    } catch (e) {
      DebugLogger.error('❌ Failed to load more properties: $e');
      rethrow;
    }
  }

  void _updatePaginationInfo(UnifiedPropertyResponse response) {
    _currentPage++;
    _totalPages = response.totalPages;
    _hasMore = response.hasMore;
    
    DebugLogger.api('📊 Pagination updated: page $_currentPage/$_totalPages, hasMore: $_hasMore');
  }

  // Swipe actions
  Future<void> swipeRight(PropertyModel property) async {
    await _handleSwipe(property, true);
    _recordSwipeStats(true);
    
    // Show feedback to user
    Get.snackbar(
      '❤️ Liked!',
      '${property.title} added to your favorites',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  Future<void> swipeLeft(PropertyModel property) async {
    await _handleSwipe(property, false);
    _recordSwipeStats(false);
    
    // Show feedback to user
    Get.snackbar(
      '👈 Passed',
      '${property.title} added to passed properties',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.grey.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  Future<void> _handleSwipe(PropertyModel property, bool isLiked) async {
    try {
      DebugLogger.api('👆 Swiping ${isLiked ? 'RIGHT (LIKE)' : 'LEFT (PASS)'}: ${property.title}');

      // Optimistic update - move to next card immediately
      _moveToNextCard();

      // Record swipe in background
      _recordSwipeAsync(property.id, isLiked);

      // Notify LikesController for both likes and passes
      _notifyLikesController(isLiked);

      // Check if we need to prefetch more properties
      _checkForPrefetch();

    } catch (e) {
      DebugLogger.error('❌ Failed to handle swipe: $e');
      // Could implement rollback logic here if needed
    }
  }

  void _notifyLikesController(bool isLiked) {
    try {
      // Wait a bit longer to ensure the swipe is fully recorded before refreshing
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          if (Get.isRegistered<LikesController>()) {
            final likesController = Get.find<LikesController>();
            // Refresh both liked and passed properties to ensure sync
            likesController.refreshAll();
            DebugLogger.api('🔄 Notified LikesController to refresh all properties');

            // Also update the current segment if user is viewing likes
            if (likesController.currentSegment.value == LikesSegment.liked && isLiked) {
              likesController.refreshLiked();
            } else if (likesController.currentSegment.value == LikesSegment.passed && !isLiked) {
              likesController.refreshPassed();
            }
          } else {
            DebugLogger.api('ℹ️ LikesController not yet registered, will refresh when accessed');
          }
        } catch (e) {
          DebugLogger.warning('⚠️ Could not notify LikesController: $e');
        }
      });
    } catch (e) {
      DebugLogger.warning('⚠️ Error setting up LikesController notification: $e');
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
    // Check if user is authenticated
    if (!_authController.isAuthenticated) {
      DebugLogger.warning('⚠️ User not authenticated, cannot record swipe');
      Get.snackbar(
        'Authentication Required',
        'Please log in to save your preferences',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Get current location for swipe recording
    final currentLat = _locationController.currentLatitude;
    final currentLng = _locationController.currentLongitude;
    
    DebugLogger.api('📍 Recording swipe with auth: ${_authController.isAuthenticated}, location: $currentLat, $currentLng');
    
    // Record swipe asynchronously without blocking UI
    _swipesRepository.recordSwipe(
      propertyId: propertyId,
      isLiked: isLiked,
      userLocationLat: currentLat,
      userLocationLng: currentLng,
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
    ).then((_) {
      DebugLogger.success('✅ Swipe recorded successfully for property $propertyId with location and auth');
    }).catchError((e) {
      DebugLogger.error('❌ Failed to record swipe for property $propertyId: $e');
      // Show error to user
      Get.snackbar(
        'Error',
        'Failed to save your preference. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    });
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
    }
  }

  // Reset and reload deck (when filters change)
  Future<void> _resetAndLoadDeck() async {
    DebugLogger.api('🔄 Resetting deck due to filter change');
    
    deck.clear();
    currentIndex.value = 0;
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    
    await _loadInitialDeck();
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

  // Get current visible cards for swipe stack (current + next 2)
  List<PropertyModel> get visibleCards {
    final start = currentIndex.value;
    final end = (start + 3).clamp(0, deck.length);
    return deck.sublist(start, end);
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
  void showNearbyProperties() {
    _filterService.setCurrentLocation();
  }

  void filterByPropertyType(String type) {
    _filterService.updatePropertyTypes([type]);
  }

  void filterByPurpose(String purpose) {
    _filterService.updatePurpose(purpose);
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

  // Helper getters
  bool get isLoading => state.value == DiscoverState.loading;
  bool get isEmpty => state.value == DiscoverState.empty;
  bool get hasError => state.value == DiscoverState.error;
  bool get isLoaded => state.value == DiscoverState.loaded;
  bool get hasProperties => deck.isNotEmpty;
  bool get canSwipe => hasProperties && currentProperty != null;
}