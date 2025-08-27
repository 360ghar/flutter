import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/filter_service.dart';
import '../../controllers/location_controller.dart';
import '../../routes/app_routes.dart';

/// Unified AppBar component for Explore, Discover, and Likes pages
/// 
/// Features:
/// - Consistent white background with flat design
/// - Location selector with amber pin icon
/// - Three action icons: search, refresh, filter
/// - Responsive design for all screen sizes
/// - Clean architecture with proper separation of concerns
class UnifiedAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Callback for search action
  final VoidCallback? onSearchTap;
  
  /// Callback for refresh action
  final VoidCallback? onRefreshTap;
  
  /// Callback for filter action (defaults to navigation to filters page)
  final VoidCallback? onFilterTap;
  
  /// Callback for location selector tap (defaults to navigation to location search)
  final VoidCallback? onLocationTap;
  
  /// Custom location text override (if null, uses current location from LocationController)
  final String? locationText;

  const UnifiedAppBar({
    super.key,
    this.onSearchTap,
    this.onRefreshTap,
    this.onFilterTap,
    this.onLocationTap,
    this.locationText,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Background and styling
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 16.0,
      
      // Title section - Location Selector (positioned on left)
      title: _LocationSelector(
        onTap: onLocationTap ?? _defaultLocationTap,
        locationText: locationText,
      ),
      
      // Action icons
      actions: [
        _ActionIcon(
          icon: Icons.search,
          color: Colors.black87,
          onTap: onSearchTap ?? _defaultSearchTap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        _ActionIcon(
          icon: Icons.cached,
          color: const Color(0xFFFFC107), // Amber
          onTap: onRefreshTap ?? _defaultRefreshTap,
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        _ActionIcon(
          icon: Icons.tune,
          color: Colors.black87,
          onTap: onFilterTap ?? _defaultFilterTap,
          padding: const EdgeInsets.only(left: 6, right: 12),
        ),
      ],
      
      // Bottom border
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1.0),
        child: Divider(
          height: 1.0,
          thickness: 1.0,
          color: Color(0xFFE0E0E0), // Colors.grey.shade300
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1); // +1 for divider

  // Default action callbacks
  void _defaultLocationTap() {
    Get.toNamed(AppRoutes.locationSearch);
  }

  void _defaultSearchTap() {
    _showSearchDialog();
  }

  void _defaultRefreshTap() {
    // Default refresh behavior - can be overridden by pages
    Get.snackbar(
      'Refresh',
      'Refreshing data...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
    );
  }

  void _defaultFilterTap() {
    Get.toNamed(AppRoutes.filters);
  }

  void _showSearchDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Search Properties',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search by location, property type...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    // Handle search submission
                    Get.back();
                    Get.snackbar(
                      'Search',
                      'Searching for: $value',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Location Selector Widget
class _LocationSelector extends StatelessWidget {
  final VoidCallback onTap;
  final String? locationText;

  const _LocationSelector({
    required this.onTap,
    this.locationText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: Colors.black,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Location pin icon
            const Icon(
              Icons.location_on_outlined,
              color: Color(0xFFFFC107), // Amber
              size: 20,
            ),
            
            const SizedBox(width: 8),
            
            // Location text
            Flexible(
              child: _LocationText(customText: locationText),
            ),
            
            const SizedBox(width: 4),
            
            // Dropdown arrow
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.black54,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

/// Location Text Widget with reactive updates
class _LocationText extends StatelessWidget {
  final String? customText;

  const _LocationText({this.customText});

  @override
  Widget build(BuildContext context) {
    // If custom text is provided, use it
    if (customText != null) {
      return Text(
        customText!,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Otherwise, use reactive location from controllers
    return GetBuilder<LocationController>(
      builder: (locationController) {
        return GetBuilder<FilterService>(
          builder: (filterService) {
            String displayText = 'Select Location';
            
            // Priority: 1. Filter location, 2. Current city, 3. Default
            if (filterService.selectedLocation.value != null) {
              displayText = filterService.selectedLocation.value!.name;
            } else if (locationController.currentCity.value.isNotEmpty) {
              displayText = locationController.currentCity.value;
            }
            
            return Text(
              displayText,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        );
      },
    );
  }
}

/// Action Icon Widget
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final EdgeInsets padding;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: IconButton(
        icon: Icon(
          icon,
          color: color,
          size: 22,
        ),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        splashRadius: 20,
      ),
    );
  }
}