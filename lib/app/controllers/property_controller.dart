import 'package:get/get.dart';
import '../data/models/property_model.dart';
import '../data/repositories/property_repository.dart';

class PropertyController extends GetxController {
  final PropertyRepository _repository;
  
  final RxList<PropertyModel> properties = <PropertyModel>[].obs;
  final RxList<PropertyModel> favouriteProperties = <PropertyModel>[].obs;
  final RxList<PropertyModel> passedProperties = <PropertyModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

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
    fetchProperties();
    fetchFavouriteProperties();
    fetchPassedProperties();
  }

  Future<void> fetchProperties() async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _repository.getProperties();
      properties.value = result;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFavouriteProperties() async {
    try {
      print('PropertyController: Fetching favourite properties...');
      final result = await _repository.getFavouriteProperties();
      print('PropertyController: Received ${result.length} favourite properties');
      favouriteProperties.value = result;
      print('PropertyController: favouriteProperties updated, current length: ${favouriteProperties.length}');
    } catch (e) {
      print('PropertyController: Error fetching favourites: $e');
      error.value = e.toString();
    }
  }

  Future<void> fetchPassedProperties() async {
    try {
      final result = await _repository.getPassedProperties();
      passedProperties.value = result;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> addToFavourites(String propertyId) async {
    try {
      await _repository.addToFavourites(propertyId);
      await fetchFavouriteProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> removeFromFavourites(String propertyId) async {
    try {
      await _repository.removeFromFavourites(propertyId);
      await fetchFavouriteProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> addToPassedProperties(String propertyId) async {
    try {
      await _repository.addToPassedProperties(propertyId);
      await fetchPassedProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> removeFromPassedProperties(String propertyId) async {
    try {
      await _repository.removeFromPassedProperties(propertyId);
      await fetchPassedProperties();
    } catch (e) {
      error.value = e.toString();
    }
  }

  bool isFavourite(String propertyId) {
    return favouriteProperties.any((property) => property.id == propertyId);
  }

  bool isPassed(String propertyId) {
    return passedProperties.any((property) => property.id == propertyId);
  }

  PropertyModel? getPropertyById(String id) {
    try {
      return properties.firstWhere((property) => property.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filter methods
  List<PropertyModel> getFilteredFavourites() {
    print('PropertyController: getFilteredFavourites called, raw favourites: ${favouriteProperties.length}');
    final filtered = _applyFilters(favouriteProperties);
    print('PropertyController: After filtering: ${filtered.length} properties');
    return filtered;
  }

  List<PropertyModel> getFilteredPassed() {
    return _applyFilters(passedProperties);
  }

  List<PropertyModel> _applyFilters(List<PropertyModel> propertyList) {
    print('PropertyController: Applying filters to ${propertyList.length} properties');
    print('PropertyController: Purpose: ${selectedPurpose.value}');
    print('PropertyController: Price range: ${minPrice.value} - ${maxPrice.value}');
    print('PropertyController: Bedrooms range: ${minBedrooms.value} - ${maxBedrooms.value}');
    print('PropertyController: Property type: ${propertyType.value}');
    
    return propertyList.where((property) {
      // Purpose filter - for now, we'll use some logic based on property type and price
      if (!_matchesPurpose(property)) {
        print('PropertyController: Property ${property.id} (${property.title}) filtered out by purpose');
        return false;
      }

      // Price filter (adjusted based on purpose)
      final adjustedPrice = _getAdjustedPrice(property);
      if (adjustedPrice < minPrice.value || adjustedPrice > maxPrice.value) {
        print('PropertyController: Property ${property.id} (${property.title}) filtered out by price: $adjustedPrice');
        return false;
      }

      // Bedrooms filter (skip for Stay mode if less than 1 bedroom)
      if (selectedPurpose.value != 'Stay') {
        if (property.bedrooms < minBedrooms.value || property.bedrooms > maxBedrooms.value) {
          print('PropertyController: Property ${property.id} (${property.title}) filtered out by bedrooms: ${property.bedrooms}');
          return false;
        }
      }

      // Property type filter
      if (propertyType.value != 'All' && !_matchesPropertyType(property)) {
        print('PropertyController: Property ${property.id} (${property.title}) filtered out by type: ${property.propertyType}');
        return false;
      }

      // Amenities filter
      if (selectedAmenities.isNotEmpty) {
        final hasAllAmenities = selectedAmenities.every((amenity) => property.amenities.contains(amenity));
        if (!hasAllAmenities) {
          print('PropertyController: Property ${property.id} (${property.title}) filtered out by amenities');
          return false;
        }
      }

      print('PropertyController: Property ${property.id} (${property.title}) passed all filters');
      return true;
    }).toList();
  }

  bool _matchesPurpose(PropertyModel property) {
    switch (selectedPurpose.value) {
      case 'Stay':
        // Stay properties should be smaller, furnished apartments/hotels
        return property.propertyType.toLowerCase().contains('apartment') ||
               property.propertyType.toLowerCase().contains('studio') ||
               property.price < 5000000; // Less than 50L for stay properties
      case 'Rent':
        // Rent properties - most properties can be rented
        return true;
      case 'Buy':
      default:
        // Buy properties - all properties available for purchase
        return true;
    }
  }

  double _getAdjustedPrice(PropertyModel property) {
    switch (selectedPurpose.value) {
      case 'Stay':
        // Convert property price to estimated per-night rate
        return (property.price / 365 / 100).clamp(500.0, 50000.0); // Rough estimate
      case 'Rent':
        // Convert property price to estimated monthly rent
        return (property.price * 0.001).clamp(5000.0, 500000.0); // Rough 0.1% of property value per month
      case 'Buy':
      default:
        return property.price;
    }
  }

  bool _matchesPropertyType(PropertyModel property) {
    final selectedType = propertyType.value;
    
    if (selectedPurpose.value == 'Stay') {
      // For Stay mode, map property types differently
      switch (selectedType) {
        case 'Hotel':
          return property.propertyType.toLowerCase().contains('apartment') ||
                 property.propertyType.toLowerCase().contains('studio');
        case 'Resort':
          return property.propertyType.toLowerCase().contains('villa') ||
                 property.propertyType.toLowerCase().contains('penthouse');
        default:
          return property.propertyType == selectedType;
      }
    }
    
    return property.propertyType == selectedType;
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