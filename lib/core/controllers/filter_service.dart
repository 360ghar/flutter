import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/models/unified_filter_model.dart';
import '../data/models/api_response_models.dart';
import '../utils/debug_logger.dart';
import 'location_controller.dart';

class FilterService extends GetxController {
  static FilterService get instance => Get.find<FilterService>();

  // Storage instance
  final _storage = GetStorage();
  late final LocationController _locationController;
  
  // Central filter state
  final Rx<UnifiedFilterModel> currentFilter = UnifiedFilterModel.initial().obs;
  
  // Location state
  final Rx<LocationData?> selectedLocation = Rx<LocationData?>(null);
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  
  // Loading states
  final RxBool isApplyingFilters = false.obs;
  final RxBool isLoadingLocation = false.obs;
  
  // Debounce timer for text search
  Timer? _searchDebouncer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  @override
  void onInit() {
    super.onInit();
    _locationController = Get.find<LocationController>();
    _loadSavedFilters();
    _setupListeners();
    
    // Listen to location updates
    _locationController.currentPosition.listen((position) {
      // Position updates are handled by the location controller
    });
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    super.onClose();
  }

  void _loadSavedFilters() {
    try {
      // Load saved location
      final savedLocation = _storage.read('saved_location');
      if (savedLocation != null) {
        selectedLocation.value = LocationData.fromJson(savedLocation);
        _updateLocationInFilter();
      }
      
      // Load saved filters
      final savedFilters = _storage.read('saved_filters');
      if (savedFilters != null) {
        currentFilter.value = UnifiedFilterModel.fromJson(savedFilters);
      }
      
      DebugLogger.success('📂 Loaded saved filters');
    } catch (e) {
      DebugLogger.error('Error loading saved filters: $e');
    }
  }

  void _setupListeners() {
    // Save filters whenever they change
    ever(currentFilter, (filter) {
      _storage.write('saved_filters', filter.toJson());
      DebugLogger.info('Filters saved: ${filter.activeFilterCount} active');
    });
    
    // Save location whenever it changes
    ever(selectedLocation, (location) {
      if (location != null) {
        _storage.write('saved_location', location.toJson());
        _updateLocationInFilter();
      }
    });
  }

  void _updateLocationInFilter() {
    if (selectedLocation.value != null) {
      currentFilter.value = currentFilter.value.copyWith(
        latitude: selectedLocation.value!.latitude,
        longitude: selectedLocation.value!.longitude,
        city: selectedLocation.value!.city,
        locality: selectedLocation.value!.locality,
      );
    }
  }

  // Update methods for each filter type
  void updatePurpose(String purpose) {
    currentFilter.value = currentFilter.value.copyWith(purpose: purpose);
    _adjustPriceRangeForPurpose(purpose);
    DebugLogger.info('Purpose updated to: $purpose');
  }

  void updatePriceRange(double min, double max) {
    currentFilter.value = currentFilter.value.copyWith(
      priceMin: min,
      priceMax: max,
    );
    DebugLogger.info('Price range updated: min=₹$min, max=₹$max');
  }

  void updateBedrooms(int? min, int? max) {
    currentFilter.value = currentFilter.value.copyWith(
      bedroomsMin: min,
      bedroomsMax: max,
    );
    DebugLogger.info('Bedrooms updated: min=$min, max=$max');
  }

  void updateBathrooms(int? min, int? max) {
    currentFilter.value = currentFilter.value.copyWith(
      bathroomsMin: min,
      bathroomsMax: max,
    );
    DebugLogger.info('Bathrooms updated: min=$min, max=$max');
  }

  void updateArea(double? min, double? max) {
    currentFilter.value = currentFilter.value.copyWith(
      areaMin: min,
      areaMax: max,
    );
    DebugLogger.info('Area updated: min=$min sqft, max=$max sqft');
  }

  void updatePropertyTypes(List<String> types) {
    currentFilter.value = currentFilter.value.copyWith(propertyType: types);
    DebugLogger.info('Property types updated: ${types.join(', ')}');
  }

