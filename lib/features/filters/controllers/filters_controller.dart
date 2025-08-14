import 'dart:async';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/data/models/filters_model.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/controllers/location_controller.dart';

class FiltersController extends GetxController {
  static FiltersController get instance => Get.find<FiltersController>();

  final GetStorage _storage = GetStorage();
  final LocationController _locationController = Get.find<LocationController>();

  // Reactive filters state
  final Rx<FiltersModel> _filters = FiltersModel().obs;
  FiltersModel get filters => _filters.value;
  Rx<FiltersModel> get filtersRx => _filters;

  // Debounce timer for text search
  Timer? _searchDebouncer;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  // Loading states
  final RxBool isApplyingFilters = false.obs;
  final RxBool isLoadingLocation = false.obs;

  // Current location cache
  Position? _currentPosition;

  @override
  void onInit() {
    super.onInit();
    _loadSavedFilters();
    
    // Listen to location updates
    _locationController.currentPosition.listen((position) {
      if (position != null) {
        _currentPosition = position;
      }
    });
  }

  @override
  void onClose() {
    _searchDebouncer?.cancel();
    super.onClose();
  }

  // Load saved filters from storage
  void _loadSavedFilters() {
    try {
      final savedFilters = _storage.read('filters');
      if (savedFilters != null) {
        _filters.value = FiltersModel.fromJson(Map<String, dynamic>.from(savedFilters));
        DebugLogger.success('📂 Loaded saved filters');
      }
    } catch (e) {
      DebugLogger.error('❌ Failed to load saved filters: $e');
    }
  }

  // Save filters to storage
  void _saveFilters() {
    try {
      _storage.write('filters', _filters.value.toJson());
      DebugLogger.success('💾 Filters saved to storage');
    } catch (e) {
      DebugLogger.error('❌ Failed to save filters: $e');
    }
  }

  // Update filters and save
  void updateFilters(FiltersModel newFilters) {
    _filters.value = newFilters;
    _saveFilters();
  }

  // Text search with debounce
  void updateSearchQuery(String? query) {
    _searchDebouncer?.cancel();
    
    if (query == null || query.isEmpty) {
      _updateFilter((filters) => filters.copyWith(q: null));
      return;
    }

    _searchDebouncer = Timer(_searchDebounceDelay, () {
      _updateFilter((filters) => filters.copyWith(q: query));
    });
  }

  // Location filters
  void updateLocation({
    required double latitude,
    required double longitude,
    int? radius,
  }) {
    _updateFilter((filters) => filters.copyWith(
      lat: latitude,
      lng: longitude,
      radius: radius ?? filters.radius,
      sortBy: 'distance', // Always sort by distance when location is set
    ));
  }

