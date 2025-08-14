import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/filters/controllers/filter_controller.dart';
import '../../controllers/location_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/theme.dart';

class SharedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  
  const SharedAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final propertyFilterController = Get.find<PropertyFilterController>();
    final locationController = Get.find<LocationController>();
    
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton 
        ? IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
            onPressed: () => Get.back(),
          )
        : null,
      title: title != null 
        ? Text(
            title!,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          )
        : _buildLocationSelector(context, propertyFilterController, locationController),
      centerTitle: false,
      actions: [
        _buildFilterButton(context, propertyFilterController),
      ],
    );
  }

  Widget _buildLocationSelector(
    BuildContext context,
    PropertyFilterController filterController,
    LocationController locationController,
  ) {
    return Obx(() {
      final selectedLocation = filterController.selectedLocation.value;
      String locationText = 'Select Location';
      IconData locationIcon = Icons.location_on_outlined;
      
      if (selectedLocation != null) {
        locationText = selectedLocation.name;
        locationIcon = Icons.location_on;
      } else if (locationController.currentCity.value.isNotEmpty) {
        locationText = locationController.currentCity.value;
        locationIcon = Icons.my_location;
      }
      
      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.locationSearch),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                locationIcon,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  locationText,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilterButton(
    BuildContext context,
    PropertyFilterController filterController,
  ) {
    return Obx(() {
      final activeFilters = filterController.activeFiltersCount;
      
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.tune,
                color: activeFilters > 0 
                  ? AppTheme.primaryColor 
                  : Theme.of(context).textTheme.bodyLarge?.color,
              ),
              onPressed: () => Get.toNamed(AppRoutes.filters),
            ),
            if (activeFilters > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    activeFilters.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}