  void addPropertyType(String type) {
    final types = List<String>.from(currentFilter.value.propertyType ?? []);
    if (!types.contains(type)) {
      types.add(type);
      updatePropertyTypes(types);
    }
  }

  void removePropertyType(String type) {
    final types = List<String>.from(currentFilter.value.propertyType ?? []);
    types.remove(type);
    updatePropertyTypes(types);
  }

  void updateAmenities(List<String> amenities) {
    currentFilter.value = currentFilter.value.copyWith(amenities: amenities);
    DebugLogger.info('Amenities updated: ${amenities.length} selected');
  }

  void addAmenity(String amenity) {
    final amenities = List<String>.from(currentFilter.value.amenities ?? []);
    if (!amenities.contains(amenity)) {
      amenities.add(amenity);
      updateAmenities(amenities);
    }
  }

  void removeAmenity(String amenity) {
    final amenities = List<String>.from(currentFilter.value.amenities ?? []);
    amenities.remove(amenity);
    updateAmenities(amenities);
  }

  void toggleAmenity(String amenity) {
    final amenities = List<String>.from(currentFilter.value.amenities ?? []);
    if (amenities.contains(amenity)) {
      amenities.remove(amenity);
    } else {
      amenities.add(amenity);
    }
    updateAmenities(amenities);
  }

  void updateLocation(LocationData location) {
    selectedLocation.value = location;
    DebugLogger.info('Location updated: ${location.name}');
  }

  void updateLocationWithCoordinates({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? city,
    String? locality,
  }) {
    currentFilter.value = currentFilter.value.copyWith(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm ?? currentFilter.value.radiusKm,
      city: city,
      locality: locality,
      sortBy: null, // Don't force sort by distance when location is set
    );
    DebugLogger.info('Location updated: lat=$latitude, lng=$longitude');
  }

  void updateRadius(double radiusKm) {
    currentFilter.value = currentFilter.value.copyWith(radiusKm: radiusKm);
    DebugLogger.info('Search radius updated: ${radiusKm}km');
  }

  void updateSortBy(SortBy sortBy) {
    currentFilter.value = currentFilter.value.copyWith(sortBy: sortBy);
    DebugLogger.info('Sort by updated: $sortBy');
  }

  void updateParkingSpaces(int? min) {
    currentFilter.value = currentFilter.value.copyWith(parkingSpacesMin: min);
    DebugLogger.info('Parking spaces updated: min $min');
  }

  void updateFloorRange(int? min, int? max) {
    currentFilter.value = currentFilter.value.copyWith(
      floorNumberMin: min,
      floorNumberMax: max,
    );
    DebugLogger.info('Floor range updated: min=$min, max=$max');
  }

  void updateMaxAge(int? ageInYears) {
    currentFilter.value = currentFilter.value.copyWith(ageMax: ageInYears);
    DebugLogger.info('Max age updated: $ageInYears years');
  }

  // Text search with debounce
  void updateSearchQuery(String query) {
    _searchDebouncer?.cancel();
    
    if (query.isEmpty) {
      searchQuery.value = '';
      currentFilter.value = currentFilter.value.copyWith(
        city: selectedLocation.value?.city,
      );
      return;
    }

    _searchDebouncer = Timer(_searchDebounceDelay, () {
      searchQuery.value = query;
      currentFilter.value = currentFilter.value.copyWith(city: query);
    });
  }

