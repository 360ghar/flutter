import 'dart:async';
import 'package:get/get.dart';
import '../data/models/unified_filter_model.dart';
import '../data/models/page_state_model.dart';
import '../data/models/api_response_models.dart';
import '../utils/debug_logger.dart';
import 'page_state_service.dart';

/// Legacy FilterService that bridges to the new page-specific state system
/// This maintains backward compatibility for existing controllers that use FilterService
class FilterService extends GetxController {
  static FilterService get instance => Get.find<FilterService>();

  late final PageStateService _pageStateService;
  
  @override
  void onInit() {
    super.onInit();
    _pageStateService = Get.find<PageStateService>();
    DebugLogger.info('FilterService initialized with page-specific state support');
  }

  // Helper to get current page state
  PageStateModel _getCurrentPageState() {
    return _pageStateService.getCurrentPageState();
  }

  // Legacy interface - now delegates to PageStateService
  UnifiedFilterModel get currentFilter => _getCurrentPageState().filters;
  
  bool get isLoading => _getCurrentPageState().isLoading;
  String get searchQuery => _getCurrentPageState().searchQuery ?? '';
  
  // Legacy compatibility fields
  final RxBool isApplyingFilters = false.obs;
  final RxBool isLoadingLocation = false.obs;

  // Update methods for each filter type - now delegate to PageStateService
  void updatePurpose(String purpose) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(purpose: purpose);
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    _adjustPriceRangeForPurpose(purpose);
    DebugLogger.info('Purpose updated to: $purpose');
  }

  void updatePriceRange(double min, double max) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(
      priceMin: min,
      priceMax: max,
    );
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Price range updated: min=₹$min, max=₹$max');
  }

  void updateBedrooms(int? min, int? max) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(
      bedroomsMin: min,
      bedroomsMax: max,
    );
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Bedrooms updated: min=$min, max=$max');
  }

  void updateBathrooms(int? min, int? max) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(
      bathroomsMin: min,
      bathroomsMax: max,
    );
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Bathrooms updated: min=$min, max=$max');
  }

  void updateArea(double? min, double? max) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(
      areaMin: min,
      areaMax: max,
    );
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Area updated: min=$min sqft, max=$max sqft');
  }

  void updatePropertyTypes(List<String> types) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(propertyType: types);
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Property types updated: ${types.join(', ')}');
  }

  void addPropertyType(String type) {
    final types = List<String>.from(_getCurrentPageState().filters.propertyType ?? []);
    if (!types.contains(type)) {
      types.add(type);
      updatePropertyTypes(types);
    }
  }

  void removePropertyType(String type) {
    final types = List<String>.from(_getCurrentPageState().filters.propertyType ?? []);
    types.remove(type);
    updatePropertyTypes(types);
  }

  void updateAmenities(List<String> amenities) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(amenities: amenities);
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Amenities updated: ${amenities.length} selected');
  }

  void addAmenity(String amenity) {
    final amenities = List<String>.from(_getCurrentPageState().filters.amenities ?? []);
    if (!amenities.contains(amenity)) {
      amenities.add(amenity);
      updateAmenities(amenities);
    }
  }

  void removeAmenity(String amenity) {
    final amenities = List<String>.from(_getCurrentPageState().filters.amenities ?? []);
    amenities.remove(amenity);
    updateAmenities(amenities);
  }

  void toggleAmenity(String amenity) {
    final amenities = List<String>.from(_getCurrentPageState().filters.amenities ?? []);
    if (amenities.contains(amenity)) {
      amenities.remove(amenity);
    } else {
      amenities.add(amenity);
    }
    updateAmenities(amenities);
  }

  void updateLocation(LocationData location) {
    _pageStateService.updateLocation(location);
    DebugLogger.info('Location updated: ${location.name}');
  }

  void updateLocationWithCoordinates({
    required double latitude,
    required double longitude,
    double? radiusKm,
    String? locationName,
  }) {
    DebugLogger.info('📍 FilterService.updateLocationWithCoordinates called');
    DebugLogger.info('📍 Parameters: lat=$latitude, lng=$longitude, radius=${radiusKm}km, name=$locationName');
    
    // If no location name provided, get it from reverse geocoding
    final finalName = locationName ?? 'Location (${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)})';
    
    final location = LocationData(
      name: finalName,
      latitude: latitude,
      longitude: longitude,
    );
    
    DebugLogger.info('📍 Created LocationData: ${location.toJson()}');
    _pageStateService.updateLocation(location);
    DebugLogger.success('✅ FilterService location updated: lat=$latitude, lng=$longitude');
  }

  void updateRadius(double radiusKm) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(radiusKm: radiusKm);
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Search radius updated: ${radiusKm}km');
  }

  void updateSortBy(SortBy sortBy) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(sortBy: sortBy);
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Sort by updated: $sortBy');
  }

  void updateParkingSpaces(int? min) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(parkingSpacesMin: min);
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Parking spaces updated: min $min');
  }

  void updateFloorRange(int? min, int? max) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(
      floorNumberMin: min,
      floorNumberMax: max,
    );
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Floor range updated: min=$min, max=$max');
  }

  void updateMaxAge(int? ageInYears) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(ageMax: ageInYears);
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
    DebugLogger.info('Max age updated: $ageInYears years');
  }

  // Text search with debounce
  void updateSearchQuery(String query) {
    final currentPageType = _pageStateService.currentPageType.value;
    _pageStateService.updatePageSearch(currentPageType, query);
  }

  // Set current location
  Future<void> setCurrentLocation() async {
    try {
      await _pageStateService.useCurrentLocation();
    } catch (e) {
      DebugLogger.error('❌ Failed to get current location: $e');
      Get.snackbar(
        'Location Error',
        'Unable to get your current location',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Short-stay filters
  void updateStayDates({String? checkIn, String? checkOut}) {
    // For compatibility - these would be handled in the specific implementations
    DebugLogger.info('Stay dates updated: checkIn=$checkIn, checkOut=$checkOut');
  }

  void updateGuests(int? guests) {
    // For compatibility - these would be handled in the specific implementations
    DebugLogger.info('Guests updated: $guests');
  }

  // Reset methods
  void resetFilters() {
    final currentPageType = _pageStateService.currentPageType.value;
    _pageStateService.resetPageFilters(currentPageType);
    DebugLogger.info('Filters reset for ${currentPageType.name}');
  }

  void clearLocation() {
    // This would need to be implemented in PageStateService
    // For now, just log it
    DebugLogger.info('Location cleared');
  }

  // Apply filters (legacy method for compatibility)
  void applyFilters() {
    isApplyingFilters.value = true;
    
    // Trigger a small delay to show loading state
    Future.delayed(const Duration(milliseconds: 100), () {
      isApplyingFilters.value = false;
    });
    
    final currentState = _getCurrentPageState();
    DebugLogger.api('🔍 Applying filters: ${currentState.activeFiltersCount} active');
  }

  // Helper methods
  void _adjustPriceRangeForPurpose(String purpose) {
    double newMin, newMax;
    
    switch (purpose) {
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
    final currentState = _getCurrentPageState();
    final currentMin = currentState.filters.priceMin ?? newMin;
    final currentMax = currentState.filters.priceMax ?? newMax;
    
    if (currentMin < newMin || currentMax > newMax) {
      updatePriceRange(newMin, newMax);
    }
  }

  double getPriceMin() {
    final currentState = _getCurrentPageState();
    switch (currentState.filters.purpose) {
      case 'rent':
        return 5000.0;
      case 'buy':
      default:
        return 500000.0;
    }
  }

  double getPriceMax() {
    final currentState = _getCurrentPageState();
    switch (currentState.filters.purpose) {
      case 'rent':
        return 500000.0;
      case 'buy':
      default:
        return 150000000.0;
    }
  }

  String getPriceLabel() {
    final currentState = _getCurrentPageState();
    switch (currentState.filters.purpose) {
      case 'rent':
        return 'Price per month';
      case 'buy':
      default:
        return 'Property price';
    }
  }

  // Get query parameters for API calls
  Map<String, dynamic> getQueryParams() {
    final currentState = _getCurrentPageState();
    final params = <String, dynamic>{};
    final filter = currentState.filters;
    
    if (currentState.searchQuery?.isNotEmpty == true) {
      params['q'] = currentState.searchQuery;
    }
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
    
    // *** THE FIX: Get location from the single source of truth ***
    if (currentState.selectedLocation != null) {
      params['lat'] = currentState.selectedLocation!.latitude;
      params['lng'] = currentState.selectedLocation!.longitude;
    }
    
    if (filter.radiusKm != null) params['radius'] = filter.radiusKm;
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
    final currentState = _getCurrentPageState();
    final filter = currentState.filters;
    
    if (currentState.searchQuery?.isNotEmpty == true) {
      summary.add('Search: "${currentState.searchQuery}"');
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
  bool get hasActiveFilters => _getCurrentPageState().hasActiveFilters;
  
  // Get count of active filters
  int get activeFiltersCount => _getCurrentPageState().activeFiltersCount;
  
  // Check if location is set
  bool get hasLocation => _getCurrentPageState().hasLocation;

  // Get location display text
  String get locationDisplayText => _getCurrentPageState().locationDisplayText;

  // Method to set property IDs for favorites filtering
  void setPropertyIds(List<int> ids) {
    final currentPageType = _pageStateService.currentPageType.value;
    final currentState = _getCurrentPageState();
    final updatedFilters = currentState.filters.copyWith(propertyIds: ids);
    _pageStateService.updatePageFilters(currentPageType, updatedFilters);
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
