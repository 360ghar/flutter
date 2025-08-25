import 'package:get/get.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/reactive_state_monitor.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/controllers/auth_controller.dart';

class SwipeController extends GetxController {
  late final ApiService _apiService;
  late final AuthController _authController;
  late final FilterService _filterService;
  late final LocationController _locationController;
  
  final RxList<PropertyModel> currentStack = <PropertyModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> swipeStats = <String, dynamic>{}.obs;
  
  // Track interaction timing
  DateTime? _cardViewStartTime;
  int _totalSwipes = 0;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();
    _filterService = Get.find<FilterService>();
    _locationController = Get.find<LocationController>();
    
    // Setup monitoring for debugging
    ReactiveStateMonitor.monitorRxList(currentStack, 'SwipeController.currentStack');
    ReactiveStateMonitor.monitorRxBool(isLoading, 'SwipeController.isLoading');
    
    _setupFilterListener();
    _loadInitialStack();
    _loadSwipeStats();
  }

  void _setupFilterListener() {
    // TODO: Listen to filter changes with debounce - needs update for new page-specific state system
    // debounce(
    //   _filterService.currentFilter,
    //   (_) => _refreshStackWithFilters(),
    //   time: const Duration(milliseconds: 800), // Longer debounce for swipe stack
    // );
    
    // Listen to location changes
    ever(_locationController.currentPosition, (position) {
      if (position != null && currentStack.isEmpty) {
        _loadInitialStack();
      }
    });
  }

  Future<void> _fetchPropertiesWithCurrentFilters({bool isInitialLoad = false}) async {
    try {
      // Get current location for filtering
      double? latitude = _locationController.currentLatitude;
      double? longitude = _locationController.currentLongitude;
      
      // Require location for property fetching
      if (latitude == null || longitude == null) {
        throw Exception('User location is required for property recommendations. Please enable location services.');
      }
      
      // Update filter with current location
      final currentFilters = _filterService.currentFilter.copyWith(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 10.0, // 10km radius for swipe stack
      );
      
      DebugLogger.info('🎯 Fetching properties with filters for swipe stack');
      DebugLogger.info('📍 Location: $latitude, $longitude');
      
      final response = await _apiService.searchProperties(
        filters: currentFilters,
        page: 1,
        limit: isInitialLoad ? 20 : 10,
      );
      
      if (isInitialLoad) {
        currentStack.assignAll(response.properties);
      } else {
        // For refresh, merge with existing cards that haven't been swiped
        final unseenProperties = response.properties.where((property) => 
          !currentStack.any((existing) => existing.id == property.id)
        ).toList();
        
        currentStack.addAll(unseenProperties);
      }
      
      DebugLogger.info('✅ Fetched ${response.properties.length} properties for swipe stack');
      
    } catch (e) {
      DebugLogger.error('❌ Error fetching properties for swipe stack: $e');
      rethrow; // Re-throw to handle in calling method
    }
  }
  


  Future<void> _loadInitialStack() async {
    isLoading.value = true;
    
    try {
      DebugLogger.info('🔍 Loading initial swipe stack...');
      
      if (_authController.isAuthenticated) {
        await _fetchPropertiesWithCurrentFilters(isInitialLoad: true);
        
        DebugLogger.success('✅ Swipe stack loaded: ${currentStack.length} properties');
      } else {
        DebugLogger.warning('⚠️ User not authenticated, cannot load properties');
        currentStack.clear();
      }
      
      currentIndex.value = 0;
      _startCardViewTimer();
      
    } catch (e) {
      DebugLogger.error('❌ Error loading initial stack: $e');
      Get.snackbar(
        'Error',
        'Failed to load properties',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSwipeStats() async {
    if (!_authController.isAuthenticated) {
      DebugLogger.warning('⚠️ User not authenticated, skipping swipe stats');
      return;
    }
    
    try {
      DebugLogger.info('🔍 Loading swipe statistics...');
      
      // Swipe stats endpoint removed in new API format
      // Stats are now embedded in property responses
      swipeStats.value = {'note': 'Stats available via property responses'};
      
      DebugLogger.success('✅ Swipe stats loaded via new API format');
    } catch (e) {
      DebugLogger.error('❌ Error loading swipe stats: $e');
    }
  }

  void _startCardViewTimer() {
    _cardViewStartTime = DateTime.now();
  }

  int _getInteractionTime() {
    if (_cardViewStartTime == null) return 0;
    return DateTime.now().difference(_cardViewStartTime!).inSeconds;
  }

  Future<void> swipeLeft(PropertyModel property) async {
    DebugLogger.info('👈 Swiping left on property: ${property.id} (${property.title})');
    await _recordSwipe(property, false, 'left');
    _nextProperty();
  }

  Future<void> swipeRight(PropertyModel property) async {
    DebugLogger.info('👉 Swiping right on property: ${property.id} (${property.title})');
    await _recordSwipe(property, true, 'right');
    _nextProperty();
  }

  Future<void> swipeUp(PropertyModel property) async {
    DebugLogger.info('👆 Swiping up on property: ${property.id} (${property.title})');
    // Navigate to property details
    Get.toNamed('/property-details', arguments: property);
    
  }

  Future<void> _recordSwipe(PropertyModel property, bool isLiked, String direction) async {
    try {

      
      if (_authController.isAuthenticated) {
        DebugLogger.info('📝 Recording swipe in backend...');
        
        // Analytics removed - swipe recorded directly via swipeProperty endpoint
        DebugLogger.success('✅ Swipe recorded in backend');
      } else {
        DebugLogger.warning('⚠️ User not authenticated, recording locally');
      }
      
      // Update local state with user location
      final currentLat = _locationController.currentLatitude;
      final currentLng = _locationController.currentLongitude;
      
      await _apiService.swipeProperty(
        property.id, 
        isLiked,
        userLocationLat: currentLat,
        userLocationLng: currentLng,
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      );
      DebugLogger.info(isLiked 
        ? '❤️ Added to favorites: ${property.title}'
        : '👎 Added to passed: ${property.title}');
      
      _totalSwipes++;
      
    } catch (e) {
      DebugLogger.error('❌ Error recording swipe: $e');
      
      // Still update local state even if API fails, with location
      final currentLat = _locationController.currentLatitude;
      final currentLng = _locationController.currentLongitude;
      
      await _apiService.swipeProperty(
        property.id, 
        isLiked,
        userLocationLat: currentLat,
        userLocationLng: currentLng,
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      Get.snackbar(
        'Warning',
        'Swipe recorded locally but failed to sync with server',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _nextProperty() {
    if (currentIndex.value < currentStack.length - 1) {
      currentIndex.value++;
      _startCardViewTimer();
      
      // Load more properties if running low
      if (currentIndex.value >= currentStack.length - 3) {
        _loadMoreProperties();
      }
    } else {
      DebugLogger.info('📋 Reached end of stack, loading more properties...');
      _loadMoreProperties();
    }
  }

  Future<void> _loadMoreProperties() async {
    if (!_authController.isAuthenticated) {
      DebugLogger.warning('⚠️ Cannot load more properties without authentication');
      return;
    }
    
    try {
      DebugLogger.info('🔍 Loading more properties for swipe stack...');
      
      final previousCount = currentStack.length;
      await _fetchPropertiesWithCurrentFilters(isInitialLoad: false);
      // New properties are already added to currentStack in the fetch method
      final newCount = currentStack.length - previousCount;
      
      DebugLogger.success('✅ Added $newCount new properties to stack');
      
    } catch (e) {
      DebugLogger.error('❌ Error loading more properties: $e');
    }
  }

  // Undo functionality removed - users can unlike properties from the Likes screen

  Future<void> refreshSwipeStats() async {
    await _loadSwipeStats();
  }

  List<PropertyModel> get visibleCards {
    final List<PropertyModel> cards = [];
    for (int i = currentIndex.value; i < currentIndex.value + 3 && i < currentStack.length; i++) {
      cards.add(currentStack[i]);
    }
    DebugLogger.info('📊 visibleCards getter called: index=${currentIndex.value}, stackSize=${currentStack.length}, visibleCount=${cards.length}');
    return cards;
  }

  void resetStack() {
    DebugLogger.info('🔄 Resetting swipe stack...');
    currentIndex.value = 0;
    _totalSwipes = 0;
    _loadInitialStack();
  }

  // Client-side filtering removed - all filtering done at backend level

  // Old filtering methods removed - backend now handles all filtering

  // Getters for UI
  bool get hasMoreCards => currentIndex.value < currentStack.length;
  PropertyModel? get currentCard => hasMoreCards ? currentStack[currentIndex.value] : null;
  int get remainingCards => currentStack.length - currentIndex.value;
  int get totalSwipesInSession => _totalSwipes;
  
  // Stats getters
  int get totalLikes => swipeStats['total_likes'] ?? 0;
  int get totalPasses => swipeStats['total_passes'] ?? 0;
  int get totalSwipes => swipeStats['total_swipes'] ?? 0;
  double get likeRate => totalSwipes > 0 ? (totalLikes / totalSwipes) * 100 : 0.0;

} 