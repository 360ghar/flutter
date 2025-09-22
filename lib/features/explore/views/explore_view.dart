import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/controllers/page_state_service.dart';
import '../../../core/data/models/page_state_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/utils/error_mapper.dart';
import 'package:ghar360/core/widgets/common/error_states.dart';
import 'package:ghar360/core/widgets/common/loading_states.dart';
import 'package:ghar360/core/widgets/common/property_filter_widget.dart';
import 'package:ghar360/core/widgets/common/unified_top_bar.dart';
import '../controllers/explore_controller.dart';
import '../widgets/property_horizontal_list.dart';
import '../widgets/property_marker_chip.dart';

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});

  PageStateService get pageStateService => Get.find<PageStateService>();

  @override
  Widget build(BuildContext context) {
    DebugLogger.info(
      '🎨 ExploreView build() called. Current state: ${controller.state.value}',
    );

    return Obx(() {
      final pageStateService = Get.find<PageStateService>();

      // Make Scaffold reactive to search visibility changes for proper space allocation
      final searchVisible = pageStateService.isSearchVisible(PageType.explore);

      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: ExploreTopBar(
          key: ValueKey(
            'explore_topbar_$searchVisible',
          ), // Force recreation when visibility changes
          onSearchChanged: (query) => controller.updateSearchQuery(query),
          onFilterTap:
              () => showPropertyFilterBottomSheet(context, pageType: 'explore'),
        ),
        body: Obx(() {
          final isRefreshing = pageStateService.exploreState.value.isRefreshing;

          return Column(
            children: [
              // Subtle refresh indicator
              if (isRefreshing)
                LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryYellow,
                  ),
                ),
              // Main content
              Expanded(
                child: Obx(() {
                  final currentState = controller.state.value;
                  final propertiesCount = controller.properties.length;
                  DebugLogger.info(
                    '🌨️ View Builder (Obx) - State: $currentState, Properties: $propertiesCount',
                  );

                  switch (currentState) {
                    case ExploreState.loading:
                      // If location is available, keep the map visible and let markers update
                      final hasLocation =
                          Get.find<PageStateService>()
                              .exploreState
                              .value
                              .hasLocation;
                      if (hasLocation) {
                        DebugLogger.info(
                          '💻 Loading properties, rendering map with pending markers',
                        );
                        return _buildMapInterface(context);
                      }
                      DebugLogger.info(
                        '💻 Rendering loading state (no location yet)',
                      );
                      return _buildLoadingState(context);

                    case ExploreState.error:
                      DebugLogger.info('⚠️ Rendering error state');
                      return _buildErrorState();

                    case ExploreState.empty:
                      DebugLogger.info('💭 Rendering empty state');
                      return _buildEmptyState(context);

                    case ExploreState.loaded:
                    case ExploreState.loadingMore:
                      DebugLogger.info(
                        '🗺️ Rendering map interface with $propertiesCount properties',
                      );
                      return _buildMapInterface(context);

                    default:
                      final hasLocation =
                          Get.find<PageStateService>()
                              .exploreState
                              .value
                              .hasLocation;
                      if (hasLocation) {
                        DebugLogger.info(
                          '🔄 Initializing; rendering map while loading',
                        );
                        return _buildMapInterface(context);
                      }
                      DebugLogger.info(
                        '🔄 Rendering default loading state (no location yet)',
                      );
                      return _buildLoadingState(context);
                  }
                }),
              ),
            ],
          );
        }),
      );
    });
  }

  Widget _buildLoadingState(BuildContext context) {
    return Stack(
      children: [
        // Skeleton map
        Container(
          color: AppColors.surface,
          child: Center(
            child: Icon(Icons.map, size: 100, color: AppColors.divider),
          ),
        ),

        // Loading overlay with progress
        Obx(() {
          if (controller.loadingProgress.value > 0) {
            return LoadingStates.progressiveLoadingIndicator(
              current: controller.loadingProgress.value,
              total: controller.totalPages.value,
              message: 'Loading properties for map...',
            );
          }
          return LoadingStates.mapLoadingOverlay(context);
        }),
      ],
    );
  }

  Widget _buildErrorState() {
    return Obx(() {
      final appError = controller.error.value;
      if (appError == null) return const SizedBox();

      try {
        // Pass the actual error object and its stack trace
        final exception = ErrorMapper.mapApiError(
          appError.error,
          appError.stackTrace,
        );
        return ErrorStates.genericError(
          error: exception,
          onRetry: controller.retryLoading,
        );
      } catch (e) {
        return ErrorStates.networkError(
          onRetry: controller.retryLoading,
          customMessage: appError.error.toString(),
        );
      }
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return ErrorStates.emptyState(
      title: 'no_properties_found'.tr,
      message: 'no_properties_found_area_message'.tr,
      icon: Icons.location_off,
      onAction:
          () => showPropertyFilterBottomSheet(
            Get.context ?? context,
            pageType: 'explore',
          ),
      actionText: 'adjust_filters'.tr,
    );
  }

  Widget _buildMapInterface(BuildContext context) {
    DebugLogger.info('🌎 Building map interface');
    return Stack(
      children: [
        // Main map
        Positioned.fill(
          child: Builder(
            builder: (_) {
              try {
                return FlutterMap(
                  key: ValueKey(
                    'map_${controller.currentCenter.value.latitude}_${controller.currentCenter.value.longitude}_${controller.currentZoom.value}',
                  ),
                  mapController: controller.mapController,
                  options: MapOptions(
                    initialCenter: controller.currentCenter.value,
                    initialZoom: controller.currentZoom.value,
                    minZoom: 3.0,
                    maxZoom: 18.0,
                    onPositionChanged: (position, hasGesture) {
                      if (hasGesture && controller.isMapReady.value) {
                        final zoomChanged =
                            (position.zoom - controller.currentZoom.value)
                                .abs() >
                            0.1;
                        final distance = _calculateDistance(
                          controller.currentCenter.value,
                          position.center,
                        );
                        final centerChanged = distance > 100;
                        if (zoomChanged || centerChanged) {
                          controller.onMapMove(position, hasGesture);
                        }
                      }
                    },
                    onMapReady: () {
                      DebugLogger.success('🗺️ Map is ready!');
                      controller.onMapReady();
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ghar360.app',
                      maxZoom: 18,
                    ),
                    RichAttributionWidget(
                      attributions: const [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                    // Search radius circle (reactive)
                    Obx(() {
                      if (!pageStateService.getCurrentPageState().hasLocation) {
                        return const SizedBox.shrink();
                      }
                      return CircleLayer(
                        circles: [
                          CircleMarker(
                            point: controller.currentCenter.value,
                            radius: controller.currentRadius.value * 1000,
                            color: AppColors.primaryYellow.withValues(
                              alpha: 0.1,
                            ),
                            borderColor: AppColors.primaryYellow.withValues(
                              alpha: 0.5,
                            ),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      );
                    }),
                    // Property markers (reactive)
                    Obx(() {
                      final markers = controller.propertyMarkers;
                      if (markers.isEmpty) return const SizedBox.shrink();
                      return MarkerLayer(
                        markers:
                            markers
                                .map(
                                  (marker) => Marker(
                                    point: marker.position,
                                    width: 40,
                                    height: 40,
                                    child: PropertyMarkerChip(
                                      property: marker.property,
                                      isSelected: marker.isSelected,
                                      label: marker.label,
                                      onTap: () {
                                        DebugLogger.info(
                                          'Property marker tapped: ${marker.property.title}',
                                        );
                                        controller.selectProperty(
                                          marker.property,
                                        );
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    }),
                  ],
                );
              } catch (e) {
                DebugLogger.error('❌ Map rendering failed: $e');
                return ErrorStates.networkError(
                  onRetry: controller.retryLoading,
                  customMessage: 'map_render_failed_message'.tr,
                );
              }
            },
          ),
        ),
        // Map controls
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: _buildMapControls(),
        ),
        // Info panel
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          child: _buildInfoPanel(),
        ),
        // Loading indicator for more properties
        if (controller.state.value == ExploreState.loadingMore)
          Positioned(
            bottom: 230,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryYellow,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'loading_more_properties'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Horizontal property list at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: PropertyHorizontalList(controller: controller),
          ),
        ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        // Zoom controls
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: AppColors.getCardShadow(),
          ),
          child: Column(
            children: [
              IconButton(
                icon: Icon(Icons.add, color: AppColors.iconColor),
                onPressed: controller.zoomIn,
              ),
              Container(width: 1, height: 1, color: AppColors.divider),
              IconButton(
                icon: Icon(Icons.remove, color: AppColors.iconColor),
                onPressed: controller.zoomOut,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Current location button
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: AppColors.getCardShadow(),
          ),
          child: IconButton(
            icon: Icon(Icons.my_location, color: AppColors.primaryYellow),
            onPressed: controller.recenterToCurrentLocation,
          ),
        ),

        const SizedBox(height: 12),

        // Fit bounds button
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: AppColors.getCardShadow(),
          ),
          child: IconButton(
            icon: Icon(Icons.center_focus_strong, color: AppColors.accentBlue),
            onPressed: controller.fitBoundsToProperties,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Obx(() {
        final propertiesCountText = controller.propertiesCountText;
        final currentAreaText = controller.currentAreaText;
        final locationDisplayText = controller.locationDisplayText;

        DebugLogger.info(
          '📊 Info panel update - properties: $propertiesCountText, area: $currentAreaText',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              propertiesCountText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentAreaText,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            if (locationDisplayText != 'All Locations' &&
                locationDisplayText != 'Select Location') ...[
              const SizedBox(height: 4),
              Text(
                locationDisplayText,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryYellow,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  // Bottom sheet removed in favor of persistent horizontal list

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLat =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLng =
        (point2.longitude - point1.longitude) * (math.pi / 180);
    final double a =
        (math.sin(deltaLat / 2) * math.sin(deltaLat / 2)) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            (math.sin(deltaLng / 2) * math.sin(deltaLng / 2));
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }
}
