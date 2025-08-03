import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/property_model.dart';
import '../data/models/property_card_model.dart';
import '../data/repositories/property_repository.dart';
import '../data/providers/api_service.dart';
import 'auth_controller.dart';
import '../utils/debug_logger.dart';
import '../utils/reactive_state_monitor.dart';

class PropertyController extends GetxController {
  final PropertyRepository _repository;
  late final ApiService _apiService;
  late final AuthController _authController;
  
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
  
  // User location
  final Rxn<Position> userPosition = Rxn<Position>();
  final RxBool isLocationPermissionGranted = false.obs;

  // Filter properties
  final RxMap<String, dynamic> filters = <String, dynamic>{}.obs;
  final RxString selectedPurpose = 'Buy'.obs; // Buy, Rent, Stay
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 150000000.0.obs; // ₹15Cr to accommodate all properties
  final RxInt minBedrooms = 0.obs;
  final RxInt maxBedrooms = 10.obs;
  final RxString propertyType = 'All'.obs;
  final RxList<String> selectedAmenities = <String>[].obs;

  PropertyController(this._repository);

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();
    
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
    
    // If already logged in, initialize immediately
    if (_authController.isLoggedIn.value) {
      _initializeController();
    }
  }

  Future<void> _initializeController() async {
    await _requestLocationPermission();
    await _getCurrentLocation();
    // Only load essential data on init - other data will be loaded lazily when needed
    await fetchDiscoverProperties();
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

  // Location methods
  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        isLocationPermissionGranted.value = false;
        Get.snackbar(
          'Location Permission',
          'Location access is permanently denied. Please enable it in settings.',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      
      if (permission == LocationPermission.denied) {
        isLocationPermissionGranted.value = false;
        Get.snackbar(
          'Location Permission',
          'Location access is required for nearby properties.',
          snackPosition: SnackPosition.TOP,
        );
        return;
      }
      
      isLocationPermissionGranted.value = true;
    } catch (e) {
      print('Error requesting location permission: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!isLocationPermissionGranted.value) return;
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userPosition.value = position;
      
      // Update user location in backend
      if (_authController.isAuthenticated) {
        await _authController.updateUserLocation(
          position.latitude,
          position.longitude,
        );
      }
      
      // Load nearby properties
      await fetchNearbyProperties();
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<Position> _getCurrentLocationSync() async {
    if (userPosition.value != null) {
      return userPosition.value!;
    }
    
    await _getCurrentLocation();
    
    return userPosition.value ?? Position(
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
    if (userPosition.value == null) {
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
        latitude: userPosition.value!.latitude,
        longitude: userPosition.value!.longitude,
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
        'latitude': userPosition.value!.latitude,
        'longitude': userPosition.value!.longitude,
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
        // For non-authenticated users, repository already returns PropertyCardModel
        final allProps = await _repository.getProperties();
        final filtered = _applyCardFilters(allProps);
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
        
        // Track property view
        await _apiService.trackEvent('property_view', {
          'property_id': int.parse(propertyId),
          'source': 'property_details',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
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
      
      // Track availability check
      await _apiService.trackEvent('property_availability_check', {
        'property_id': int.parse(propertyId),
        'check_in_date': checkInDate,
        'check_out_date': checkOutDate,
        'guests': guests,
        'available': availability['available'] ?? false,
        'timestamp': DateTime.now().toIso8601String(),
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
      
      // Track interest
      await _apiService.trackEvent('property_interest', {
        'property_id': int.parse(propertyId),
        'interest_type': interestType,
        'has_message': message != null,
        'has_preferred_time': preferredTime != null,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
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

  // Filter methods
  List<PropertyCardModel> getFilteredFavourites() {
    DebugLogger.info('🔍 Filtering ${favouriteProperties.length} favourite properties');
    final filtered = _applyCardFilters(favouriteProperties);
    DebugLogger.info('✅ After filtering: ${filtered.length} properties');
    return filtered;
  }

  List<PropertyCardModel> getFilteredPassed() {
    return _applyCardFilters(passedProperties);
  }

  List<PropertyCardModel> _applyCardFilters(List<PropertyCardModel> propertyList) {
    DebugLogger.info('🔍 Applying filters to ${propertyList.length} properties');
    DebugLogger.info('📋 Purpose: ${selectedPurpose.value}');
    DebugLogger.info('💰 Price range: ${minPrice.value} - ${maxPrice.value}');
    DebugLogger.info('🛏️ Bedrooms range: ${minBedrooms.value} - ${maxBedrooms.value}');
    DebugLogger.info('🏠 Property type: ${propertyType.value}');
    
    return propertyList.where((property) {
      // Purpose filter
      if (!_matchesCardPurpose(property)) {
        DebugLogger.info('❌ Property ${property.id} (${property.title}) filtered out by purpose');
        return false;
      }

      // Price filter (adjusted based on purpose)
      final adjustedPrice = _getCardAdjustedPrice(property);
      if (adjustedPrice < minPrice.value || adjustedPrice > maxPrice.value) {
        DebugLogger.info('❌ Property ${property.id} (${property.title}) filtered out by price: $adjustedPrice');
        return false;
      }

      // Bedrooms filter (skip for Stay mode if less than 1 bedroom)
      if (selectedPurpose.value != 'Stay') {
        if (property.bedrooms != null && (property.bedrooms! < minBedrooms.value || property.bedrooms! > maxBedrooms.value)) {
          DebugLogger.info('❌ Property ${property.id} (${property.title}) filtered out by bedrooms: ${property.bedrooms}');
          return false;
        }
      }

      // Property type filter
      if (propertyType.value != 'All' && !_matchesCardPropertyType(property)) {
        DebugLogger.info('❌ Property ${property.id} (${property.title}) filtered out by type: ${property.propertyTypeString}');
        return false;
      }

      DebugLogger.info('✅ Property ${property.id} (${property.title}) passed all filters');
      return true;
    }).toList();
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

  bool _matchesCardPurpose(PropertyCardModel property) {
    switch (selectedPurpose.value) {
      case 'Stay':
        // Stay properties should match the purpose or be suitable for short stays
        return property.purpose == PropertyPurpose.shortStay ||
               property.propertyType == PropertyType.apartment ||
               property.basePrice < 5000000; // Less than 50L for stay properties
      case 'Rent':
        // Rent properties - match purpose or suitable for rent
        return property.purpose == PropertyPurpose.rent || property.purpose == PropertyPurpose.shortStay;
      case 'Buy':
      default:
        // Buy properties - all properties available for purchase
        return property.purpose == PropertyPurpose.buy;
    }
  }

  double _getCardAdjustedPrice(PropertyCardModel property) {
    switch (selectedPurpose.value) {
      case 'Stay':
        // Convert property price to estimated per-night rate
        return (property.basePrice / 365 / 100).clamp(500.0, 50000.0); // Rough estimate
      case 'Rent':
        // Convert property price to estimated monthly rent
        return (property.basePrice * 0.001).clamp(5000.0, 500000.0); // Rough 0.1% of property value per month
      case 'Buy':
      default:
        return property.basePrice;
    }
  }

  bool _matchesCardPropertyType(PropertyCardModel property) {
    final selectedType = propertyType.value;
    
    if (selectedPurpose.value == 'Stay') {
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

  void updateFilters({
    String? selectedPurposeValue,
    double? minPriceValue,
    double? maxPriceValue,
    int? minBedroomsValue,
    int? maxBedroomsValue,
    String? propertyTypeValue,
    List<String>? selectedAmenitiesValue,
  }) {
    if (selectedPurposeValue != null) {
      selectedPurpose.value = selectedPurposeValue;
      _updatePriceRangeForPurpose();
    }
    if (minPriceValue != null) minPrice.value = minPriceValue;
    if (maxPriceValue != null) maxPrice.value = maxPriceValue;
    if (minBedroomsValue != null) minBedrooms.value = minBedroomsValue;
    if (maxBedroomsValue != null) maxBedrooms.value = maxBedroomsValue;
    if (propertyTypeValue != null) propertyType.value = propertyTypeValue;
    if (selectedAmenitiesValue != null) selectedAmenities.value = selectedAmenitiesValue;
  }

  void clearFilters() {
    selectedPurpose.value = 'Buy';
    _updatePriceRangeForPurpose();
    minBedrooms.value = 0;
    maxBedrooms.value = 10;
    propertyType.value = 'All';
    selectedAmenities.clear();
  }

  void _updatePriceRangeForPurpose() {
    double newMin, newMax;
    
    switch (selectedPurpose.value) {
      case 'Stay':
        newMin = 500.0; // ₹500 per night
        newMax = 50000.0; // ₹50K per night
        break;
      case 'Rent':
        newMin = 5000.0; // ₹5K per month
        newMax = 5000000.0; // ₹50L per month
        break;
      case 'Buy':
      default:
        newMin = 500000.0; // ₹5L
        newMax = 150000000.0; // ₹15Cr
        break;
    }
    
    // Clamp current values to ensure they're within the new range
    minPrice.value = minPrice.value.clamp(newMin, newMax);
    maxPrice.value = maxPrice.value.clamp(newMin, newMax);
    
    // If both values are the same after clamping, reset to full range
    if (minPrice.value == maxPrice.value) {
      minPrice.value = newMin;
      maxPrice.value = newMax;
    }
    
    // Ensure minPrice <= maxPrice
    if (minPrice.value > maxPrice.value) {
      minPrice.value = newMin;
      maxPrice.value = newMax;
    }
  }

  double getPriceMin() {
    switch (selectedPurpose.value) {
      case 'Stay':
        return 500.0;
      case 'Rent':
        return 5000.0;
      case 'Buy':
      default:
        return 500000.0;
    }
  }

  double getPriceMax() {
    switch (selectedPurpose.value) {
      case 'Stay':
        return 50000.0;
      case 'Rent':
        return 5000000.0;
      case 'Buy':
      default:
        return 150000000.0;
    }
  }

  String getPriceLabel() {
    switch (selectedPurpose.value) {
      case 'Stay':
        return 'Price per night';
      case 'Rent':
        return 'Price per month';
      case 'Buy':
      default:
        return 'Property price';
    }
  }
} 