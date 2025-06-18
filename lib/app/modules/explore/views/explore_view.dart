import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../controllers/explore_controller.dart';
import '../../../controllers/theme_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../utils/app_colors.dart';
import '../../../../widgets/navigation/bottom_nav_bar.dart';
import '../../../../widgets/common/property_filter_widget.dart';


class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Scaffold(
      body: Stack(
        children: [
          // OpenStreetMap with Flutter Map
          Obx(() => FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: controller.currentLocation.value,
              initialZoom: controller.currentZoom.value,
              onMapReady: controller.onMapReady,
              onPositionChanged: controller.onPositionChanged,
              onMapEvent: controller.onMapEvent,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate: Get.isDarkMode 
                    ? 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ghar360',
                maxZoom: 19,
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Get.isDarkMode 
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      BlendMode.color,
                    ),
                    child: tileWidget,
                  );
                },
              ),
              
              // Radius circle
              CircleLayer(
                circles: [controller.radiusCircle],
              ),
              
              // Property markers
              MarkerLayer(
                markers: controller.markers,
              ),
              
              // Current location marker
              if (controller.hasLocationPermission.value)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 20.0,
                      height: 20.0,
                      point: controller.currentLocation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          )),
          
          // Top Search Bar and Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.getCardShadow(),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.searchController,
                          style: TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'search_hint'.tr,
                            hintStyle: TextStyle(color: AppColors.searchHint),
                            prefixIcon: Icon(Icons.search, color: AppColors.iconColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: controller.searchLocation,
                        ),
                      ),
                      Obx(() => controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.iconColor),
                              onPressed: controller.clearSearch,
                            )
                          : const SizedBox.shrink()),
                      Obx(() => controller.isSearching.value
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.loadingIndicator),
                                ),
                              ),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Control Buttons Row
                Row(
                  children: [
                    // Filters Button
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.buttonBackground,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.getCardShadow(),
                      ),
                      child: PropertyFilterWidget(
                        pageType: 'explore',
                        onFiltersApplied: () {
                          // Refresh the map markers and property list
                          controller.refreshFilteredProperties();
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Current Location Button
                    _buildControlButton(
                      icon: Icons.my_location,
                      label: 'my_location'.tr,
                      onTap: controller.goToCurrentLocation,
                      backgroundColor: AppColors.surface,
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Theme Toggle Button
                    Obx(() => _buildControlButton(
                      icon: themeController.isDarkMode.value 
                          ? Icons.light_mode 
                          : Icons.dark_mode,
                      label: themeController.isDarkMode.value 
                          ? 'light'.tr 
                          : 'dark'.tr,
                      onTap: themeController.toggleTheme,
                      backgroundColor: AppColors.surface,
                    )),
                    
                    const Spacer(),
                    
                    // Property Count and Radius Info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.getCardShadow(),
                      ),
                      child: Obx(() => Text(
                        '${controller.visiblePropertyCount} • ${controller.radiusText}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Loading Indicator
          Obx(() => controller.isLoadingLocation.value
              ? Container(
                  color: AppColors.shadowColor.withValues(alpha: 0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.loadingIndicator),
                    ),
                  ),
                )
              : const SizedBox.shrink()),
          
          // Bottom Property List
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() => controller.showPropertyList.value
                ? _buildPropertyList()
                : const SizedBox.shrink()),
          ),
          
          // Toggle Property List Button
          Positioned(
            bottom: 100,
            right: 16,
            child: Obx(() => FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.buttonBackground,
              onPressed: controller.togglePropertyList,
              child: Icon(
                controller.showPropertyList.value 
                    ? Icons.keyboard_arrow_down 
                    : Icons.keyboard_arrow_up,
                color: AppColors.buttonText,
              ),
            )),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.getCardShadow(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: backgroundColor == AppColors.buttonBackground 
                  ? AppColors.buttonText 
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: backgroundColor == AppColors.buttonBackground 
                    ? AppColors.buttonText 
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyList() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: AppColors.getCardShadow(),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Obx(() => Text(
                  '${controller.visiblePropertyCount} Properties Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                )),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.iconColor),
                  onPressed: controller.togglePropertyList,
                ),
              ],
            ),
          ),
          
          // Property List
          Expanded(
            child: Obx(() => controller.visibleProperties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined, size: 48, color: AppColors.iconColor),
                        const SizedBox(height: 8),
                        Text(
                          'No properties found in this area',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.visibleProperties.length,
                    itemBuilder: (context, index) {
                      final property = controller.visibleProperties[index];
                      return _buildPropertyCard(property);
                    },
                  )),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(PropertyModel property) {
    return Obx(() => GestureDetector(
      onTap: () => controller.viewPropertyDetails(property),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: controller.selectedPropertyId.value == property.id
              ? AppColors.primaryYellow.withValues(alpha: 0.1)
              : AppColors.propertyCardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.selectedPropertyId.value == property.id
                ? AppColors.primaryYellow
                : AppColors.border,
            width: controller.selectedPropertyId.value == property.id ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Property Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  property.images.isNotEmpty ? property.images.first : '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppColors.inputBackground,
                    child: Icon(Icons.home, color: AppColors.iconColor),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Property Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.propertyCardText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      '${property.address}, ${property.city}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.propertyCardSubtext,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        _buildPropertySpec(Icons.bed, '${property.bedrooms}'),
                        const SizedBox(width: 12),
                        _buildPropertySpec(Icons.bathtub, '${property.bathrooms}'),
                        const SizedBox(width: 12),
                        _buildPropertySpec(Icons.square_foot, '${property.area.toInt()}'),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    property.formattedPrice,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.propertyCardPrice,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.propertyType,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.propertyCardSubtext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildPropertySpec(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.propertyFeatureIcon),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.propertyFeatureText,
          ),
        ),
      ],
    );
  }
} 