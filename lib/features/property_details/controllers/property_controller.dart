import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/models/unified_filter_model.dart';

import '../../../core/data/providers/api_service.dart';
import '../../../core/data/repositories/swipes_repository.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/location_controller.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/reactive_state_monitor.dart';

class PropertyController extends GetxController {
  late final ApiService _apiService;
  late final SwipesRepository _swipesRepository;
  late final AuthController _authController;
  late final LocationController _locationController;
  late final FilterService _filterService;
  
  final RxList<PropertyModel> properties = <PropertyModel>[].obs;
  final RxList<PropertyModel> discoverProperties = <PropertyModel>[].obs;
  final RxList<PropertyModel> nearbyProperties = <PropertyModel>[].obs;
  final RxList<PropertyModel> recommendedProperties = <PropertyModel>[].obs;
  final RxList<PropertyModel> favouriteProperties = <PropertyModel>[].obs;
  final RxList<PropertyModel> passedProperties = <PropertyModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingDiscover = false.obs;
  final RxBool isLoadingNearby = false.obs;
  final RxBool isLoadingMoreDiscover = false.obs;
  final RxBool isLoadingMoreNearby = false.obs;
  final RxString error = ''.obs;
  
  // Pagination state
  final RxInt currentDiscoverPage = 1.obs;
  final RxInt currentNearbyPage = 1.obs;
  final RxBool hasMoreDiscoverProperties = true.obs;
  final RxBool hasMoreNearbyProperties = true.obs;
  
  // Legacy filter properties - kept for backward compatibility
  final RxMap<String, dynamic> filters = <String, dynamic>{}.obs;

  PropertyController();

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _swipesRepository = Get.find<SwipesRepository>();
    _authController = Get.find<AuthController>();
    _locationController = Get.find<LocationController>();
    _filterService = Get.find<FilterService>();
    
    // Setup reactive state monitoring for debugging
    ReactiveStateMonitor.monitorPropertyController(this, 'PropertyController');
    
    // Listen to authentication state changes
    ever(_authController.isLoggedIn, (isLoggedIn) {
      if (isLoggedIn) {
        // User is logged in, safe to fetch data
        _initializeController();
      } else {
        // User logged out, clear all data
        _clearAllData();
      }
    });
    
    // Listen to filter changes for automatic refresh of favorites
    debounce(
      _filterService.currentFilter,
      (_) => _onFiltersChanged(),
      time: const Duration(milliseconds: 500),
    );
    
    // If already logged in, initialize immediately
    if (_authController.isLoggedIn.value) {
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    // Location is now handled by LocationController
    // Only load essential data on init - other data will be loaded lazily when needed
    // Note: Discover properties are now handled by DiscoverController to avoid duplicate requests
    DebugLogger.info('🏠 PropertyController initialized; discover properties handled by DiscoverController');
  }
  
  void _onFiltersChanged() {
    // React to filter changes - refresh favorites if they're loaded
    DebugLogger.info('🔄 Filters changed, refreshing favorites');
    if (favouriteProperties.isNotEmpty) {
      fetchFavouriteProperties(); // This will now apply current filters
    }
  }
  
  void _clearAllData() {
    properties.clear();
    discoverProperties.clear();
    nearbyProperties.clear();
    recommendedProperties.clear();
    favouriteProperties.clear();
    passedProperties.clear();
    error.value = '';
    
    // Reset pagination state
    currentDiscoverPage.value = 1;
    currentNearbyPage.value = 1;
    hasMoreDiscoverProperties.value = true;
    hasMoreNearbyProperties.value = true;
  }

  // Helper method to get current location from LocationController
  Future<Position> _getCurrentLocationSync() async {
    if (_locationController.hasLocation) {
      return _locationController.currentPosition.value!;
    }
    
    // Try to get current location
    await _locationController.getCurrentLocation();
    
    final position = _locationController.currentPosition.value;
    if (position == null) {
      throw Exception('User location is required but not available. Please enable location services.');
    }
    return position;
  }

  // API integration methods
  Future<void> fetchDiscoverProperties({int limit = 10, bool loadMore = false}) async {
    // DISABLED: This method has been disabled to prevent duplicate API requests.
    // Discover properties are now handled exclusively by DiscoverController.
    DebugLogger.info('⚠️ fetchDiscoverProperties called but disabled; use DiscoverController instead');
    return;
  }

