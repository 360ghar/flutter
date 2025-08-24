import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/data/models/unified_filter_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/debug_logger.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late final FilterService _filterService;
  late UnifiedFilterModel _filters;

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filterService = Get.find<FilterService>();
    _filters = _filterService.currentFilter.value;

    // Initialize controllers with current values
    _locationController.text = _filterService.locationDisplayText;
    _minPriceController.text = _filters.priceMin?.toString() ?? '';
    _maxPriceController.text = _filters.priceMax?.toString() ?? '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Purpose
                    _buildSectionTitle('Property Type'),
                    _buildPurposeChips(),

                    const SizedBox(height: 24),

                    // Property Types
                    _buildSectionTitle('Property Category'),
                    _buildPropertyTypeChips(),

                    const SizedBox(height: 24),

                    // Price Range
                    _buildSectionTitle('Price Range'),
                    _buildPriceRangeInputs(),

                    const SizedBox(height: 24),

                    // Bedrooms
                    _buildSectionTitle('Bedrooms'),
                    _buildBedroomChips(),

                    const SizedBox(height: 24),

                    // Location
                    _buildSectionTitle('Location'),
                    _buildLocationInput(),

                    const SizedBox(height: 24),

                    // Radius
                    _buildSectionTitle('Search Radius'),
                    _buildRadiusSlider(),
                  ],
                ),
              ),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryYellow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.tune,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildPurposeChips() {
    final purposes = ['buy', 'rent', 'short_stay'];
    final purposeLabels = {'buy': 'Buy', 'rent': 'Rent', 'short_stay': 'Short Stay'};

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: purposes.map((purpose) {
        final isSelected = _filters.purpose == purpose;
        return FilterChip(
          label: Text(purposeLabels[purpose]!),
          selected: isSelected,
          onSelected: (selected) => _togglePurpose(purpose, selected),
          selectedColor: AppColors.primaryYellow.withOpacity(0.2),
          checkmarkColor: AppColors.primaryYellow,
        );
      }).toList(),
    );
  }

  Widget _buildPropertyTypeChips() {
    final types = ['house', 'apartment', 'builder_floor', 'room'];
    final typeLabels = {
      'house': 'House',
      'apartment': 'Apartment',
      'builder_floor': 'Builder Floor',
      'room': 'Room'
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = _filters.propertyType?.contains(type) == true;
        return FilterChip(
          label: Text(typeLabels[type]!),
          selected: isSelected,
          onSelected: (selected) => _togglePropertyType(type, selected),
          selectedColor: AppColors.primaryYellow.withOpacity(0.2),
          checkmarkColor: AppColors.primaryYellow,
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeInputs() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minPriceController,
            decoration: const InputDecoration(
              labelText: 'Min Price',
              prefixText: '₹',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final minPrice = double.tryParse(value);
              setState(() {
                _filters = _filters.copyWith(priceMin: minPrice);
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _maxPriceController,
            decoration: const InputDecoration(
              labelText: 'Max Price',
              prefixText: '₹',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final maxPrice = double.tryParse(value);
              setState(() {
                _filters = _filters.copyWith(priceMax: maxPrice);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBedroomChips() {
    final bedroomOptions = [1, 2, 3, 4, '4+'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bedroomOptions.map((option) {
        final isSelected = _filters.bedroomsMin == option ||
                          (_filters.bedroomsMin == 4 && option == '4+');
        return FilterChip(
          label: Text(option.toString()),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _filters = _filters.copyWith(
                  bedroomsMin: option == '4+' ? 4 : option as int,
                );
              });
            } else {
              setState(() {
                _filters = _filters.copyWith(bedroomsMin: null);
              });
            }
          },
          selectedColor: AppColors.primaryYellow.withOpacity(0.2),
          checkmarkColor: AppColors.primaryYellow,
        );
      }).toList(),
    );
  }

  Widget _buildLocationInput() {
    return TextField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: 'Location',
        hintText: 'Enter city or area',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.my_location),
          onPressed: () => _useCurrentLocation(),
        ),
      ),
      onChanged: (value) {
        // Location will be handled by the location search widget
        setState(() {
          _filters = _filters.copyWith(city: value);
        });
      },
    );
  }

  Widget _buildRadiusSlider() {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '${_filters.radiusKm?.toStringAsFixed(1) ?? '5.0'} km',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              (_filters.radiusKm ?? 5.0) < 1
                  ? '${((_filters.radiusKm ?? 5.0) * 1000).round()}m'
                  : '${(_filters.radiusKm ?? 5.0).toStringAsFixed(1)}km',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Slider(
          value: _filters.radiusKm ?? 5.0,
          min: 1.0,
          max: 50.0,
          divisions: 49,
          label: '${_filters.radiusKm?.toStringAsFixed(1) ?? '5.0'} km',
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(radiusKm: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _clearFilters(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.grey[400]!),
              ),
              child: const Text('Clear All'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _applyFilters(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  void _togglePurpose(String purpose, bool selected) {
    setState(() {
      _filters = _filters.copyWith(purpose: selected ? purpose : null);
    });
  }

  void _togglePropertyType(String type, bool selected) {
    setState(() {
      final currentTypes = List<String>.from(_filters.propertyType ?? []);
      if (selected) {
        currentTypes.add(type);
      } else {
        currentTypes.remove(type);
      }
      _filters = _filters.copyWith(propertyType: currentTypes);
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      // This would integrate with the location service
      Get.snackbar(
        'Current Location',
        'Using your current location for search',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      DebugLogger.error('Error getting current location: $e');
    }
  }

  void _clearFilters() {
    setState(() {
      _filters = UnifiedFilterModel.initial();
      _locationController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _applyFilters() {
    DebugLogger.api('Applying filters: ${_filters.toJson()}');

    // Update the filter service
    _filterService.currentFilter.value = _filters;

    // Save preferences
    _savePreferences();

    // Close dialog
    Get.back();

    // Show confirmation
    Get.snackbar(
      'Filters Applied',
      'Your search filters have been updated',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryYellow,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _savePreferences() async {
    try {
      // This would save user preferences to backend
      DebugLogger.info('Saving user filter preferences');
    } catch (e) {
      DebugLogger.error('Error saving preferences: $e');
    }
  }
}
