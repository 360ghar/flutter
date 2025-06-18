import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../controllers/explore_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../utils/theme.dart';
import '../../../../widgets/navigation/bottom_nav_bar.dart';
import '../../../../widgets/common/property_filter_widget.dart';


class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
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
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ghar360',
                maxZoom: 19,
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white.withOpacity(0.1),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search location...',
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: controller.searchLocation,
                        ),
                      ),
                      Obx(() => controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: controller.clearSearch,
                            )
                          : const SizedBox.shrink()),
                      Obx(() => controller.isSearching.value
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
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
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                      label: 'My Location',
                      onTap: controller.goToCurrentLocation,
                      backgroundColor: Colors.white,
                    ),
                    
                    const Spacer(),
                    
                    // Property Count and Radius Info
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Obx(() => Text(
                        '${controller.visiblePropertyCount} • ${controller.radiusText}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryYellow),
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
              backgroundColor: AppTheme.primaryYellow,
              onPressed: controller.togglePropertyList,
              child: Icon(
                controller.showPropertyList.value 
                    ? Icons.keyboard_arrow_down 
                    : Icons.keyboard_arrow_up,
                color: Colors.black,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: backgroundColor == AppTheme.primaryYellow ? Colors.black : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: backgroundColor == AppTheme.primaryYellow ? Colors.black : Colors.grey[700],
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: controller.togglePropertyList,
                ),
              ],
            ),
          ),
          
          // Property List
          Expanded(
            child: Obx(() => controller.visibleProperties.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No properties found in this area',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
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
              ? AppTheme.primaryYellow.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.selectedPropertyId.value == property.id
                ? AppTheme.primaryYellow
                : Colors.grey[200]!,
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
                    color: Colors.grey[200],
                    child: const Icon(Icons.home, color: Colors.grey),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      '${property.address}, ${property.city}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryYellow,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.propertyType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
} 