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

        // Top App Bar with Location, Search, and Filters
        _buildTopAppBar(),



        // Map Controls
        _buildMapControls(),

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
    return Obx(() {
      final mapCenter = controller.mapCenter.value;
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
                          color: Colors.black.withValues(alpha: 0.2),
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

  Widget _buildPropertyList() {
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final listHeight = screenHeight > 700 ? 220.0 : 200.0; // Responsive height

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: listHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Obx(() {
          if (controller.properties.isEmpty) {
            return Column(
              children: [
                // Handle for dragging
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'No properties found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
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
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Property count and refresh indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                      '${controller.properties.length} properties',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    )),
                    Obx(() => controller.isLoadingProperties.value
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Refreshing...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh, size: 16),
                          onPressed: controller.refresh,
                          color: Colors.grey[600],
                        )),
                  ],
                ),
              ),

              // Horizontal property list
              Expanded(
                child: ListView.builder(
                  controller: controller.horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.properties.length + (controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Loading indicator at the end
                    if (index == controller.properties.length && controller.isLoadingMore.value) {
                      return Container(
                        width: 320,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
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
                      onLikeTap: () => controller.toggleLikeProperty(property),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Obx(() {
      if (!controller.isLoadingProperties.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: MediaQuery.of(Get.context!).padding.top + 120,
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



  Widget _buildTopAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.white.withValues(alpha: 0.95),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Bar Row with Location, Search, Refresh, Filter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Location Selector (First)
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => LocationSearch.showLocationSearch(Get.context!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Obx(() => Expanded(
                                child: Text(
                                  controller.currentLocationText.value,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Search Toggle (Second)
                    IconButton(
                      icon: Obx(() => Icon(
                        controller.isSearchActive.value ? Icons.search_off : Icons.search,
                        color: Colors.grey[700],
                        size: 22,
                      )),
                      onPressed: () {
                        if (controller.isSearchActive.value) {
                          controller.deactivateSearchMode();
                        } else {
                          controller.activateSearchMode();
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                    // Refresh Indicator (Third)
                    Obx(() {
                      if (controller.isLoadingProperties.value) {
                        return Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(left: 8, right: 8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                          ),
                        );
                      }
                      return IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.grey),
                        onPressed: controller.refresh,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),

                    // Filter Button (Fourth)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.tune),
                            onPressed: () => Get.toNamed('/filters'),
                            color: Colors.grey[700],
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Obx(() {
                            final filterCount = Get.find<FilterService>().activeFiltersCount;
                            if (filterCount > 0) {
                              return Positioned(
                                right: 0,
                                top: 0,
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

              // Search Bar (when active)
              Obx(() {
                if (controller.isSearchActive.value) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        // Search Input Field
                        TextField(
                          controller: TextEditingController(text: controller.searchQuery.value),
                          onChanged: controller.updateSearchQuery,
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              controller.performSearch(value);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search locations...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: Obx(() {
                              if (controller.searchQuery.value.isNotEmpty) {
                                return IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: controller.clearSearch,
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.primaryYellow),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),

                        // Search Results (if any)
                        if (controller.searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: controller.searchResults.length,
                              itemBuilder: (context, index) {
                                final result = controller.searchResults[index];
                                return InkWell(
                                  onTap: () {
                                    controller.selectLocationResult(result);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: index < controller.searchResults.length - 1
                                          ? Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5))
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                result.displayText ?? result.description,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (result.structuredFormatting != null &&
                                                  result.structuredFormatting != result.displayText)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    result.structuredFormatting!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey[400],
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
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

  Widget _buildMapControls() {
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final listHeight = screenHeight > 700 ? 220.0 : 200.0;
    final bottomPosition = listHeight + 20;

    return Positioned(
      right: 16,
      bottom: bottomPosition,
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
            color: Colors.black.withValues(alpha: 0.1),
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
    final screenHeight = MediaQuery.of(Get.context!).size.height;
    final listHeight = screenHeight > 700 ? 220.0 : 200.0;
    final bottomPosition = listHeight + 20;

    return Positioned(
      left: 16,
      bottom: bottomPosition, // Position above the property list
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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