  // Set current location
  Future<void> setCurrentLocation() async {
    if (isLoadingLocation.value) return;

    try {
      isLoadingLocation.value = true;
      
      // Get current position
      await _locationController.getCurrentLocation();
      final position = _locationController.currentPosition.value;
      if (position != null) {
        updateLocationWithCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: currentFilter.value.radiusKm ?? 10.0,
        );
        
        Get.snackbar(
          'Location Updated',
          'Using your current location for search',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      DebugLogger.error('❌ Failed to get current location: $e');
      Get.snackbar(
        'Location Error',
        'Unable to get your current location',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoadingLocation.value = false;
    }
  }

  // Short-stay filters
  void updateStayDates({String? checkIn, String? checkOut}) {
    // Convert to the unified model format if needed
    // For now, we'll store as additional parameters
    DebugLogger.info('Stay dates updated: checkIn=$checkIn, checkOut=$checkOut');
  }

  void updateGuests(int? guests) {
    // Store guests count in a suitable field
    DebugLogger.info('Guests updated: $guests');
  }

  // Reset methods
  void resetFilters() {
    currentFilter.value = UnifiedFilterModel.initial();
    searchQuery.value = '';
    // Keep location as it is
    _updateLocationInFilter();
    DebugLogger.info('All filters reset');
    
    Get.snackbar(
      'Filters Reset',
      'All filters have been cleared',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void clearLocation() {
    selectedLocation.value = null;
    currentFilter.value = currentFilter.value.copyWith(
      latitude: null,
      longitude: null,
      city: null,
      locality: null,
    );
    _storage.remove('saved_location');
    DebugLogger.info('Location cleared');
  }

  // Apply filters (used by controllers to trigger API calls)
  void applyFilters() {
    isApplyingFilters.value = true;
    
    // Trigger a small delay to show loading state
    Future.delayed(const Duration(milliseconds: 100), () {
      isApplyingFilters.value = false;
    });
    
    DebugLogger.api('🔍 Applying filters: ${currentFilter.value.activeFilterCount} active');
  }

  // Helper methods
  void _adjustPriceRangeForPurpose(String purpose) {
    double? newMin, newMax;
    
    switch (purpose) {
      case 'short_stay':
        newMin = 500.0; // ₹500 per night
        newMax = 50000.0; // ₹50K per night
        break;
      case 'rent':
        newMin = 5000.0; // ₹5K per month
        newMax = 500000.0; // ₹5L per month
        break;
      case 'buy':
      default:
        newMin = 500000.0; // ₹5L
        newMax = 150000000.0; // ₹15Cr
        break;
    }
    
    // Update price range if current values are out of bounds
    final currentMin = currentFilter.value.priceMin ?? newMin;
    final currentMax = currentFilter.value.priceMax ?? newMax;
    
    if (currentMin < newMin || currentMax > newMax) {
      currentFilter.value = currentFilter.value.copyWith(
        priceMin: newMin,
        priceMax: newMax,
      );
    }
  }

  double getPriceMin() {
    switch (currentFilter.value.purpose) {
      case 'short_stay':
        return 500.0;
      case 'rent':
        return 5000.0;
      case 'buy':
      default:
        return 500000.0;
    }
  }

  double getPriceMax() {
    switch (currentFilter.value.purpose) {
      case 'short_stay':
        return 50000.0;
      case 'rent':
        return 500000.0;
      case 'buy':
      default:
        return 150000000.0;
    }
  }

  String getPriceLabel() {
    switch (currentFilter.value.purpose) {
      case 'short_stay':
        return 'Price per night';
      case 'rent':
        return 'Price per month';
      case 'buy':
      default:
        return 'Property price';
    }
  }

  // Get query parameters for API calls
  Map<String, dynamic> getQueryParams() {
    final params = <String, dynamic>{};
    final filter = currentFilter.value;
    
    if (searchQuery.value.isNotEmpty) params['q'] = searchQuery.value;
    if (filter.purpose != null) params['purpose'] = filter.purpose;
    if (filter.priceMin != null) params['price_min'] = filter.priceMin;
    if (filter.priceMax != null) params['price_max'] = filter.priceMax;
    if (filter.bedroomsMin != null) params['bedrooms_min'] = filter.bedroomsMin;
    if (filter.bedroomsMax != null) params['bedrooms_max'] = filter.bedroomsMax;
    if (filter.bathroomsMin != null) params['bathrooms_min'] = filter.bathroomsMin;
    if (filter.bathroomsMax != null) params['bathrooms_max'] = filter.bathroomsMax;
    if (filter.areaMin != null) params['area_min'] = filter.areaMin;
    if (filter.areaMax != null) params['area_max'] = filter.areaMax;
    if (filter.propertyType != null && filter.propertyType!.isNotEmpty) {
      params['property_type'] = filter.propertyType!.join(',');
    }
    if (filter.amenities != null && filter.amenities!.isNotEmpty) {
      params['amenities'] = filter.amenities!.join(',');
    }
    if (filter.latitude != null) params['lat'] = filter.latitude;
    if (filter.longitude != null) params['lng'] = filter.longitude;
    if (filter.radiusKm != null) params['radius'] = filter.radiusKm;
    if (filter.city != null) params['city'] = filter.city;
    if (filter.locality != null) params['locality'] = filter.locality;
    if (filter.sortBy != null) params['sort_by'] = filter.sortBy;
    if (filter.parkingSpacesMin != null) params['parking_min'] = filter.parkingSpacesMin;
    if (filter.floorNumberMin != null) params['floor_min'] = filter.floorNumberMin;
    if (filter.floorNumberMax != null) params['floor_max'] = filter.floorNumberMax;
    if (filter.ageMax != null) params['age_max'] = filter.ageMax;
    if (filter.propertyIds != null && filter.propertyIds!.isNotEmpty) {
      params['property_ids'] = filter.propertyIds!.join(',');
    }
    
    return params;
  }

  // Get summary of active filters for display
  List<String> getActiveFiltersSummary() {
    List<String> summary = [];
    final filter = currentFilter.value;
    
    if (searchQuery.value.isNotEmpty) {
      summary.add('Search: "${searchQuery.value}"');
    }
    
    if (filter.purpose != null && filter.purpose != 'buy') {
      summary.add('Purpose: ${filter.purpose}');
    }
    
    if (filter.priceMin != null || filter.priceMax != null) {
      final min = filter.priceMin ?? getPriceMin();
      final max = filter.priceMax ?? getPriceMax();
      summary.add('Price: ₹${min.toInt()} - ₹${max.toInt()}');
    }
    
    if (filter.bedroomsMin != null || filter.bedroomsMax != null) {
      summary.add('Bedrooms: ${filter.bedroomsMin ?? 0} - ${filter.bedroomsMax ?? 10}');
    }
    
    if (filter.propertyType != null && filter.propertyType!.isNotEmpty) {
      summary.add('Types: ${filter.propertyType!.join(', ')}');
    }
    
    if (filter.amenities != null && filter.amenities!.isNotEmpty) {
      summary.add('Amenities: ${filter.amenities!.length} selected');
    }
    
    return summary;
  }

  // Check if filters are active
  bool get hasActiveFilters => currentFilter.value.activeFilterCount > 0 || searchQuery.value.isNotEmpty;
  
  // Get count of active filters
  int get activeFiltersCount => currentFilter.value.activeFilterCount + (searchQuery.value.isNotEmpty ? 1 : 0);
  
  // Check if location is set
  bool get hasLocation => currentFilter.value.latitude != null && currentFilter.value.longitude != null;

  // Get location display text
  String get locationDisplayText {
    final filter = currentFilter.value;
    if (filter.city != null) {
      return filter.locality != null 
          ? '${filter.locality}, ${filter.city}'
          : filter.city!;
    } else if (hasLocation) {
      return 'Current Location';
    }
    return 'All Locations';
  }

  // Method to set property IDs for favorites filtering
  void setPropertyIds(List<int> ids) {
    currentFilter.value = currentFilter.value.copyWith(propertyIds: ids);
  }

  // Predefined amenities list
  static const List<String> availableAmenities = [
    'parking',
    'gym',
    'pool',
    'security',
    'elevator',
    'garden',
    'powerbackup',
    'clubhouse',
    'playground',
    'wifi',
    'ac',
    'furnished',
    'balcony',
    'terrace',
  ];

  // Sort options
  static const Map<String, String> sortOptions = {
    'distance': 'Distance',
    'price_low': 'Price: Low to High',
    'price_high': 'Price: High to Low',
    'newest': 'Newest First',
    'popular': 'Most Popular',
    'relevance': 'Relevance',
  };
}