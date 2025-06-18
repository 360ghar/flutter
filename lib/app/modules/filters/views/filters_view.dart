import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/filters_controller.dart';
import '../../../utils/theme.dart';

class FiltersView extends GetView<FiltersController> {
  const FiltersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Filters',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.clearAllFilters(),
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: AppTheme.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Purpose Section
            _buildSectionTitle('I\'m looking to'),
            const SizedBox(height: 12),
            Obx(() => _buildPurposeSelector()),
            const SizedBox(height: 24),

            // Budget Section
            Obx(() => _buildBudgetSection()),
            const SizedBox(height: 24),

            // Property Type Section
            _buildSectionTitle('Property Type'),
            const SizedBox(height: 12),
            Obx(() => _buildPropertyTypeSelector()),
            const SizedBox(height: 24),

            // Bedrooms Section
            _buildSectionTitle('Bedrooms'),
            const SizedBox(height: 12),
            Obx(() => _buildBedroomsSelector()),
            const SizedBox(height: 24),

            // Bathrooms Section (for Buy/Rent only)
            Obx(() {
              if (controller.selectedPurpose.value != 'Stay') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Bathrooms'),
                    const SizedBox(height: 12),
                    _buildBathroomsSelector(),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),

            // Area Section (for Buy/Rent only)
            Obx(() {
              if (controller.selectedPurpose.value != 'Stay') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Area (sq ft)'),
                    const SizedBox(height: 12),
                    _buildAreaSlider(),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),

            // Amenities Section
            _buildSectionTitle('Amenities'),
            const SizedBox(height: 12),
            Obx(() => _buildAmenitiesSelector()),
            const SizedBox(height: 24),

            // Location Section
            _buildSectionTitle('Location'),
            const SizedBox(height: 12),
            _buildLocationSelector(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => controller.clearAllFilters(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryYellow),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    color: AppTheme.primaryYellow,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => controller.applyFilters(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Obx(() => Text(
                  'Show ${controller.filteredPropertiesCount.value} Properties',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildPurposeSelector() {
    final purposes = ['Buy', 'Rent', 'Stay'];
    
    return Row(
      children: purposes.map((purpose) {
        final isSelected = controller.selectedPurpose.value == purpose;
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.setPurpose(purpose),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryYellow : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryYellow : Colors.grey[300]!,
                ),
              ),
              child: Text(
                purpose,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetSection() {
    final purpose = controller.selectedPurpose.value;
    String budgetLabel = '';
    String minLabel = '';
    String maxLabel = '';
    
    switch (purpose) {
      case 'Stay':
        budgetLabel = 'Budget per night';
        minLabel = '₹${(controller.minBudget.value / 1000).toInt()}K';
        maxLabel = '₹${(controller.maxBudget.value / 1000).toInt()}K';
        break;
      case 'Rent':
        budgetLabel = 'Budget per month';
        minLabel = '₹${(controller.minBudget.value / 1000).toInt()}K';
        maxLabel = '₹${(controller.maxBudget.value / 100000).toInt()}L';
        break;
      case 'Buy':
        budgetLabel = 'Budget';
        minLabel = '₹${(controller.minBudget.value / 100000).toInt()}L';
        maxLabel = '₹${(controller.maxBudget.value / 10000000).toInt()}Cr';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(budgetLabel),
        const SizedBox(height: 16),
        RangeSlider(
          values: RangeValues(
            controller.minBudget.value,
            controller.maxBudget.value,
          ),
          min: controller.getBudgetMin(),
          max: controller.getBudgetMax(),
          divisions: 20,
          activeColor: AppTheme.primaryYellow,
          inactiveColor: Colors.grey[300],
          labels: RangeLabels(minLabel, maxLabel),
          onChanged: (values) => controller.setBudgetRange(values.start, values.end),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(minLabel, style: const TextStyle(color: Colors.grey)),
            Text(maxLabel, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyTypeSelector() {
    final purpose = controller.selectedPurpose.value;
    List<String> types = [];
    
    switch (purpose) {
      case 'Stay':
        types = ['Hotel', 'Resort', 'Apartment', 'Villa', 'Hostel', 'Guest House'];
        break;
      case 'Rent':
        types = ['Apartment', 'House', 'Villa', 'Studio', 'Room', 'Office'];
        break;
      case 'Buy':
        types = ['Apartment', 'House', 'Villa', 'Plot', 'Commercial', 'Office'];
        break;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = controller.selectedPropertyTypes.contains(type);
        return GestureDetector(
          onTap: () => controller.togglePropertyType(type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryYellow : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryYellow : Colors.grey[300]!,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBedroomsSelector() {
    final bedrooms = ['Any', '1', '2', '3', '4', '5+'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bedrooms.map((bedroom) {
        final isSelected = controller.selectedBedrooms.value == bedroom;
        return GestureDetector(
          onTap: () => controller.setBedrooms(bedroom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryYellow : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryYellow : Colors.grey[300]!,
              ),
            ),
            child: Text(
              bedroom,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBathroomsSelector() {
    final bathrooms = ['Any', '1', '2', '3', '4+'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bathrooms.map((bathroom) {
        final isSelected = controller.selectedBathrooms.value == bathroom;
        return GestureDetector(
          onTap: () => controller.setBathrooms(bathroom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryYellow : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryYellow : Colors.grey[300]!,
              ),
            ),
            child: Text(
              bathroom,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAreaSlider() {
    return Column(
      children: [
        RangeSlider(
          values: RangeValues(
            controller.minArea.value,
            controller.maxArea.value,
          ),
          min: 500,
          max: 5000,
          divisions: 18,
          activeColor: AppTheme.primaryYellow,
          inactiveColor: Colors.grey[300],
          labels: RangeLabels(
            '${controller.minArea.value.toInt()}',
            '${controller.maxArea.value.toInt()}',
          ),
          onChanged: (values) => controller.setAreaRange(values.start, values.end),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${controller.minArea.value.toInt()} sq ft',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              '${controller.maxArea.value.toInt()} sq ft',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenitiesSelector() {
    final purpose = controller.selectedPurpose.value;
    List<String> amenities = [];
    
    switch (purpose) {
      case 'Stay':
        amenities = ['WiFi', 'Pool', 'Gym', 'Spa', 'Restaurant', 'Room Service', 'Parking', 'AC'];
        break;
      case 'Rent':
      case 'Buy':
        amenities = ['Parking', 'Gym', 'Pool', 'Security', 'Elevator', 'Garden', 'Balcony', 'AC'];
        break;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((amenity) {
        final isSelected = controller.selectedAmenities.contains(amenity);
        return GestureDetector(
          onTap: () => controller.toggleAmenity(amenity),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryYellow : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.primaryYellow : Colors.grey[300]!,
              ),
            ),
            child: Text(
              amenity,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => Text(
              controller.selectedLocation.value.isEmpty 
                  ? 'Select location'
                  : controller.selectedLocation.value,
              style: TextStyle(
                color: controller.selectedLocation.value.isEmpty 
                    ? Colors.grey 
                    : Colors.black,
                fontSize: 16,
              ),
            )),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
} 