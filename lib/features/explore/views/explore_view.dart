import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/explore_controller.dart';
import '../widgets/property_card.dart';
import '../widgets/location_search.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/common/unified_app_bar.dart';

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: UnifiedAppBar(
        onSearchTap: () => _showSearchDialog(),
        onRefreshTap: controller.refresh,
        onFilterTap: () => Get.toNamed(AppRoutes.filters),
        onLocationTap: () => LocationSearch.showLocationSearch(context),
      ),
      body: Obx(() {
        switch (controller.state.value) {
          case ExploreState.loading:
          case ExploreState.initial:
            return _buildLoadingState();
          case ExploreState.error:
            return _buildErrorState();
          case ExploreState.empty:
          case ExploreState.loaded:
          case ExploreState.loadingMore:
            return _buildExploreInterface();
        }
      }),
    );
  }

  Widget _buildExploreInterface() {
    return Stack(
      children: [
        // Full Screen Map
        _buildMap(),

        // Info Panel
        _buildInfoPanel(),

        // Horizontal Property List at Bottom
        _buildPropertyList(),

        // Loading Overlay
        _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildMap() {
    // Get initial values once to reduce reactive dependencies
    final mapCenter = controller.mapCenter.value ?? controller.currentCenter.value;
    final zoom = controller.currentZoom.value;

    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: zoom,
          minZoom: 3.0,
          maxZoom: 18.0,
          onPositionChanged: (position, hasGesture) {
            if (hasGesture && controller.isMapReady.value) {
              // Update zoom if changed significantly (reduce sensitivity)
              if ((position.zoom - controller.currentZoom.value).abs() > 0.5) {
                controller.onMapZoomChanged(position.zoom);
              }

              // Update center if moved significantly (increase threshold to 500 meters)
              final distance = _calculateDistance(
                controller.currentCenter.value,
                position.center,
              );

              if (distance > 500) {
                controller.onMapMoved(position.center);
              }
            }
          },
          onMapReady: () {
            controller.onMapReady();
          },
        ),
        children: [
          // OpenStreetMap Tile Layer
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            maxZoom: 18,
          ),

          // Search Radius Indicator Circle
          Obx(() {
            final center = controller.currentCenter.value;
            final radiusKm = controller.currentRadius.value;
            
            return CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: _kmToMapRadius(radiusKm, zoom, center.latitude),
                  color: AppColors.primaryYellow.withValues(alpha: 0.1),
                  borderColor: AppColors.primaryYellow.withValues(alpha: 0.3),
                  borderStrokeWidth: 2,
                  useRadiusInMeter: false,
                ),
              ],
            );
          }),

          // Property Markers Layer
          Obx(() => MarkerLayer(
            markers: controller.propertyMarkers.map((marker) {
              return Marker(
                width: marker.isSelected ? 50.0 : 40.0,
                height: marker.isSelected ? 50.0 : 40.0,
                point: marker.position,
                child: GestureDetector(
                  onTap: () => controller.onPropertySelected(marker.property),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: marker.isSelected
                          ? AppColors.primaryYellow
                          : Colors.white,
                      border: Border.all(
                        color: marker.isSelected
                            ? Colors.white
                            : AppColors.primaryYellow,
                        width: marker.isSelected ? 3 : 2,
                      ),
                      borderRadius: BorderRadius.circular(marker.isSelected ? 25 : 20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: marker.isSelected ? 0.3 : 0.2),
                          blurRadius: marker.isSelected ? 6 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.home,
                      color: marker.isSelected
                          ? Colors.white
                          : AppColors.primaryYellow,
                      size: marker.isSelected ? 26 : 20,
                    ),
                  ),
                ),
              );
            }).toList(),
          )),

          // Current Location Marker
          Obx(() {
            final currentPosition = controller.currentCenter.value;
            return MarkerLayer(
              markers: [
                Marker(
                  width: 24.0,
                  height: 24.0,
                  point: currentPosition,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
    );
  }

  // Helper method to calculate distance between two points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLng = (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a = (math.sin(deltaLat / 2) * math.sin(deltaLat / 2)) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        (math.sin(deltaLng / 2) * math.sin(deltaLng / 2));
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  // Helper to convert km to map radius based on zoom and latitude
  double _kmToMapRadius(double km, double zoom, double latitude) {
    // Approximate conversion based on zoom level and latitude
    // This is a simplified calculation - for more accuracy, use proper map projections
    final double metersPerPixel = 156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);
    return (km * 1000) / metersPerPixel;
  }

  Widget _buildPropertyList() {
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final listHeight = screenHeight > 700 ? 240.0 : 200.0; // Responsive height

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: listHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Obx(() {
          if (controller.properties.isEmpty && !controller.isLoadingProperties.value) {
            return Column(
              children: [
                // Handle for dragging
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No properties found',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try adjusting filters or moving the map',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              // Handle for dragging
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Property count and refresh indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                      '${controller.properties.length} properties found',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    )),
                    Obx(() => controller.isLoadingProperties.value
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Updating...',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: controller.refresh,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Horizontal property list
              Expanded(
                child: ListView.builder(
                  controller: controller.horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: controller.properties.length + (controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == controller.properties.length && controller.isLoadingMore.value) {
                      return Container(
                        width: 320,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                          ),
                        ),
                      );
                    }

                    // Property card
                    final property = controller.properties[index];
                    final isSelected = controller.selectedProperty.value?.id == property.id;

                    return PropertyCard(
                      property: property,
                      isSelected: isSelected,
                      onTap: () => controller.onPropertySelectedFromList(property, index),
                      onViewDetails: () => controller.viewPropertyDetails(property),
                      onLikeTap: () => controller.toggleLikeProperty(property),
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Obx(() {
      if (!controller.isLoadingProperties.value || controller.properties.isNotEmpty) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: MediaQuery.of(Get.context!).padding.top + 140,
        left: 0,
        right: 0,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Loading properties...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                if (controller.loadingProgress.value > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${controller.loadingProgress.value}%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading map...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Setting up your location and loading properties',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load map',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: controller.fetchPropertiesForMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                controller: TextEditingController(text: controller.searchQuery.value),
                onChanged: controller.updateSearchQuery,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    controller.performSearch(value);
                    Get.back();
                  }
                },
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
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.searchResults.isNotEmpty) {
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: controller.searchResults.length.clamp(0, 5),
                      itemBuilder: (context, index) {
                        final result = controller.searchResults[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                          title: Text(
                            result.description,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            controller.selectLocationResult(result);
                            Get.back();
                          },
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildInfoPanel() {
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final listHeight = screenHeight > 700 ? 240.0 : 200.0;
    final bottomPosition = listHeight + 20;

    return Positioned(
      left: 16,
      bottom: bottomPosition,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: controller.properties.isNotEmpty
                        ? Colors.green
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  controller.propertiesCountText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              controller.currentAreaText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: AppColors.primaryYellow,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.locationDisplayText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        )),
      ),
    );
  }
}