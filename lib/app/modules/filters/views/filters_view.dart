import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/filters_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../utils/app_colors.dart';

class FiltersView extends GetView<FiltersController> {
  const FiltersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'Filters',
          style: TextStyle(
            color: AppColors.appBarText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.activeFilterCount > 0 ? controller.resetFilters : null,
            child: Text(
              'Reset',
              style: TextStyle(
                color: controller.activeFilterCount > 0 
                    ? AppColors.primaryYellow 
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          // Active filters count
          Obx(() => Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${controller.activeFilterCount} filters active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (controller.hasLocation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.locationDisplayText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                  ),
              ],
            ),
          )),
          
          // Filters content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationSection(),
                  _buildSectionDivider(),
                  _buildPropertyTypeSection(),
                  _buildSectionDivider(),
                  _buildPurposeSection(),
                  _buildSectionDivider(),
                  _buildPriceSection(),
                  _buildSectionDivider(),
                  _buildRoomsSection(),
                  _buildSectionDivider(),
                  _buildAreaSection(),
                  _buildSectionDivider(),
                  _buildAmenitiesSection(),
                  _buildSectionDivider(),
                  _buildAdditionalFilters(),
                  const SizedBox(height: 100), // Space for apply button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildApplyButton(),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location'),
        const SizedBox(height: 16),
        
        // Current location button
        Obx(() => ListTile(
          leading: Icon(
            Icons.my_location,
            color: controller.isLoadingLocation.value 
                ? AppColors.textSecondary 
                : AppColors.primaryYellow,
          ),
          title: Text(
            'Use Current Location',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: controller.hasLocation
              ? Text('Using your location', style: TextStyle(color: AppColors.textSecondary))
              : null,
          trailing: controller.isLoadingLocation.value
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                  ),
                )
              : null,
          onTap: controller.isLoadingLocation.value ? null : controller.setCurrentLocation,
        )),
        
        // Search radius
        if (controller.hasLocation) ...[
          const SizedBox(height: 16),
          Text(
            'Search Radius: ${controller.filters.radius ?? 5} km',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Slider(
            value: (controller.filters.radius ?? 5).toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: AppColors.primaryYellow,
            onChanged: (value) => controller.updateRadius(value.toInt()),
          )),
        ],
      ],
    );
  }

  Widget _buildPropertyTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Property Type'),
        const SizedBox(height: 16),
        Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: PropertyType.values.map((type) {
            final isSelected = controller.filters.propertyType?.contains(type) ?? false;
            return FilterChip(
              label: Text(FiltersController.propertyTypeDisplayNames[type] ?? type.name),
              selected: isSelected,
              onSelected: (selected) => controller.togglePropertyType(type),
              selectedColor: AppColors.primaryYellow.withOpacity(0.2),
              checkmarkColor: AppColors.primaryYellow,
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildPurposeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Purpose'),
        const SizedBox(height: 16),
        Obx(() => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: PropertyPurpose.values.map((purpose) {
            final isSelected = controller.filters.purpose == purpose;
            return FilterChip(
              label: Text(FiltersController.purposeDisplayNames[purpose] ?? purpose.name),
              selected: isSelected,
              onSelected: (selected) => controller.updatePurpose(selected ? purpose : null),
              selectedColor: AppColors.primaryYellow.withOpacity(0.2),
              checkmarkColor: AppColors.primaryYellow,
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Price Range'),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min Price',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  controller.updatePriceRange(min: price);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max Price',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  controller.updatePriceRange(max: price);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bedrooms'),
        const SizedBox(height: 16),
        
        Obx(() => Wrap(
          spacing: 8,
          children: List.generate(6, (index) {
            final bedrooms = index == 0 ? null : index;
            final isSelected = controller.filters.bedroomsMin == bedrooms;
            
            return FilterChip(
              label: Text(index == 0 ? 'Any' : '$index+'),
              selected: isSelected,
              onSelected: (selected) => controller.updateBedroomRange(
                min: selected ? bedrooms : null,
              ),
              selectedColor: AppColors.primaryYellow.withOpacity(0.2),
              checkmarkColor: AppColors.primaryYellow,
            );
          }),
        )),
        
        const SizedBox(height: 16),
        _buildSectionTitle('Bathrooms'),
        const SizedBox(height: 16),
        
        Obx(() => Wrap(
          spacing: 8,
          children: List.generate(4, (index) {
            final bathrooms = index == 0 ? null : index;
            final isSelected = controller.filters.bathroomsMin == bathrooms;
            
            return FilterChip(
              label: Text(index == 0 ? 'Any' : '$index+'),
              selected: isSelected,
              onSelected: (selected) => controller.updateBathroomRange(
                min: selected ? bathrooms : null,
              ),
              selectedColor: AppColors.primaryYellow.withOpacity(0.2),
              checkmarkColor: AppColors.primaryYellow,
            );
          }),
        )),
      ],
    );
  }

  Widget _buildAreaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Area (sq ft)'),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min Area',
                  suffixText: 'sq ft',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final area = double.tryParse(value);
                  controller.updateAreaRange(min: area);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max Area',
                  suffixText: 'sq ft',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final area = double.tryParse(value);
                  controller.updateAreaRange(max: area);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Amenities'),
        const SizedBox(height: 16),
        Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: FiltersController.availableAmenities.map((amenity) {
            final isSelected = controller.filters.amenities?.contains(amenity) ?? false;
            return FilterChip(
              label: Text(amenity.split('_').map((word) => 
                word[0].toUpperCase() + word.substring(1)).join(' ')),
              selected: isSelected,
              onSelected: (selected) => controller.toggleAmenity(amenity),
              selectedColor: AppColors.primaryYellow.withOpacity(0.2),
              checkmarkColor: AppColors.primaryYellow,
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildAdditionalFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Additional Filters'),
        const SizedBox(height: 16),
        
        // Parking
        ListTile(
          leading: Icon(Icons.local_parking, color: AppColors.iconColor),
          title: Text('Minimum Parking Spaces'),
          trailing: DropdownButton<int?>(
            value: controller.filters.parkingSpacesMin,
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              ...List.generate(5, (index) => DropdownMenuItem(
                value: index + 1,
                child: Text('${index + 1}+'),
              )),
            ],
            onChanged: controller.updateParkingSpaces,
          ),
        ),
        
        // Property age
        ListTile(
          leading: Icon(Icons.schedule, color: AppColors.iconColor),
          title: Text('Maximum Property Age'),
          trailing: DropdownButton<int?>(
            value: controller.filters.ageMax,
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              const DropdownMenuItem(value: 1, child: Text('New (0-1 years)')),
              const DropdownMenuItem(value: 5, child: Text('Recent (0-5 years)')),
              const DropdownMenuItem(value: 10, child: Text('Modern (0-10 years)')),
              const DropdownMenuItem(value: 20, child: Text('Established (0-20 years)')),
            ],
            onChanged: controller.updateMaxAge,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      height: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              controller.applyFilters();
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Obx(() => Text(
              controller.activeFilterCount > 0 
                  ? 'Apply ${controller.activeFilterCount} Filters' 
                  : 'Show All Properties',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )),
          ),
        ),
      ),
    );
  }
}