  Future<void> fetchNearbyProperties({
    double radiusKm = 10,
    int limit = 20,
    bool loadMore = false,
  }) async {
    if (!_locationController.hasLocation) {
      DebugLogger.warning('⚠️ No user position available for nearby properties');
      return;
    }
    
    
    try {
      if (loadMore) {
        if (!hasMoreNearbyProperties.value || isLoadingMoreNearby.value) return;
        isLoadingMoreNearby.value = true;
      } else {
        isLoadingNearby.value = true;
        currentNearbyPage.value = 1;
        hasMoreNearbyProperties.value = true;
      }
      
      DebugLogger.info('🔍 Fetching nearby properties: page=${loadMore ? currentNearbyPage.value : 1}, radiusKm=$radiusKm, loadMore=$loadMore');
      
      final response = await _apiService.searchProperties(
        filters: UnifiedFilterModel(
          latitude: _locationController.currentLatitude!,
          longitude: _locationController.currentLongitude!,
          radiusKm: radiusKm,
          sortBy: null,
        ),
        page: loadMore ? currentNearbyPage.value : 1,
        limit: limit,
      );
      
      if (loadMore) {
        nearbyProperties.addAll(response.properties);
        currentNearbyPage.value++;
      } else {
        nearbyProperties.assignAll(response.properties);
        currentNearbyPage.value = 2;
      }
      
      hasMoreNearbyProperties.value = response.hasMore;
      
      DebugLogger.success('✅ Nearby properties loaded: ${response.properties.length} items');
      
    } catch (e) {
      DebugLogger.error('❌ Error fetching nearby properties: $e');
      Get.snackbar(
        'Error',
        'Failed to load nearby properties',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (loadMore) {
        isLoadingMoreNearby.value = false;
      } else {
        isLoadingNearby.value = false;
      }
    }
  }

  Future<void> fetchRecommendedProperties({int limit = 10}) async {
    try {
      DebugLogger.info('🔍 Fetching recommended properties with limit: $limit');
      
      // Recommendations endpoint removed - use regular search instead
      final filters = _filterService.currentFilter.value.copyWith(
        latitude: _locationController.currentLatitude,
        longitude: _locationController.currentLongitude,
        radiusKm: 10.0,
      );
      
      final response = await _apiService.searchProperties(
        filters: filters,
        limit: limit,
        page: 1,
      );
      final result = response.properties;
      recommendedProperties.assignAll(result);
      
      DebugLogger.success('✅ Recommended properties loaded: ${result.length} items');
      
    } catch (e) {
      DebugLogger.error('❌ Error fetching recommended properties: $e');
    }
  }

  Future<void> searchPropertiesWithFilters(Map<String, dynamic> searchFilters) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      DebugLogger.info('🔍 Searching properties with filters: $searchFilters');
      
      if (_authController.isAuthenticated) {
        // Get user location for API call
        final userLocation = await _getCurrentLocationSync();
        final filterModel = UnifiedFilterModel.fromJson(searchFilters);
        final response = await _apiService.searchProperties(
          filters: filterModel.copyWith(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude,
          ),
        );
        properties.assignAll(response.properties);
        
        DebugLogger.success('✅ Property search completed: ${response.properties.length} results');
        
        // Analytics tracking removed
      } else {
        DebugLogger.error('⚠️ User not authenticated, cannot search properties');
        throw Exception('Authentication required to search properties');
      }
    } catch (e) {
      error.value = e.toString();
      DebugLogger.error('❌ Error searching properties: $e');
      Get.snackbar(
        'Search Error',
        'Failed to search properties. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<PropertyModel?> getPropertyDetails(String propertyId) async {
    try {
      DebugLogger.info('🔍 Fetching property details for ID: $propertyId');
      
      if (_authController.isAuthenticated) {
        final property = await _apiService.getPropertyDetails(int.parse(propertyId));
        
        DebugLogger.success('✅ Property details loaded: ${property.title}');
        
        // Analytics tracking removed
        
        return property;
      } else {
        DebugLogger.error('⚠️ User not authenticated, cannot fetch property details');
        throw Exception('Authentication required to fetch property details');
      }
    } catch (e) {
      DebugLogger.error('❌ Error fetching property details: $e');
      Get.snackbar(
        'Error',
        'Failed to load property details',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    }
  }

  Future<void> checkPropertyAvailability(
    String propertyId, {
    String? checkInDate,
    String? checkOutDate,
    int? guests,
  }) async {
    
    try {
      DebugLogger.info('🔍 Checking availability for property: $propertyId');
      
      // Availability endpoint removed - show message to user
      DebugLogger.info('🔍 Availability check endpoint removed');
      
      Get.snackbar(
        'Feature Unavailable',
        'Availability checking is currently unavailable. Please contact the agent for availability information.',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      DebugLogger.error('❌ Error checking property availability: $e');
      Get.snackbar(
        'Error',
        'Failed to check availability',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> showPropertyInterest(
    String propertyId, {
    String interestType = 'visit',
    String? message,
    String? preferredTime,
  }) async {
    try {
      DebugLogger.info('🔍 Showing interest in property: $propertyId');
      
      // Property interest endpoint removed - show message to user
      DebugLogger.info('🔍 Property interest endpoint removed');
      
      Get.snackbar(
        'Feature Unavailable',
        'Interest recording is currently unavailable. Please contact the agent directly.',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      DebugLogger.error('❌ Error showing property interest: $e');
      Get.snackbar(
        'Error',
        'Failed to record interest. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  Future<void> fetchProperties() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      if (_authController.isAuthenticated) {
        // Use API service for authenticated users with user location
        final userLocation = await _getCurrentLocationSync();
        final response = await _apiService.searchProperties(
          filters: UnifiedFilterModel(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude,
            radiusKm: 10,
            sortBy: null,
          ),
        );
        properties.assignAll(response.properties);
        DebugLogger.success('✅ Properties loaded from API: ${response.properties.length} items');
      } else {
        DebugLogger.error('⚠️ User not authenticated, cannot fetch properties');
        throw Exception('Authentication required to fetch properties');
      }
    } catch (e) {
      error.value = e.toString();
      DebugLogger.error('❌ Error fetching properties: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Lazy loading methods
  Future<void> loadMoreDiscoverProperties() async {
    // DISABLED: Discover properties are handled by DiscoverController
    DebugLogger.info('⚠️ loadMoreDiscoverProperties called but disabled; use DiscoverController instead');
    return;
  }

  Future<void> loadMoreNearbyProperties() async {
    await fetchNearbyProperties(loadMore: true);
  }

  // Lazy loading data methods - only fetch when actually needed
  Future<void> fetchFavouritePropertiesLazy() async {
    if (favouriteProperties.isNotEmpty) return; // Already loaded
    await fetchFavouriteProperties();
  }

  Future<void> fetchPassedPropertiesLazy() async {
    if (passedProperties.isNotEmpty) return; // Already loaded
    await fetchPassedProperties();
  }

  Future<void> fetchRecommendedPropertiesLazy() async {
    if (recommendedProperties.isNotEmpty) return; // Already loaded
    await fetchRecommendedProperties();
  }

  Future<void> fetchFavouriteProperties() async {
    try {
      DebugLogger.info('🔍 Fetching favourite properties...');
      
      if (_authController.isAuthenticated) {
        // Get liked properties using SwipesRepository
        final likedProperties = await _swipesRepository.getLikedProperties(
          filters: _filterService.currentFilter.value,
          page: 1,
          limit: 50,
        );
        
        favouriteProperties.assignAll(likedProperties);
        DebugLogger.success('✅ Favourite properties loaded: ${likedProperties.length} items');
        
        // Analytics tracking removed
      } else {
        DebugLogger.error('⚠️ User not authenticated, cannot fetch favourite properties');
        throw Exception('Authentication required to fetch favourite properties');
      }
    } catch (e) {
      DebugLogger.error('❌ Error fetching favourites: $e');
      error.value = e.toString();
    }
  }

  Future<void> fetchPassedProperties() async {
    try {
      DebugLogger.info('🔍 Fetching passed (disliked) properties...');
      
      if (_authController.isAuthenticated) {
        // Get passed properties using SwipesRepository
        final passedPropertiesList = await _swipesRepository.getPassedProperties(
          filters: _filterService.currentFilter.value,
          page: 1,
          limit: 50,
        );
        
        passedProperties.assignAll(passedPropertiesList);
        DebugLogger.success('✅ Passed properties loaded: ${passedPropertiesList.length} items');
        
        // Analytics tracking removed
      } else {
        DebugLogger.error('⚠️ User not authenticated, cannot fetch passed properties');
        throw Exception('Authentication required to fetch passed properties');
      }
    } catch (e) {
      DebugLogger.error('❌ Error fetching passed properties: $e');
      error.value = e.toString();
    }
  }

  Future<void> addToFavourites(dynamic propertyId) async {
    try {
      await _apiService.swipeProperty(propertyId, true);
      await fetchFavouriteProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> removeFromFavourites(dynamic propertyId) async {
    try {
      // Analytics tracking removed
      await fetchFavouriteProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> addToPassedProperties(dynamic propertyId) async {
    try {
      await _apiService.swipeProperty(propertyId, false);
      await fetchPassedProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> removeFromPassedProperties(dynamic propertyId) async {
    try {
      // Analytics tracking removed
      await fetchPassedProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  bool isFavourite(dynamic propertyId) {
    final id = propertyId.toString();
    return favouriteProperties.any((property) => property.id.toString() == id);
  }

  bool isPassed(dynamic propertyId) {
    final id = propertyId.toString();
    return passedProperties.any((property) => property.id.toString() == id);
  }

  PropertyModel? getPropertyById(dynamic id) {
    try {
      final idString = id.toString();
      return properties.firstWhere((property) => property.id.toString() == idString);
    } catch (e) {
      return null;
    }
  }

  // Filter methods - now using FilterController with unified PropertyModel
  List<PropertyModel> getFilteredFavourites() {
    // Filtering is now done at the API level in fetchFavouriteProperties
    DebugLogger.info('📋 Returning ${favouriteProperties.length} favourite properties');
    return favouriteProperties;
  }

  List<PropertyModel> getFilteredPassed() {
    // Filtering can be added here if needed for passed properties
    return passedProperties;
  }

  // Legacy filter methods removed - use FilterService directly
} 