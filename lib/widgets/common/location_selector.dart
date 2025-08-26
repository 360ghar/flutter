import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/app_colors.dart';
import '../../core/controllers/location_controller.dart';
import '../../core/controllers/page_state_service.dart';
import '../../core/data/models/page_state_model.dart';

class LocationSelector extends GetView<LocationController> {
  final PageType pageType;

  const LocationSelector({
    super.key,
    required this.pageType,
  });

  @override
  Widget build(BuildContext context) {
    final pageStateService = Get.find<PageStateService>();

    return Obx(() {
      final currentPageState = _getPageState(pageStateService);
      final locationText = currentPageState.locationDisplayText;
      
      return GestureDetector(
        onTap: () => _showLocationPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: AppColors.primaryYellow,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  locationText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      );
    });
  }

  PageStateModel _getPageState(PageStateService pageStateService) {
    switch (pageType) {
      case PageType.explore:
        return pageStateService.exploreState.value;
      case PageType.discover:
        return pageStateService.discoverState.value;
      case PageType.likes:
        return pageStateService.likesState.value;
    }
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerModal(pageType: pageType),
    );
  }
}

class LocationPickerModal extends StatefulWidget {
  final PageType pageType;

  const LocationPickerModal({
    super.key,
    required this.pageType,
  });

  @override
  State<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends State<LocationPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  final LocationController locationController = Get.find<LocationController>();
  final PageStateService pageStateService = Get.find<PageStateService>();

  @override
  void initState() {
    super.initState();
    // Clear previous suggestions
    locationController.clearPlaceSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryYellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Select Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppColors.textPrimary),
              onChanged: (query) {
                if (query.isNotEmpty) {
                  locationController.getPlaceSuggestions(query);
                } else {
                  locationController.clearPlaceSuggestions();
                }
              },
              decoration: InputDecoration(
                hintText: 'Search for a location',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.iconColor),
                suffixIcon: Obx(() {
                  if (locationController.isSearchingPlaces.value) {
                    return Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                        ),
                      );
                  } else if (_searchController.text.isNotEmpty) {
                    return IconButton(
                            icon: Icon(Icons.clear, color: AppColors.iconColor),
                            onPressed: () {
                              _searchController.clear();
                              locationController.clearPlaceSuggestions();
                            },
                          );
                  }
                  return const SizedBox.shrink();
                }),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildQuickActionTile(
                  icon: Icons.my_location,
                  title: 'Use Current Location',
                  subtitle: 'Get location from GPS',
                  iconColor: AppColors.primaryYellow,
                  onTap: () => _useCurrentLocation(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Search results
          Expanded(
            child: Obx(() {
              final suggestions = locationController.placeSuggestions;
              
              if (suggestions.isEmpty && _searchController.text.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No locations found',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return _buildLocationTile(
                    title: suggestion.mainText,
                    subtitle: suggestion.secondaryText,
                    onTap: () => _selectPlaceSuggestion(suggestion),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppColors.surface,
      ),
    );
  }

  Widget _buildLocationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.location_on, color: AppColors.accentBlue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  void _useCurrentLocation() async {
    try {
      Navigator.of(context).pop();
      await pageStateService.useCurrentLocationForPage(widget.pageType);
      
      Get.snackbar(
        'Location Updated',
        'Using your current location',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to get current location',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
    }
  }

  void _selectPlaceSuggestion(PlaceSuggestion suggestion) async {
    try {
      Navigator.of(context).pop();
      
      // Get place details with preferred name from autocomplete selection
      final locationData = await locationController.getPlaceDetails(
        suggestion.placeId,
        preferredName: suggestion.mainText,
      );
      if (locationData != null) {
        pageStateService.updateLocationForPage(widget.pageType, locationData, source: 'manual');
        
        Get.snackbar(
          'Location Selected',
          suggestion.mainText,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to select location',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
    }
  }
}
