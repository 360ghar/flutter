import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../data/models/unified_filter_model.dart';
import '../utils/debug_logger.dart';

class PropertyFilterController extends GetxController {
  // Storage instance
  final _storage = GetStorage();
  
  // Central filter state
  final Rx<UnifiedFilterModel> currentFilter = UnifiedFilterModel.initial().obs;
  
  // Location state
  final Rx<LocationData?> selectedLocation = Rx<LocationData?>(null);
  
  // UI state
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedFilters();
    _setupListeners();
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
    DebugLogger.info('Price range updated: ₹$min - ₹$max');
  }

  void updateBedrooms(int? min, int? max) {
    currentFilter.value = currentFilter.value.copyWith(
      bedroomsMin: min,
      bedroomsMax: max,
    );
    DebugLogger.info('Bedrooms updated: $min - $max');
  }

  void updateBathrooms(int? min, int? max) {
    currentFilter.value = currentFilter.value.copyWith(
      bathroomsMin: min,
      bathroomsMax: max,
    );
    DebugLogger.info('Bathrooms updated: $min - $max');
  }

  void updateArea(double? min, double? max) {
    currentFilter.value = currentFilter.value.copyWith(
      areaMin: min,
      areaMax: max,
    );
    DebugLogger.info('Area updated: $min - $max sqft');
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

  void updateRadius(double radiusKm) {
    currentFilter.value = currentFilter.value.copyWith(radiusKm: radiusKm);
    DebugLogger.info('Search radius updated: ${radiusKm}km');
  }

  void updateSortBy(String sortBy) {
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
    DebugLogger.info('Floor range updated: $min - $max');
  }

  void updateMaxAge(int? ageInYears) {
    currentFilter.value = currentFilter.value.copyWith(ageMax: ageInYears);
    DebugLogger.info('Max age updated: $ageInYears years');
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    // Search query can be added to city/locality for text-based search
    if (query.isNotEmpty) {
      currentFilter.value = currentFilter.value.copyWith(city: query);
    } else {
      currentFilter.value = currentFilter.value.copyWith(
        city: selectedLocation.value?.city,
      );
    }
  }

  // Reset methods
  void resetFilters() {
    currentFilter.value = UnifiedFilterModel.initial();
    searchQuery.value = '';
    // Keep location as it is
    _updateLocationInFilter();
    DebugLogger.info('All filters reset');
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

  // Method to set property IDs for favorites filtering
  void setPropertyIds(List<int> ids) {
    currentFilter.value = currentFilter.value.copyWith(propertyIds: ids);
  }
}