  void updateRadius(int radius) {
    _updateFilter((filters) => filters.copyWith(radius: radius));
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
        updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          radius: filters.radius ?? 5,
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

  // Property type filters
  void updatePropertyTypes(List<PropertyType>? types) {
    _updateFilter((filters) => filters.copyWith(propertyType: types));
  }

  void togglePropertyType(PropertyType type) {
    final currentTypes = List<PropertyType>.from(filters.propertyType ?? []);
    
    if (currentTypes.contains(type)) {
      currentTypes.remove(type);
    } else {
      currentTypes.add(type);
    }
    
    updatePropertyTypes(currentTypes.isEmpty ? null : currentTypes);
  }

  // Purpose filter
  void updatePurpose(PropertyPurpose? purpose) {
    _updateFilter((filters) => filters.copyWith(purpose: purpose));
  }

  // Price filters
  void updatePriceRange({double? min, double? max}) {
    _updateFilter((filters) => filters.copyWith(
      priceMin: min,
      priceMax: max,
    ));
  }

  // Room filters
  void updateBedroomRange({int? min, int? max}) {
    _updateFilter((filters) => filters.copyWith(
      bedroomsMin: min,
      bedroomsMax: max,
    ));
  }

  void updateBathroomRange({int? min, int? max}) {
    _updateFilter((filters) => filters.copyWith(
      bathroomsMin: min,
      bathroomsMax: max,
    ));
  }

  // Area filter
  void updateAreaRange({double? min, double? max}) {
    _updateFilter((filters) => filters.copyWith(
      areaMin: min,
      areaMax: max,
    ));
  }

  // Location metadata
  void updateCity(String? city) {
    _updateFilter((filters) => filters.copyWith(city: city));
  }

  void updateLocality(String? locality) {
    _updateFilter((filters) => filters.copyWith(locality: locality));
  }

  void updatePincode(String? pincode) {
    _updateFilter((filters) => filters.copyWith(pincode: pincode));
  }

  // Amenities
  void updateAmenities(List<String>? amenities) {
    _updateFilter((filters) => filters.copyWith(amenities: amenities));
  }

  void toggleAmenity(String amenity) {
    final currentAmenities = List<String>.from(filters.amenities ?? []);
    
    if (currentAmenities.contains(amenity)) {
      currentAmenities.remove(amenity);
    } else {
      currentAmenities.add(amenity);
    }
    
    updateAmenities(currentAmenities.isEmpty ? null : currentAmenities);
  }

  // Additional filters
  void updateParkingSpaces(int? min) {
    _updateFilter((filters) => filters.copyWith(parkingSpacesMin: min));
  }

  void updateFloorRange({int? min, int? max}) {
    _updateFilter((filters) => filters.copyWith(
      floorNumberMin: min,
      floorNumberMax: max,
    ));
  }

  void updateMaxAge(int? maxAge) {
    _updateFilter((filters) => filters.copyWith(ageMax: maxAge));
  }

  // Short-stay filters
  void updateStayDates({String? checkIn, String? checkOut}) {
    _updateFilter((filters) => filters.copyWith(
      checkIn: checkIn,
      checkOut: checkOut,
    ));
  }

  void updateGuests(int? guests) {
    _updateFilter((filters) => filters.copyWith(guests: guests));
  }

  // Sorting
  void updateSortBy(String sortBy) {
    _updateFilter((filters) => filters.copyWith(sortBy: sortBy));
  }

  // Reset all filters
  void resetFilters() {
    _filters.value = FiltersModel();
    _saveFilters();
    
    Get.snackbar(
      'Filters Reset',
      'All filters have been cleared',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  // Apply filters (used by controllers to trigger API calls)
  void applyFilters() {
    isApplyingFilters.value = true;
    
    // Trigger a small delay to show loading state
    Future.delayed(const Duration(milliseconds: 100), () {
      isApplyingFilters.value = false;
    });
    
    DebugLogger.api('🔍 Applying filters: ${filters.cacheKey}');
  }

  // Helper to update filters and save
  void _updateFilter(FiltersModel Function(FiltersModel) updater) {
    _filters.value = updater(_filters.value);
    _saveFilters();
  }

  // Get query parameters for API calls
  Map<String, dynamic> getQueryParams() {
    return filters.toQueryParams();
  }

  // Check if location is set
  bool get hasLocation => filters.lat != null && filters.lng != null;

  // Get location display text
  String get locationDisplayText {
    if (filters.city != null) {
      return filters.locality != null 
          ? '${filters.locality}, ${filters.city}'
          : filters.city!;
    } else if (hasLocation) {
      return 'Current Location';
    }
    return 'All Locations';
  }

  // Get active filter count
  int get activeFilterCount {
    int count = 0;
    
    if (filters.q != null && filters.q!.isNotEmpty) count++;
    if (filters.propertyType?.isNotEmpty == true) count++;
    if (filters.purpose != null) count++;
    if (filters.priceMin != null || filters.priceMax != null) count++;
    if (filters.bedroomsMin != null || filters.bedroomsMax != null) count++;
    if (filters.bathroomsMin != null || filters.bathroomsMax != null) count++;
    if (filters.areaMin != null || filters.areaMax != null) count++;
    if (filters.amenities?.isNotEmpty == true) count++;
    if (filters.parkingSpacesMin != null) count++;
    if (filters.floorNumberMin != null || filters.floorNumberMax != null) count++;
    if (filters.ageMax != null) count++;
    if (filters.checkIn != null || filters.checkOut != null) count++;
    if (filters.guests != null) count++;
    
    return count;
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

  // Property type display names
  static const Map<PropertyType, String> propertyTypeDisplayNames = {
    PropertyType.house: 'House',
    PropertyType.apartment: 'Apartment',
    PropertyType.builderFloor: 'Builder Floor',
    PropertyType.room: 'Room',
  };

  // Purpose display names
  static const Map<PropertyPurpose, String> purposeDisplayNames = {
    PropertyPurpose.buy: 'Buy',
    PropertyPurpose.rent: 'Rent',
    PropertyPurpose.shortStay: 'Short Stay',
  };

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