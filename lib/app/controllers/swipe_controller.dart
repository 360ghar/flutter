import 'package:get/get.dart';
import '../data/models/property_model.dart';
import '../data/models/property_card_model.dart';
import '../data/providers/api_service.dart';
import '../utils/debug_logger.dart';
import '../utils/reactive_state_monitor.dart';
import 'property_controller.dart';
import 'auth_controller.dart';

class SwipeController extends GetxController {
  final PropertyController _propertyController = Get.find<PropertyController>();
  late final ApiService _apiService;
  late final AuthController _authController;
  
  final RxList<PropertyCardModel> currentStack = <PropertyCardModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool canUndo = false.obs;
  final RxMap<String, dynamic> swipeStats = <String, dynamic>{}.obs;
  
  // Track interaction timing
  DateTime? _cardViewStartTime;
  int _totalSwipes = 0;
  String? _lastSwipeId;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();
    
    // Setup monitoring for debugging
    ReactiveStateMonitor.monitorRxList(currentStack, 'SwipeController.currentStack');
    ReactiveStateMonitor.monitorRxBool(isLoading, 'SwipeController.isLoading');
    
    _loadInitialStack();
    _loadSwipeStats();
  }

  Future<void> _loadInitialStack() async {
    isLoading.value = true;
    
    try {
      DebugLogger.info('🔍 Loading initial swipe stack...');
      
      if (_authController.isAuthenticated) {
        // Load fresh properties for discovery
        await _propertyController.fetchDiscoverProperties(limit: 20);
        currentStack.assignAll(_propertyController.discoverProperties);
        
        DebugLogger.success('✅ Swipe stack loaded from API: ${currentStack.length} properties');
        DebugLogger.info('📊 Current stack sample: ${currentStack.take(3).map((p) => 'ID:${p.id} "${p.title}"').join(", ")}');
        DebugLogger.info('📊 Current index: ${currentIndex.value}');
        DebugLogger.info('📊 Visible cards count: ${visibleCards.length}');
      } else {
        DebugLogger.warning('⚠️ User not authenticated, using local properties');
        // Fallback to existing properties
        final allProperties = _propertyController.properties;
        final filteredProperties = _applyFilters(allProperties);
        
        final availableProperties = filteredProperties
            .where((property) => 
                !_propertyController.isFavourite(property.id) && 
                !_propertyController.isPassed(property.id))
            .toList();
        
        currentStack.assignAll(availableProperties.take(10).toList());
        
        DebugLogger.info('📱 Swipe stack loaded from local: ${currentStack.length} properties');
      }
      
      currentIndex.value = 0;
      _startCardViewTimer();
      
      // Track stack load analytics
      if (_authController.isAuthenticated) {
        await _apiService.trackEvent('swipe_stack_loaded', {
          'stack_size': currentStack.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
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
      
      final stats = await _apiService.getSwipeStats();
      swipeStats.value = stats;
      
      DebugLogger.success('✅ Swipe stats loaded: ${stats.length} entries');
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

  Future<void> swipeLeft(PropertyCardModel property) async {
    DebugLogger.info('👈 Swiping left on property: ${property.id} (${property.title})');
    await _recordSwipe(property, false, 'left');
    _nextProperty();
  }

  Future<void> swipeRight(PropertyCardModel property) async {
    DebugLogger.info('👉 Swiping right on property: ${property.id} (${property.title})');
    await _recordSwipe(property, true, 'right');
    _nextProperty();
  }

  Future<void> swipeUp(PropertyCardModel property) async {
    DebugLogger.info('👆 Swiping up on property: ${property.id} (${property.title})');
    // Navigate to property details
    Get.toNamed('/property-details', arguments: property);
    
    // Track swipe up analytics
    if (_authController.isAuthenticated) {
      await _apiService.trackEvent('property_swipe_up', {
        'property_id': property.id,
        'interaction_time': _getInteractionTime(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _recordSwipe(PropertyCardModel property, bool isLiked, String direction) async {
    try {
      final interactionTime = _getInteractionTime();
      
      if (_authController.isAuthenticated) {
        DebugLogger.info('📝 Recording swipe in backend...');
        
        await _apiService.trackSwipeAction(
          propertyId: property.id,
          isLiked: isLiked,
          swipeDirection: direction,
          interactionTimeSeconds: interactionTime,
          additionalData: {
            'property_title': property.title,
            'property_type': property.propertyTypeString,
            'base_price': property.basePrice,
          },
        );
        
        DebugLogger.success('✅ Swipe recorded in backend');
        
        // Enable undo functionality
        canUndo.value = true;
        _lastSwipeId = property.id.toString();
        
        // Track additional analytics
        await _apiService.trackEvent('property_swipe', {
          'property_id': property.id,
          'is_liked': isLiked,
          'direction': direction,
          'interaction_time_seconds': interactionTime,
          'total_swipes_in_session': _totalSwipes + 1,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        DebugLogger.warning('⚠️ User not authenticated, recording locally');
      }
      
      // Update local state
      if (isLiked) {
        await _propertyController.addToFavourites(property.id);
        DebugLogger.info('❤️ Added to favorites: ${property.title}');
      } else {
        await _propertyController.addToPassedProperties(property.id);
        DebugLogger.info('👎 Added to passed: ${property.title}');
      }
      
      _totalSwipes++;
      
    } catch (e) {
      DebugLogger.error('❌ Error recording swipe: $e');
      
      // Still update local state even if API fails
      if (isLiked) {
        await _propertyController.addToFavourites(property.id);
      } else {
        await _propertyController.addToPassedProperties(property.id);
      }
      
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
      
      await _propertyController.fetchDiscoverProperties(limit: 10);
      final newProperties = _propertyController.discoverProperties
          .where((property) => 
              !currentStack.any((existing) => existing.id == property.id) &&
              !_propertyController.isFavourite(property.id) && 
              !_propertyController.isPassed(property.id))
          .toList();
      
      currentStack.addAll(newProperties);
      
      DebugLogger.success('✅ Added ${newProperties.length} new properties to stack');
      
      // Track analytics
      await _apiService.trackEvent('swipe_stack_extended', {
        'new_properties_count': newProperties.length,
        'total_stack_size': currentStack.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      DebugLogger.error('❌ Error loading more properties: $e');
    }
  }

  Future<void> undoLastSwipe() async {
    if (!canUndo.value || _lastSwipeId == null) {
      DebugLogger.warning('⚠️ Cannot undo: no recent swipe or undo not available');
      return;
    }
    
    if (!_authController.isAuthenticated) {
      DebugLogger.warning('⚠️ Cannot undo: user not authenticated');
      Get.snackbar(
        'Authentication Required',
        'Please log in to undo swipes',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    try {
      DebugLogger.info('🔄 Undoing last swipe...');
      
      await _apiService.undoLastSwipe();
      
      // Reset the current index to show the previous card
      if (currentIndex.value > 0) {
        currentIndex.value--;
      }
      
      // Remove from local favorites/passed lists
      await _propertyController.removeFromFavourites(_lastSwipeId!);
      await _propertyController.removeFromPassedProperties(_lastSwipeId!);
      
      canUndo.value = false;
      _lastSwipeId = null;
      _totalSwipes = _totalSwipes > 0 ? _totalSwipes - 1 : 0;
      
      DebugLogger.success('✅ Swipe undone successfully');
      
      // Track undo analytics
      await _apiService.trackEvent('swipe_undo', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      Get.snackbar(
        'Undo Successful',
        'Last swipe has been undone',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      DebugLogger.error('❌ Error undoing swipe: $e');
      Get.snackbar(
        'Error',
        'Failed to undo swipe. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> refreshSwipeStats() async {
    await _loadSwipeStats();
  }

  List<PropertyCardModel> get visibleCards {
    final List<PropertyCardModel> cards = [];
    for (int i = currentIndex.value; i < currentIndex.value + 3 && i < currentStack.length; i++) {
      cards.add(currentStack[i]);
    }
    DebugLogger.info('📊 visibleCards getter called: index=${currentIndex.value}, stackSize=${currentStack.length}, visibleCount=${cards.length}');
    return cards;
  }

  void resetStack() {
    DebugLogger.info('🔄 Resetting swipe stack...');
    currentIndex.value = 0;
    canUndo.value = false;
    _lastSwipeId = null;
    _totalSwipes = 0;
    _loadInitialStack();
  }

  List<PropertyCardModel> _applyFilters(List<PropertyCardModel> properties) {
    return properties.where((property) {
      // Purpose filter
      if (!_matchesPurpose(property)) {
        return false;
      }

      // Price filter (adjusted based on purpose)
      final adjustedPrice = _getAdjustedPrice(property);
      if (adjustedPrice < _propertyController.minPrice.value || 
          adjustedPrice > _propertyController.maxPrice.value) {
        return false;
      }

      // Bedrooms filter (skip for Stay mode)
      if (_propertyController.selectedPurpose.value != 'Stay') {
        if (property.bedrooms != null && (property.bedrooms! < _propertyController.minBedrooms.value || 
            property.bedrooms! > _propertyController.maxBedrooms.value)) {
          return false;
        }
      }

      // Property type filter
      if (_propertyController.propertyType.value != 'All' && 
          !_matchesPropertyType(property)) {
        return false;
      }

      // Note: PropertyCardModel doesn't include amenities for performance
      // Amenities filtering should be done at API level

      return true;
    }).toList();
  }

  bool _matchesPurpose(PropertyCardModel property) {
    switch (_propertyController.selectedPurpose.value) {
      case 'Stay':
        return property.purpose == PropertyPurpose.shortStay ||
               property.propertyType == PropertyType.apartment ||
               property.basePrice < 5000000;
      case 'Rent':
        return property.purpose == PropertyPurpose.rent || property.purpose == PropertyPurpose.shortStay;
      case 'Buy':
      default:
        return property.purpose == PropertyPurpose.buy;
    }
  }

  double _getAdjustedPrice(PropertyCardModel property) {
    switch (_propertyController.selectedPurpose.value) {
      case 'Stay':
        return property.basePrice / 30; // Daily rate approximation
      case 'Rent':
        return property.basePrice / 100; // Monthly rent approximation
      case 'Buy':
      default:
        return property.basePrice;
    }
  }

  bool _matchesPropertyType(PropertyCardModel property) {
    final selectedType = _propertyController.propertyType.value;
    
    if (_propertyController.selectedPurpose.value == 'Stay') {
      // For Stay mode, map property types differently
      switch (selectedType) {
        case 'Hotel':
          return property.propertyType == PropertyType.apartment ||
                 property.propertyType == PropertyType.room;
        case 'Resort':
          return property.propertyType == PropertyType.house ||
                 property.propertyType == PropertyType.builderFloor;
        default:
          return property.propertyTypeString == selectedType;
      }
    }
    
    return property.propertyTypeString == selectedType;
  }

  // Getters for UI
  bool get hasMoreCards => currentIndex.value < currentStack.length;
  PropertyCardModel? get currentCard => hasMoreCards ? currentStack[currentIndex.value] : null;
  int get remainingCards => currentStack.length - currentIndex.value;
  int get totalSwipesInSession => _totalSwipes;
  
  // Stats getters
  int get totalLikes => swipeStats['total_likes'] ?? 0;
  int get totalPasses => swipeStats['total_passes'] ?? 0;
  int get totalSwipes => swipeStats['total_swipes'] ?? 0;
  double get likeRate => totalSwipes > 0 ? (totalLikes / totalSwipes) * 100 : 0.0;

  // Helper method to convert PropertyModel to PropertyCardModel
  PropertyCardModel _convertToPropertyCard(PropertyModel property) {
    return PropertyCardModel(
      id: int.tryParse(property.id.toString()) ?? 0,
      title: property.title,
      propertyType: property.propertyType,
      purpose: property.purpose,
      basePrice: property.basePrice,
      areaSqft: property.areaSqft,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      mainImageUrl: property.images?.isNotEmpty == true ? property.images!.first.imageUrl : null,
      virtualTourUrl: property.virtualTourUrl,
      city: property.city,
      state: property.state,
      locality: property.locality,
      pincode: property.pincode,
      fullAddress: property.fullAddress,
      distanceKm: null, // Will be calculated based on user location if needed
      likeCount: 0, // Default value
    );
  }
} 