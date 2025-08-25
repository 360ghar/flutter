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

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        switch (controller.state.value) {
          case ExploreState.loading:
          case ExploreState.initial:
            return _buildLoadingState();
          case ExploreState.error:
            return _buildErrorState();
          case ExploreState.empty:
            return _buildEmptyState();
          case ExploreState.loaded:
          case ExploreState.loadingMore:
            return _buildMapWithProperties();
        }
      }),
    );
  }

  Widget _buildMapWithProperties() {
    return Stack(
      children: [
        // Map Layer with enhanced event handling
        _buildMap(),

        // Property Carousel (only show if property is selected)
        _buildPropertyCarousel(),

        // App Bar Overlay
        _buildAppBar(),

        // Location Search
        const LocationSearch(),

        // Map Controls
        _buildMapControls(),

        // Info Panel
        _buildInfoPanel(),

        // Loading Overlay
        _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildMap() {
    return Obx(() {
      final mapCenter = controller.mapCenter.value ?? const LatLng(28.6139, 77.2090);
      final zoom = controller.currentZoom.value;

      return FlutterMap(
        options: MapOptions(
          initialCenter: mapCenter,
          initialZoom: zoom,
          minZoom: 3.0,
          maxZoom: 18.0,
          onPositionChanged: (position, hasGesture) {
            if (hasGesture && controller.isMapReady.value) {
              // Update zoom if changed significantly
              if ((position.zoom - controller.currentZoom.value).abs() > 0.1) {
                controller.onMapZoomChanged(position.zoom);
              }

              // Update center if moved significantly (more than 100 meters)
              final distance = _calculateDistance(
                controller.currentCenter.value,
                position.center,
              );

              if (distance > 100) {
                controller.onMapMoved(position.center);
              }
            }
          },
          onMapReady: () {
            controller.onMapReady();
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            maxZoom: 18,
          ),

          // Property Markers Layer
          Obx(() => MarkerLayer(
            markers: controller.propertyMarkers.map((marker) {
              return Marker(
                width: marker.isSelected ? 50.0 : 40.0,
                height: marker.isSelected ? 50.0 : 40.0,
                point: marker.position,
                child: GestureDetector(
                  onTap: () => controller.onPropertySelected(marker.property),
                  child: Container(
                    decoration: BoxDecoration(
                      color: marker.isSelected
                          ? AppColors.primaryYellow
                          : Colors.white,
                      border: Border.all(
                        color: marker.isSelected
                            ? Colors.white
                            : AppColors.primaryYellow,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.home,
                      color: marker.isSelected
                          ? Colors.white
                          : AppColors.primaryYellow,
                      size: marker.isSelected ? 24 : 20,
                    ),
                  ),
                ),
              );
            }).toList(),
          )),

          // Current Location Marker
          Obx(() {
            final center = controller.currentCenter.value;
            return MarkerLayer(
              markers: [
                Marker(
                  width: 20.0,
                  height: 20.0,
                  point: center,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      );
    });
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



  Widget _buildPropertyCarousel() {
    return Obx(() {
      if (controller.selectedProperty.value == null) {
        return const SizedBox.shrink();
      }
      return Positioned(
        bottom: 20,
        left: 0,
        right: 0,
        child: SizedBox(
          height: 320,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: 1,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: PropertyCard(
                  property: controller.selectedProperty.value!,
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildLoadingOverlay() {
    return Obx(() {
      if (!controller.isLoadingProperties.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: MediaQuery.of(Get.context!).padding.top + 70,
        left: 0,
        right: 0,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Properties Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or moving the map to a different area.',
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
              ),
              child: const Text(
                'Retry Search',
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

  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white.withOpacity(0.95),
        padding: EdgeInsets.only(
          top: MediaQuery.of(Get.context!).padding.top,
          bottom: 8,
        ),
        child: Row(
          children: [
            // Location Button
            Expanded(
              child: InkWell(
                onTap: () => LocationSearch.showLocationSearch(Get.context!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Obx(() => Expanded(
                        child: Text(
                          controller.currentLocationText.value,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Filters Button
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: () => Get.toNamed('/filters'),
                    color: Colors.grey[700],
                  ),
                  Obx(() {
                    final filterCount = Get.find<FilterService>().activeFiltersCount;
                    if (filterCount > 0) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryYellow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$filterCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMapControls() {
    return Positioned(
      right: 16,
      bottom: controller.hasSelection ? 360 : 220,
      child: Column(
        children: [
          // Zoom In
          _buildMapControlButton(
            icon: Icons.add,
            onPressed: controller.zoomIn,
          ),

          const SizedBox(height: 8),

          // Zoom Out
          _buildMapControlButton(
            icon: Icons.remove,
            onPressed: controller.zoomOut,
          ),

          const SizedBox(height: 8),

          // Current Location
          _buildMapControlButton(
            icon: Icons.my_location,
            onPressed: controller.recenterToCurrentLocation,
            color: AppColors.primaryYellow,
          ),

          const SizedBox(height: 8),

          // Fit Bounds
          _buildMapControlButton(
            icon: Icons.center_focus_strong,
            onPressed: controller.fitBoundsToProperties,
          ),

          const SizedBox(height: 8),

          // Refresh
          _buildMapControlButton(
            icon: Icons.refresh,
            onPressed: controller.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: color ?? Colors.grey[700],
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Positioned(
      left: 16,
      bottom: controller.hasSelection ? 360 : 220,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.propertiesCountText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.currentAreaText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.locationDisplayText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        )),
      ),
    );
  }




}