import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/property_model.dart';
import '../data/models/property_card_model.dart';
import '../data/repositories/property_repository.dart';
import '../data/providers/api_service.dart';
import 'auth_controller.dart';
import 'location_controller.dart';
import 'filter_controller.dart';
import 'analytics_controller.dart';
import '../utils/debug_logger.dart';
import '../utils/reactive_state_monitor.dart';

class PropertyController extends GetxController {
  final PropertyRepository _repository;
  late final ApiService _apiService;
  late final AuthController _authController;
  late final LocationController _locationController;
  late final PropertyFilterController _filterController;
  late final AnalyticsController _analyticsController;
  
  final RxList<PropertyCardModel> properties = <PropertyCardModel>[].obs;
  final RxList<PropertyCardModel> discoverProperties = <PropertyCardModel>[].obs;
  final RxList<PropertyCardModel> nearbyProperties = <PropertyCardModel>[].obs;
  final RxList<PropertyCardModel> recommendedProperties = <PropertyCardModel>[].obs;
  final RxList<PropertyCardModel> favouriteProperties = <PropertyCardModel>[].obs;
  final RxList<PropertyCardModel> passedProperties = <PropertyCardModel>[].obs;
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
    
    // Listen to filter changes for automatic refresh
    ever(_filterController.selectedPurpose, (_) => _onFiltersChanged());
    
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
    // React to filter changes - could trigger data refresh
    DebugLogger.info('🔄 Filters changed, properties may need refresh');
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
    
