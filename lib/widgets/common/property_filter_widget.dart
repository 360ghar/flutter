import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/app_colors.dart';
import '../../app/controllers/property_controller.dart';
import '../../app/utils/controller_helper.dart';

class PropertyFilterWidget extends StatelessWidget {
  final String pageType; // 'home', 'explore', 'favourites'
  final VoidCallback? onFiltersApplied;

  const PropertyFilterWidget({
    Key? key,
    required this.pageType,
    this.onFiltersApplied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.tune, color: AppColors.iconColor),
      onPressed: () => _showFilterBottomSheet(context),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        pageType: pageType,
        onFiltersApplied: onFiltersApplied,
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String pageType;
  final VoidCallback? onFiltersApplied;

  const _FilterBottomSheet({
    Key? key,
    required this.pageType,
    this.onFiltersApplied,
  }) : super(key: key);

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late final PropertyController propertyController;
  
  late String _selectedPurpose;
  late double _minPrice;
  late double _maxPrice;
  late int _minBedrooms;
  late int _maxBedrooms;
  late String _propertyType;
  late List<String> _selectedAmenities;

  final List<String> purposes = ['Buy', 'Rent', 'Stay'];
  
  final List<String> propertyTypes = [
    'All',
    'Apartment',
    'House',
    'Condo',
    'Penthouse',
    'Villa',
    'Studio',
    'Loft',
  ];

  final List<String> stayPropertyTypes = [
    'All',
    'Hotel',
    'Resort',
    'Apartment',
    'Villa',
    'Cottage',
    'Studio',
  ];

  final List<String> amenitiesList = [
    'Gym',
    'Pool',
    'Parking',
    'Balcony',
    'Garden',
    'Security',
    'Elevator',
    'Terrace',
    'Club House',
    'Kids Play Area',
    'Power Backup',
    'Water Supply',
  ];

  @override
  void initState() {
    super.initState();
    // Ensure PropertyController is available
    ControllerHelper.ensurePropertyController();
    propertyController = Get.find<PropertyController>();
    _initializeFilters();
  }

  void _initializeFilters() {
    _selectedPurpose = propertyController.selectedPurpose;
    // Clamp values to ensure they're within the slider range
    final maxRange = propertyController.getPriceMax();
    _minPrice = propertyController.minPrice.clamp(0.0, maxRange);
    _maxPrice = propertyController.maxPrice.clamp(0.0, maxRange);
    _minBedrooms = propertyController.minBedrooms.clamp(0, 10);
    _maxBedrooms = propertyController.maxBedrooms.clamp(0, 10);
    _propertyType = propertyController.propertyType;
    _selectedAmenities = List<String>.from(propertyController.selectedAmenities);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPurposeFilter(),
                  const SizedBox(height: 30),
                  _buildPriceFilter(),
                  const SizedBox(height: 30),
                  if (_selectedPurpose != 'Stay') ...[
                    _buildBedroomsFilter(),
                    const SizedBox(height: 30),
                  ],
                  _buildPropertyTypeFilter(),
                  const SizedBox(height: 30),
                  _buildAmenitiesFilter(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Filter Properties',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purpose',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: purposes.map((purpose) {
            final isSelected = _selectedPurpose == purpose;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPurpose = purpose;
                  // Update controller purpose first
                  propertyController.updateFilters(selectedPurposeValue: purpose);
                  // Then get the updated price range
                  _minPrice = propertyController.minPrice;
                  _maxPrice = propertyController.maxPrice;
                  // Reset property type
                  _propertyType = 'All';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryYellow : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryYellow : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Text(
                  purpose,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? AppColors.surface : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    final priceLabel = _selectedPurpose == 'Stay' 
        ? 'Price per night' 
        : _selectedPurpose == 'Rent' 
            ? 'Price per month' 
            : 'Property price';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          priceLabel,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        RangeSlider(
          values: RangeValues(
            _minPrice.clamp(
              _selectedPurpose == 'Stay' ? 500.0 
                  : _selectedPurpose == 'Rent' ? 5000.0 
                  : 500000.0,
              _selectedPurpose == 'Stay' ? 50000.0 
                  : _selectedPurpose == 'Rent' ? 5000000.0 
                  : 150000000.0,
            ),
            _maxPrice.clamp(
              _selectedPurpose == 'Stay' ? 500.0 
                  : _selectedPurpose == 'Rent' ? 5000.0 
                  : 500000.0,
              _selectedPurpose == 'Stay' ? 50000.0 
                  : _selectedPurpose == 'Rent' ? 5000000.0 
                  : 150000000.0,
            ),
          ),
          min: _selectedPurpose == 'Stay' ? 500.0 
              : _selectedPurpose == 'Rent' ? 5000.0 
              : 500000.0,
          max: _selectedPurpose == 'Stay' ? 50000.0 
              : _selectedPurpose == 'Rent' ? 5000000.0 
              : 150000000.0,
          divisions: 100,
          activeColor: AppColors.primaryYellow,
          inactiveColor: AppColors.primaryYellow.withOpacity(0.2),
          labels: RangeLabels(
            '₹${_formatPrice(_minPrice)}',
            '₹${_formatPrice(_maxPrice)}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _minPrice = values.start;
              _maxPrice = values.end;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${_formatPrice(_minPrice)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '₹${_formatPrice(_maxPrice)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBedroomsFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bedrooms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Min Bedrooms',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _minBedrooms,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(6, (index) => index)
                        .map((bedroom) => DropdownMenuItem(
                              value: bedroom,
                              child: Text(bedroom == 0 ? 'Any' : '$bedroom+'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _minBedrooms = value!;
                        if (_maxBedrooms < _minBedrooms) {
                          _maxBedrooms = _minBedrooms;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Max Bedrooms',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _maxBedrooms,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: List.generate(11, (index) => index)
                        .where((bedroom) => bedroom >= _minBedrooms)
                        .map((bedroom) => DropdownMenuItem(
                              value: bedroom,
                              child: Text(bedroom == 10 ? '10+' : '$bedroom'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _maxBedrooms = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyTypeFilter() {
    // Use different property types for Stay mode
    final typesToShow = _selectedPurpose == 'Stay' ? stayPropertyTypes : propertyTypes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: typesToShow.map((type) {
            final isSelected = _propertyType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _propertyType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryYellow : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryYellow : AppColors.border,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? AppColors.surface : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: amenitiesList.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedAmenities.remove(amenity);
                  } else {
                    _selectedAmenities.add(amenity);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryYellow.withOpacity(0.1) : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryYellow : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppColors.primaryYellow,
                      ),
                    if (isSelected) const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppColors.primaryYellow : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearFilters,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primaryYellow),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primaryYellow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedPurpose = 'Buy';
      _minPrice = 500000.0;
      _maxPrice = 150000000.0;
      _minBedrooms = 0;
      _maxBedrooms = 10;
      _propertyType = 'All';
      _selectedAmenities.clear();
    });
  }

  void _applyFilters() {
    propertyController.updateFilters(
      selectedPurposeValue: _selectedPurpose,
      minPriceValue: _minPrice,
      maxPriceValue: _maxPrice,
      minBedroomsValue: _minBedrooms,
      maxBedroomsValue: _maxBedrooms,
      propertyTypeValue: _propertyType,
      selectedAmenitiesValue: _selectedAmenities,
    );

    Navigator.pop(context);
    
    if (widget.onFiltersApplied != null) {
      widget.onFiltersApplied!();
    }

    // Show confirmation
    Get.snackbar(
      'Filters Applied',
      'Properties filtered based on your preferences',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.primaryYellow,
      colorText: AppColors.surface,
      duration: const Duration(seconds: 2),
    );
  }

  String _formatPrice(double price) {
    if (price >= 10000000) {
      return '${(price / 10000000).toStringAsFixed(1)}Cr';
    } else if (price >= 100000) {
      return '${(price / 100000).toStringAsFixed(1)}L';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }
} 