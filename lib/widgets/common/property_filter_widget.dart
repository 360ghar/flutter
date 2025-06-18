import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/utils/theme.dart';
import '../../app/controllers/property_controller.dart';

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
      icon: const Icon(Icons.tune, color: Colors.black),
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
  final PropertyController propertyController = Get.find<PropertyController>();
  
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
    _initializeFilters();
  }

  void _initializeFilters() {
    _selectedPurpose = propertyController.selectedPurpose.value;
    // Clamp values to ensure they're within the slider range
    final maxRange = propertyController.getPriceMax();
    _minPrice = propertyController.minPrice.value.clamp(0.0, maxRange);
    _maxPrice = propertyController.maxPrice.value.clamp(0.0, maxRange);
    _minBedrooms = propertyController.minBedrooms.value.clamp(0, 10);
    _maxBedrooms = propertyController.maxBedrooms.value.clamp(0, 10);
    _propertyType = propertyController.propertyType.value;
    _selectedAmenities = List<String>.from(propertyController.selectedAmenities);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filter Properties',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
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
        const Text(
          'Purpose',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
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
                  _minPrice = propertyController.minPrice.value;
                  _maxPrice = propertyController.maxPrice.value;
                  // Reset property type
                  _propertyType = 'All';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryYellow : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryYellow : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Text(
                  purpose,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? Colors.white : AppTheme.textDark,
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
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
          activeColor: AppTheme.primaryYellow,
          inactiveColor: AppTheme.primaryYellow.withOpacity(0.2),
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              '₹${_formatPrice(_maxPrice)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
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
        const Text(
          'Bedrooms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Min Bedrooms',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _minBedrooms,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
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
                  const Text(
                    'Max Bedrooms',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _maxBedrooms,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
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
        const Text(
          'Property Type',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
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
                  color: isSelected ? AppTheme.primaryYellow : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryYellow : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : AppTheme.textDark,
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
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
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
                  color: isSelected ? AppTheme.primaryYellow.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryYellow : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: AppTheme.primaryYellow,
                      ),
                    if (isSelected) const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppTheme.primaryYellow : AppTheme.textDark,
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
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearFilters,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryYellow),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryYellow,
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
                backgroundColor: AppTheme.primaryYellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
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
      backgroundColor: AppTheme.primaryYellow,
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
      return '${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return price.toStringAsFixed(0);
    }
  }
} 