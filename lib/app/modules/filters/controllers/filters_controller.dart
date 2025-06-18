import 'package:get/get.dart';

class FiltersController extends GetxController {
  // Purpose selection
  final RxString selectedPurpose = 'Buy'.obs;
  
  // Budget range
  final RxDouble minBudget = 500000.0.obs; // Default for Buy
  final RxDouble maxBudget = 5000000.0.obs;
  
  // Property types
  final RxList<String> selectedPropertyTypes = <String>[].obs;
  
  // Bedrooms and Bathrooms
  final RxString selectedBedrooms = 'Any'.obs;
  final RxString selectedBathrooms = 'Any'.obs;
  
  // Area range
  final RxDouble minArea = 500.0.obs;
  final RxDouble maxArea = 2000.0.obs;
  
  // Amenities
  final RxList<String> selectedAmenities = <String>[].obs;
  
  // Location
  final RxString selectedLocation = ''.obs;
  
  // Filtered properties count (mock for now)
  final RxInt filteredPropertiesCount = 156.obs;

  void setPurpose(String purpose) {
    selectedPurpose.value = purpose;
    _updateBudgetRangeForPurpose();
    selectedPropertyTypes.clear();
    selectedAmenities.clear();
    _updateFilteredCount();
  }

  void _updateBudgetRangeForPurpose() {
    switch (selectedPurpose.value) {
      case 'Stay':
        minBudget.value = 500.0;
        maxBudget.value = 5000.0;
        break;
      case 'Rent':
        minBudget.value = 5000.0;
        maxBudget.value = 500000.0;
        break;
      case 'Buy':
        minBudget.value = 500000.0;
        maxBudget.value = 50000000.0;
        break;
    }
  }

  double getBudgetMin() {
    switch (selectedPurpose.value) {
      case 'Stay':
        return 500.0;
      case 'Rent':
        return 5000.0;
      case 'Buy':
        return 500000.0;
      default:
        return 500000.0;
    }
  }

  double getBudgetMax() {
    switch (selectedPurpose.value) {
      case 'Stay':
        return 5000.0;
      case 'Rent':
        return 500000.0;
      case 'Buy':
        return 50000000.0;
      default:
        return 50000000.0;
    }
  }

  void setBudgetRange(double min, double max) {
    minBudget.value = min;
    maxBudget.value = max;
    _updateFilteredCount();
  }

  void togglePropertyType(String type) {
    if (selectedPropertyTypes.contains(type)) {
      selectedPropertyTypes.remove(type);
    } else {
      selectedPropertyTypes.add(type);
    }
    _updateFilteredCount();
  }

  void setBedrooms(String bedrooms) {
    selectedBedrooms.value = bedrooms;
    _updateFilteredCount();
  }

  void setBathrooms(String bathrooms) {
    selectedBathrooms.value = bathrooms;
    _updateFilteredCount();
  }

  void setAreaRange(double min, double max) {
    minArea.value = min;
    maxArea.value = max;
    _updateFilteredCount();
  }

  void toggleAmenity(String amenity) {
    if (selectedAmenities.contains(amenity)) {
      selectedAmenities.remove(amenity);
    } else {
      selectedAmenities.add(amenity);
    }
    _updateFilteredCount();
  }

  void setLocation(String location) {
    selectedLocation.value = location;
    _updateFilteredCount();
  }

  void clearAllFilters() {
    selectedPurpose.value = 'Buy';
    _updateBudgetRangeForPurpose();
    selectedPropertyTypes.clear();
    selectedBedrooms.value = 'Any';
    selectedBathrooms.value = 'Any';
    minArea.value = 500.0;
    maxArea.value = 2000.0;
    selectedAmenities.clear();
    selectedLocation.value = '';
    filteredPropertiesCount.value = 156;
  }

  void applyFilters() {
    // In a real app, this would apply filters to the property list
    // For now, just go back to the previous screen
    Get.back();
    
    Get.snackbar(
      'Filters Applied',
      'Showing ${filteredPropertiesCount.value} properties',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  void _updateFilteredCount() {
    // Mock logic to update filtered count based on selected filters
    int count = 156;
    
    // Reduce count based on filters
    if (selectedPropertyTypes.isNotEmpty) count = (count * 0.8).round();
    if (selectedBedrooms.value != 'Any') count = (count * 0.7).round();
    if (selectedBathrooms.value != 'Any') count = (count * 0.6).round();
    if (selectedAmenities.isNotEmpty) count = (count * 0.5).round();
    if (selectedLocation.value.isNotEmpty) count = (count * 0.4).round();
    
    filteredPropertiesCount.value = count.clamp(1, 156);
  }
} 