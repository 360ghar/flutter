import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/utils/app_colors.dart';

class FiltersView extends GetView<FilterService> {
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
            onPressed: controller.activeFiltersCount > 0 ? controller.resetFilters : null,
            child: Text(
              'Reset',
              style: TextStyle(
                color: controller.activeFiltersCount > 0 
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
                  '${controller.activeFiltersCount} filters active',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (controller.activeFiltersCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${controller.activeFiltersCount}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.w600,
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
                  // Purpose selection
                  _buildSectionTitle('Purpose'),
                  const SizedBox(height: 12),
                  _buildPurposeSelector(),
                  
                  const SizedBox(height: 24),
                  
                  // Price range
                  _buildSectionTitle('Price Range'),
                  const SizedBox(height: 12),
                  _buildPriceRangeSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Bedrooms
                  _buildSectionTitle('Bedrooms'),
                  const SizedBox(height: 12),
                  _buildBedroomSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Property Types
                  _buildSectionTitle('Property Type'),
                  const SizedBox(height: 12),
                  _buildPropertyTypeSection(),
                  
                  const SizedBox(height: 100), // Bottom padding for apply button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildApplyButton(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildPurposeSelector() {
    return Obx(() => Row(
      children: [
        _buildPurposeChip('Buy', 'buy'),
        const SizedBox(width: 12),
        _buildPurposeChip('Rent', 'rent'),
        const SizedBox(width: 12),
        _buildPurposeChip('Short Stay', 'short_stay'),
      ],
    ));
  }

  Widget _buildPurposeChip(String label, String value) {
    final isSelected = controller.currentFilter.value.purpose == value;
    
    return GestureDetector(
      onTap: () => controller.updatePurpose(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryYellow : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Obx(() {
      final filter = controller.currentFilter.value;
      final minPrice = filter.priceMin ?? controller.getPriceMin();
      final maxPrice = filter.priceMax ?? controller.getPriceMax();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Min: ₹${_formatPrice(minPrice)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Max: ₹${_formatPrice(maxPrice)}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(Get.context!).copyWith(
              activeTrackColor: AppColors.primaryYellow,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primaryYellow,
              overlayColor: AppColors.primaryYellow.withValues(alpha: 0.2),
            ),
            child: RangeSlider(
              values: RangeValues(minPrice, maxPrice),
              min: controller.getPriceMin(),
              max: controller.getPriceMax(),
              divisions: 20,
              onChanged: (values) {
                controller.updatePriceRange(values.start, values.end);
              },
            ),
          ),
          Text(
            controller.getPriceLabel(),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildBedroomSection() {
    return Obx(() {
      final filter = controller.currentFilter.value;
      final min = filter.bedroomsMin ?? 1;
      final max = filter.bedroomsMax ?? 5;
      
      return Row(
        children: [
          Text('Min: $min', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(Get.context!).copyWith(
                activeTrackColor: AppColors.primaryYellow,
                thumbColor: AppColors.primaryYellow,
                overlayColor: AppColors.primaryYellow.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: min.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  controller.updateBedrooms(value.toInt(), max);
                },
              ),
            ),
          ),
          Text('Max: $max', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(Get.context!).copyWith(
                activeTrackColor: AppColors.primaryYellow,
                thumbColor: AppColors.primaryYellow,
                overlayColor: AppColors.primaryYellow.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: max.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  controller.updateBedrooms(min, value.toInt());
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPropertyTypeSection() {
    final propertyTypes = ['House', 'Apartment', 'Builder Floor', 'Room'];
    
    return Obx(() {
      final selectedTypes = controller.currentFilter.value.propertyType ?? [];
      
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: propertyTypes.map((type) {
          final isSelected = selectedTypes.contains(type.toLowerCase());
          
          return GestureDetector(
            onTap: () {
              if (isSelected) {
                controller.removePropertyType(type.toLowerCase());
              } else {
                controller.addPropertyType(type.toLowerCase());
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryYellow : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primaryYellow : AppColors.border,
                ),
              ),
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildApplyButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() => SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: controller.activeFiltersCount > 0 ? _applyFilters : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.activeFiltersCount > 0 
                  ? AppColors.primaryYellow 
                  : AppColors.border,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Apply Filters (${controller.activeFiltersCount})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: controller.activeFiltersCount > 0 
                    ? Colors.white 
                    : AppColors.textSecondary,
              ),
            ),
          ),
        )),
      ),
    );
  }

  void _applyFilters() {
    controller.applyFilters();
    Get.back();
    Get.snackbar(
      'Filters Applied',
      '${controller.activeFiltersCount} filters are now active',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryYellow,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  String _formatPrice(double price) {
    if (price >= 10000000) {
      return '${(price / 10000000).toStringAsFixed(1)}Cr';
    } else if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(1)}L';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }
}