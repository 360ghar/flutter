import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/data/repositories/property_repository.dart';
import '../../../core/data/providers/api_service.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/location_controller.dart';
import '../../filters/controllers/filter_controller.dart';
import '../../../core/controllers/analytics_controller.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/reactive_state_monitor.dart';

class PropertyController extends GetxController {
  final PropertyRepository _repository;
  late final ApiService _apiService;
  late final AuthController _authController;
  late final LocationController _locationController;
  late final PropertyFilterController _filterController;
  late final AnalyticsController _analyticsController;
  
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

  PropertyController(this._repository);

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();
    _locationController = Get.find<LocationController>();
    _filterController = Get.find<PropertyFilterController>();
    _analyticsController = Get.find<AnalyticsController>();
    
    // Setup reactive state monitoring for debugging
    ReactiveStateMonitor.monitorPropertyController(this, 'PropertyController');
    
    // Listen to authentication state changes
    ever(_authController.isLoggedIn, (bool isLoggedIn) {
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
      _filterController.currentFilter,
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
    await fetchDiscoverProperties();
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
    try {
      if (loadMore) {
        if (!hasMoreDiscoverProperties.value || isLoadingMoreDiscover.value) return;
        isLoadingMoreDiscover.value = true;
      } else {
        isLoadingDiscover.value = true;
        currentDiscoverPage.value = 1;
        hasMoreDiscoverProperties.value = true;
      }
      error.value = '';
      
      DebugLogger.info('🔍 Fetching discover properties - Page: ${loadMore ? currentDiscoverPage.value : 1}, Limit: $limit, LoadMore: $loadMore');
      DebugLogger.info('📊 Current discover properties count: ${discoverProperties.length}');
      
      if (_authController.isAuthenticated) {
        // Get user location for API call
        final userLocation = await _getCurrentLocationSync();
        final result = await _apiService.discoverProperties(
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
          limit: limit,
          page: loadMore ? currentDiscoverPage.value : 1,
        );
        
        // Validate and filter out invalid properties before assignment
        final validProperties = result.properties.where((property) {
          final isValid = property.id > 0 && property.title.isNotEmpty;
          if (!isValid) {
            DebugLogger.warning('⚠️ Filtering out invalid property: ID=${property.id}, Title="${property.title}"');
          }
          return isValid;
        }).toList();
        
        if (loadMore) {
          discoverProperties.addAll(validProperties);
          currentDiscoverPage.value++;
          DebugLogger.info('📈 Added ${validProperties.length} more discover properties (Total: ${discoverProperties.length})');
        } else {
          discoverProperties.assignAll(validProperties);
          currentDiscoverPage.value = 2; // Next page to load
          DebugLogger.info('🔄 Replaced discover properties with ${validProperties.length} items');
        }
        
        hasMoreDiscoverProperties.value = result.hasMore;
        
        DebugLogger.success('✅ Discover properties loaded: ${validProperties.length} valid items out of ${result.properties.length} total');
        
        // Trigger reactive update by accessing the value
        final currentLength = discoverProperties.length;
        DebugLogger.info('📊 Reactive state updated - discoverProperties.length: $currentLength');
        
        // Track analytics
        await _apiService.trackEvent('properties_discovery_loaded', {
          'count': result.properties.length,
          'limit': limit,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        DebugLogger.error('⚠️ User not authenticated, cannot fetch properties');
        throw Exception('Authentication required to fetch discover properties');
      }
    } catch (e) {
      error.value = e.toString();
      DebugLogger.error('❌ Error fetching discover properties: $e');
      
      DebugLogger.error('💥 Failed to fetch discover properties: $e');
      Get.snackbar(
        'Error',
        'Failed to load properties. Please check your connection.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (loadMore) {
        isLoadingMoreDiscover.value = false;
      } else {
        isLoadingDiscover.value = false;
      }
    }
  }

  Future<void> fetchNearbyProperties({
    double radiusKm = 5,
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
      
      DebugLogger.info('🔍 Fetching nearby properties - Page: ${loadMore ? currentNearbyPage.value : 1}, Radius: ${radiusKm}km, LoadMore: $loadMore');
      
      final response = await _apiService.exploreProperties(
        latitude: _locationController.currentLatitude!,
        longitude: _locationController.currentLongitude!,
        radiusKm: radiusKm,
        limit: limit,
        page: loadMore ? currentNearbyPage.value : 1,
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
      
      // Track analytics
      await _apiService.trackEvent('nearby_properties_loaded', {
        'count': response.properties.length,
        'radius_km': radiusKm,
        'latitude': _locationController.currentLatitude!,
        'longitude': _locationController.currentLongitude!,
        'total_available': response.total,
        'timestamp': DateTime.now().toIso8601String(),
      });
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
      
      final result = await _apiService.getPropertyRecommendations(limit: limit);
      recommendedProperties.assignAll(result);
      
      DebugLogger.success('✅ Recommended properties loaded: ${result.length} items');
      
      // Track analytics
      await _apiService.trackEvent('recommended_properties_loaded', {
        'count': result.length,
        'limit': limit,
        'timestamp': DateTime.now().toIso8601String(),
      });
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
        final response = await _apiService.filterProperties(
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
          filters: searchFilters,
        );
        properties.assignAll(response.properties);
        
        DebugLogger.success('✅ Property search completed: ${response.properties.length} results');
        
        // Track search analytics
        await _apiService.trackEvent('property_search', {
          'filters': searchFilters,
          'results_count': response.properties.length,
          'total_available': response.total,
          'timestamp': DateTime.now().toIso8601String(),
        });
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
        
        // Track property view using AnalyticsController
        await _analyticsController.trackPropertyView(propertyId, source: 'property_details');
        
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
      
      final availability = await _apiService.checkPropertyAvailability(
        int.parse(propertyId),
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        guests: guests,
      );
      
      DebugLogger.success('✅ Availability check completed');
      
      // Track availability check using AnalyticsController
      await _analyticsController.trackEvent('property_availability_check', {
        'property_id': int.parse(propertyId),
        'check_in_date': checkInDate,
        'check_out_date': checkOutDate,
        'guests': guests,
        'available': availability['available'] ?? false,
      });
      
      // Show availability result to user
      Get.snackbar(
        'Availability',
        availability['available'] == true 
            ? 'Property is available for selected dates'
            : 'Property is not available for selected dates',
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
      
      await _apiService.showPropertyInterest(
        int.parse(propertyId),
        interestType: interestType,
        message: message,
        preferredTime: preferredTime,
      );
      
      DebugLogger.success('✅ Interest shown successfully');
      
      // Track interest using AnalyticsController
      await _analyticsController.trackPropertyInterest(propertyId, interestType);
      
      Get.snackbar(
        'Interest Recorded',
        'Your interest has been sent to the agent',
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
        final response = await _apiService.exploreProperties(
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
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
    await fetchDiscoverProperties(loadMore: true);
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
        // First get liked property IDs
        final likedProperties = await _apiService.getLikedProperties();
        final likedPropertyIds = likedProperties.map((p) => p.id).toList();
        
        if (likedPropertyIds.isNotEmpty) {
          // Use the unified search with property IDs filter
          final currentFilters = _filterController.currentFilter.value.copyWith(
            propertyIds: likedPropertyIds,
          );
          
          DebugLogger.info('🎯 Fetching filtered favourites: ${likedPropertyIds.length} properties');
          
          final response = await _apiService.searchProperties(
            filters: currentFilters,
            page: 1,
            limit: likedPropertyIds.length,
          );
          
          favouriteProperties.assignAll(response.properties);
          DebugLogger.success('✅ Filtered favourite properties loaded: ${response.properties.length} items');
        } else {
          favouriteProperties.clear();
          DebugLogger.info('📭 No favourite properties found');
        }
        
        // Track analytics
        await _apiService.trackEvent('favourites_loaded', {
          'count': likedPropertyIds.length,
          'filtered_count': favouriteProperties.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
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
        final result = await _apiService.getDislikedProperties();
        passedProperties.assignAll(result);
        DebugLogger.success('✅ Passed properties loaded from API: ${result.length} items');
        
        // Track analytics
        await _apiService.trackEvent('passed_properties_loaded', {
          'count': result.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
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
      await _repository.addToFavourites(propertyId.toString());
      await fetchFavouriteProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> removeFromFavourites(dynamic propertyId) async {
    try {
      await _repository.removeFromFavourites(propertyId.toString());
      await fetchFavouriteProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> addToPassedProperties(dynamic propertyId) async {
    try {
      await _repository.addToPassedProperties(propertyId.toString());
      await fetchPassedProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> removeFromPassedProperties(dynamic propertyId) async {
    try {
      await _repository.removeFromPassedProperties(propertyId.toString());
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

  // Legacy filter methods removed - use PropertyFilterController directly
} 