    return _locationController.currentPosition.value ?? Position(
      latitude: 19.0760,
      longitude: 72.8777,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
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
        final _ = discoverProperties.length;
        DebugLogger.info('📊 Reactive state updated - discoverProperties.length: $_');
        
        // Track analytics
        await _apiService.trackEvent('properties_discovery_loaded', {
          'count': result.properties.length,
          'limit': limit,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        DebugLogger.warning('⚠️ User not authenticated, falling back to repository');
        // Fallback to repository for non-authenticated users
        final result = await _repository.getProperties();
        // Repository already returns PropertyCardModel
        if (loadMore) {
          // For local data, simulate pagination by taking next set of items
          final startIndex = (currentDiscoverPage.value - 1) * limit;
          final endIndex = (startIndex + limit).clamp(0, result.length);
          if (startIndex < result.length) {
            discoverProperties.addAll(result.skip(startIndex).take(limit).toList());
            currentDiscoverPage.value++;
          }
          hasMoreDiscoverProperties.value = startIndex + limit < result.length;
        } else {
          discoverProperties.assignAll(result.take(limit).toList());
          currentDiscoverPage.value = 2;
          hasMoreDiscoverProperties.value = result.length > limit;
        }
        
        DebugLogger.info('📱 Loaded ${discoverProperties.length} properties from local repository');
      }
    } catch (e) {
      error.value = e.toString();
      DebugLogger.error('❌ Error fetching discover properties: $e');
      
      // Try fallback to local data
      try {
        DebugLogger.info('🔄 Attempting fallback to local data...');
        final result = await _repository.getProperties();
        discoverProperties.assignAll(result.take(limit).toList());
        DebugLogger.warning('⚠️ Using fallback data: ${discoverProperties.length} properties');
        error.value = ''; // Clear error since fallback worked
      } catch (fallbackError) {
        DebugLogger.error('💥 Fallback also failed: $fallbackError');
        Get.snackbar(
          'Error',
          'Failed to load properties. Please check your connection.',
          snackPosition: SnackPosition.TOP,
        );
      }
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
        DebugLogger.warning('⚠️ User not authenticated, using local filtering');
        // For non-authenticated users, use FilterController to filter results
        final allProps = await _repository.getProperties();
        final filtered = _filterController.applyFilters(allProps);
        properties.assignAll(filtered);
        
        DebugLogger.info('📱 Local search completed: ${filtered.length} results');
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
        DebugLogger.warning('⚠️ User not authenticated, using repository');
        final property = await _repository.getPropertyById(propertyId);
        DebugLogger.info('📱 Property details loaded from repository: ${property.title}');
        return property;
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
        // Fallback to repository for non-authenticated users
        final result = await _repository.getProperties();
        properties.assignAll(result);
        DebugLogger.info('📱 Properties loaded from repository: ${result.length} items');
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
        final result = await _apiService.getLikedProperties();
        
        // Validate favourite properties
        final validFavourites = result.where((property) {
          final isValid = property.id > 0 && property.title.isNotEmpty;
          if (!isValid) {
            DebugLogger.warning('⚠️ Filtering out invalid favourite property: ID=${property.id}, Title="${property.title}"');
          }
          return isValid;
        }).toList();
        
        favouriteProperties.assignAll(validFavourites);
        DebugLogger.success('✅ Favourite properties loaded from API: ${validFavourites.length} valid items out of ${result.length} total');
        
        // Force reactive update
        final _ = favouriteProperties.length;
        DebugLogger.info('📊 Favourite properties reactive state updated - count: $_');
        
        // Track analytics
        await _apiService.trackEvent('favourites_loaded', {
          'count': result.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        // Fallback to repository
        final result = await _repository.getFavouriteProperties();
        favouriteProperties.assignAll(result);
        DebugLogger.info('📱 Favourite properties loaded from repository: ${result.length} items');
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
        // Fallback to repository
        final result = await _repository.getPassedProperties();
        passedProperties.assignAll(result);
        DebugLogger.info('📱 Passed properties loaded from repository: ${result.length} items');
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

  PropertyCardModel? getPropertyCardById(dynamic id) {
    try {
      final idString = id.toString();
      return properties.firstWhere((property) => property.id.toString() == idString);
    } catch (e) {
      return null;
    }
  }

  // Filter methods - now using FilterController
  List<PropertyCardModel> getFilteredFavourites() {
    DebugLogger.info('🔍 Filtering ${favouriteProperties.length} favourite properties');
    final filtered = _filterController.applyFilters(favouriteProperties);
    DebugLogger.info('✅ After filtering: ${filtered.length} properties');
    return filtered;
  }

  List<PropertyCardModel> getFilteredPassed() {
    return _filterController.applyFilters(passedProperties);
  }

  // Deprecated: Use FilterController.applyFilters instead
  List<PropertyCardModel> _applyCardFilters(List<PropertyCardModel> propertyList) {
    return _filterController.applyFilters(propertyList);
  }

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

  // Deprecated filter helper methods - now delegated to FilterController
  
  void updateFilters({
    String? selectedPurposeValue,
    double? minPriceValue,
    double? maxPriceValue,
    int? minBedroomsValue,
    int? maxBedroomsValue,
    String? propertyTypeValue,
    List<String>? selectedAmenitiesValue,
  }) {
    _filterController.updateFilters(
      selectedPurposeValue: selectedPurposeValue,
      minPriceValue: minPriceValue,
      maxPriceValue: maxPriceValue,
      minBedroomsValue: minBedroomsValue,
      maxBedroomsValue: maxBedroomsValue,
      propertyTypeValue: propertyTypeValue,
      selectedAmenitiesValue: selectedAmenitiesValue,
    );
  }

  void clearFilters() {
    _filterController.clearFilters();
  }

  double getPriceMin() {
    return _filterController.getPriceMin();
  }

  double getPriceMax() {
    return _filterController.getPriceMax();
  }

  String getPriceLabel() {
    return _filterController.getPriceLabel();
  }
  
  // Getter delegation for backward compatibility
  String get selectedPurpose => _filterController.selectedPurpose.value;
  double get minPrice => _filterController.minPrice.value;
  double get maxPrice => _filterController.maxPrice.value;
  int get minBedrooms => _filterController.minBedrooms.value;
  int get maxBedrooms => _filterController.maxBedrooms.value;
  String get propertyType => _filterController.propertyType.value;
  List<String> get selectedAmenities => _filterController.selectedAmenities;
} 