import 'package:get/get.dart';
import '../data/models/property_card_model.dart';
import '../data/models/property_model.dart';
import '../utils/debug_logger.dart';

class PropertyFilterController extends GetxController {
  // Filter properties
  final RxString selectedPurpose = 'Buy'.obs; // Buy, Rent, Stay
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 150000000.0.obs; // ₹15Cr to accommodate all properties
  final RxInt minBedrooms = 0.obs;
  final RxInt maxBedrooms = 10.obs;
  final RxString propertyType = 'All'.obs;
  final RxList<String> selectedAmenities = <String>[].obs;
  
  // Search state
  final RxString searchQuery = ''.obs;
  final RxBool hasActiveFilters = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeFilters();
    _setupFilterWatchers();
  }

  void _initializeFilters() {
    selectedPurpose.value = 'Buy';
    _updatePriceRangeForPurpose();
    minBedrooms.value = 0;
    maxBedrooms.value = 10;
    propertyType.value = 'All';
    selectedAmenities.clear();
    _updateHasActiveFilters();
  }

  void _setupFilterWatchers() {
    // Watch for filter changes to update hasActiveFilters
    ever(selectedPurpose, (_) => _updateHasActiveFilters());
    ever(minPrice, (_) => _updateHasActiveFilters());
    ever(maxPrice, (_) => _updateHasActiveFilters());
    ever(minBedrooms, (_) => _updateHasActiveFilters());
    ever(maxBedrooms, (_) => _updateHasActiveFilters());
    ever(propertyType, (_) => _updateHasActiveFilters());
    ever(selectedAmenities, (_) => _updateHasActiveFilters());
    ever(searchQuery, (_) => _updateHasActiveFilters());
  }

  void _updateHasActiveFilters() {
    hasActiveFilters.value = searchQuery.value.isNotEmpty ||
        selectedPurpose.value != 'Buy' ||
        minPrice.value != getPriceMin() ||
        maxPrice.value != getPriceMax() ||
        minBedrooms.value != 0 ||
        maxBedrooms.value != 10 ||
        propertyType.value != 'All' ||
        selectedAmenities.isNotEmpty;
  }

  // Filter application methods
  List<PropertyCardModel> applyFilters(List<PropertyCardModel> propertyList) {
    DebugLogger.info('🔍 Applying filters to ${propertyList.length} properties');
    DebugLogger.info('📋 Purpose: ${selectedPurpose.value}');
    DebugLogger.info('💰 Price range: ${minPrice.value} - ${maxPrice.value}');
    DebugLogger.info('🛏️ Bedrooms range: ${minBedrooms.value} - ${maxBedrooms.value}');
    DebugLogger.info('🏠 Property type: ${propertyType.value}');
    DebugLogger.info('🔍 Search query: "${searchQuery.value}"');
    
    List<PropertyCardModel> filteredList = propertyList;
    
    // Apply search query filter first
    if (searchQuery.value.isNotEmpty) {
      filteredList = _applySearchFilter(filteredList);
    }
    
    // Apply other filters
    filteredList = filteredList.where((property) {
      // Purpose filter
      if (!_matchesPurpose(property)) {
        DebugLogger.info('❌ Property ${property.id} (${property.title}) filtered out by purpose');
        return false;
      }

      // Price filter (adjusted based on purpose)
      final adjustedPrice = _getAdjustedPrice(property);
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
      if (propertyType.value != 'All' && !_matchesPropertyType(property)) {
        DebugLogger.info('❌ Property ${property.id} (${property.title}) filtered out by type: ${property.propertyTypeString}');
        return false;
      }

      DebugLogger.info('✅ Property ${property.id} (${property.title}) passed all filters');
      return true;
    }).toList();
    
    DebugLogger.info('✅ After filtering: ${filteredList.length} properties');
    return filteredList;
  }

  List<PropertyCardModel> _applySearchFilter(List<PropertyCardModel> propertyList) {
    final query = searchQuery.value.toLowerCase().trim();
    return propertyList.where((property) {
      final titleMatch = property.title.toLowerCase().contains(query);
      final cityMatch = property.city?.toLowerCase().contains(query) ?? false;
      final localityMatch = property.locality?.toLowerCase().contains(query) ?? false;
      final stateMatch = property.state?.toLowerCase().contains(query) ?? false;
      
      return titleMatch || cityMatch || localityMatch || stateMatch;
    }).toList();
  }

  bool _matchesPurpose(PropertyCardModel property) {
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

  double _getAdjustedPrice(PropertyCardModel property) {
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

  bool _matchesPropertyType(PropertyCardModel property) {
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

  // Filter update methods
  void updateFilters({
    String? selectedPurposeValue,
    double? minPriceValue,
    double? maxPriceValue,
    int? minBedroomsValue,
    int? maxBedroomsValue,
    String? propertyTypeValue,
    List<String>? selectedAmenitiesValue,
    String? searchQueryValue,
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
    if (searchQueryValue != null) searchQuery.value = searchQueryValue;
  }

  void clearFilters() {
    selectedPurpose.value = 'Buy';
    _updatePriceRangeForPurpose();
    minBedrooms.value = 0;
    maxBedrooms.value = 10;
    propertyType.value = 'All';
    selectedAmenities.clear();
    searchQuery.value = '';
  }

  void clearSearch() {
    searchQuery.value = '';
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

  // Helper methods for price ranges
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

  // Get filters as map for API calls or analytics
  Map<String, dynamic> getFiltersMap() {
    return {
      'purpose': selectedPurpose.value,
      'min_price': minPrice.value,
      'max_price': maxPrice.value,
      'min_bedrooms': minBedrooms.value,
      'max_bedrooms': maxBedrooms.value,
      'property_type': propertyType.value,
      'amenities': selectedAmenities.toList(),
      'search_query': searchQuery.value,
    };
  }

  // Get summary of active filters for display
  List<String> getActiveFiltersSummary() {
    List<String> summary = [];
    
    if (searchQuery.value.isNotEmpty) {
      summary.add('Search: "${searchQuery.value}"');
    }
    
    if (selectedPurpose.value != 'Buy') {
      summary.add('Purpose: ${selectedPurpose.value}');
    }
    
    if (minPrice.value != getPriceMin() || maxPrice.value != getPriceMax()) {
      summary.add('Price: ₹${minPrice.value.toInt()} - ₹${maxPrice.value.toInt()}');
    }
    
    if (minBedrooms.value != 0 || maxBedrooms.value != 10) {
      summary.add('Bedrooms: ${minBedrooms.value} - ${maxBedrooms.value}');
    }
    
    if (propertyType.value != 'All') {
      summary.add('Type: ${propertyType.value}');
    }
    
    if (selectedAmenities.isNotEmpty) {
      summary.add('Amenities: ${selectedAmenities.length} selected');
    }
    
    return summary;
  }

  // Count of active filters
  int get activeFiltersCount {
    int count = 0;
    
    if (searchQuery.value.isNotEmpty) count++;
    if (selectedPurpose.value != 'Buy') count++;
    if (minPrice.value != getPriceMin() || maxPrice.value != getPriceMax()) count++;
    if (minBedrooms.value != 0 || maxBedrooms.value != 10) count++;
    if (propertyType.value != 'All') count++;
    if (selectedAmenities.isNotEmpty) count++;
    
    return count;
  }
}