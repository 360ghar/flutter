import 'package:get/get.dart';
import '../data/models/property_model.dart';
import 'property_controller.dart';

class SwipeController extends GetxController {
  final PropertyController _propertyController = Get.find<PropertyController>();
  
  final RxList<PropertyModel> currentStack = <PropertyModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialStack();
  }

  void _loadInitialStack() {
    isLoading.value = true;
    
    // Get all properties and apply filters
    final allProperties = _propertyController.properties;
    final filteredProperties = _applyFilters(allProperties);
    
    // Filter out already liked or passed properties
    final availableProperties = filteredProperties
        .where((property) => 
            !_propertyController.isFavourite(property.id) && 
            !_propertyController.isPassed(property.id))
        .toList();
    
    currentStack.value = availableProperties.take(10).toList();
    currentIndex.value = 0;
    isLoading.value = false;
  }

  void swipeLeft(PropertyModel property) {
    print('Passed on: ${property.title}');
    _propertyController.addToPassedProperties(property.id);
    _nextProperty();
  }

  void swipeRight(PropertyModel property) {
    print('Liked: ${property.title}');
    _propertyController.addToFavourites(property.id);
    _nextProperty();
  }

  void swipeUp(PropertyModel property) {
    print('Viewing details for: ${property.title}');
    Get.toNamed('/property-details', arguments: property);
  }

  void superLike(PropertyModel property) {
    print('Super liked: ${property.title}');
    _propertyController.addToFavourites(property.id);
    Get.snackbar(
      'Super Liked!',
      'You super liked ${property.title}',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
    _nextProperty();
  }

  void _nextProperty() {
    if (currentIndex.value < currentStack.length - 1) {
      currentIndex.value++;
    } else {
      // Load more properties or show end message
      _loadMoreProperties();
    }
  }

  void _loadMoreProperties() {
    // In a real app, this would fetch more properties from the API
    final allProperties = _propertyController.properties;
    final filteredProperties = _applyFilters(allProperties);
    
    final availableProperties = filteredProperties
        .where((property) => 
            !_propertyController.isFavourite(property.id) && 
            !_propertyController.isPassed(property.id) &&
            !currentStack.any((stackProperty) => stackProperty.id == property.id))
        .toList();
    
    if (availableProperties.isNotEmpty) {
      currentStack.addAll(availableProperties.take(5));
    } else {
      Get.snackbar(
        'No More Properties',
        'You\'ve seen all available properties matching your filters!',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    }
  }

  PropertyModel? get currentProperty {
    if (currentIndex.value < currentStack.length) {
      return currentStack[currentIndex.value];
    }
    return null;
  }

  List<PropertyModel> get visibleCards {
    final List<PropertyModel> cards = [];
    for (int i = currentIndex.value; i < currentIndex.value + 3 && i < currentStack.length; i++) {
      cards.add(currentStack[i]);
    }
    return cards;
  }

  void resetStack() {
    _loadInitialStack();
  }

  List<PropertyModel> _applyFilters(List<PropertyModel> properties) {
    return properties.where((property) {
      // Purpose filter
      if (!_matchesPurpose(property)) {
        return false;
      }

      // Price filter (adjusted based on purpose)
      final adjustedPrice = _getAdjustedPrice(property);
      if (adjustedPrice < _propertyController.minPrice.value || 
          adjustedPrice > _propertyController.maxPrice.value) {
        return false;
      }

      // Bedrooms filter (skip for Stay mode)
      if (_propertyController.selectedPurpose.value != 'Stay') {
        if (property.bedrooms < _propertyController.minBedrooms.value || 
            property.bedrooms > _propertyController.maxBedrooms.value) {
          return false;
        }
      }

      // Property type filter
      if (_propertyController.propertyType.value != 'All' && 
          !_matchesPropertyType(property)) {
        return false;
      }

      // Amenities filter
      if (_propertyController.selectedAmenities.isNotEmpty) {
        final hasAllAmenities = _propertyController.selectedAmenities
            .every((amenity) => property.amenities.contains(amenity));
        if (!hasAllAmenities) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _matchesPurpose(PropertyModel property) {
    switch (_propertyController.selectedPurpose.value) {
      case 'Stay':
        return property.propertyType.toLowerCase().contains('apartment') ||
               property.propertyType.toLowerCase().contains('studio') ||
               property.price < 5000000;
      case 'Rent':
        return true;
      case 'Buy':
      default:
        return true;
    }
  }

  double _getAdjustedPrice(PropertyModel property) {
    switch (_propertyController.selectedPurpose.value) {
      case 'Stay':
        return (property.price / 365 / 100).clamp(500.0, 50000.0);
      case 'Rent':
        return (property.price * 0.001).clamp(5000.0, 500000.0);
      case 'Buy':
      default:
        return property.price;
    }
  }

  bool _matchesPropertyType(PropertyModel property) {
    final selectedType = _propertyController.propertyType.value;
    
    if (_propertyController.selectedPurpose.value == 'Stay') {
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
} 