import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import '../controllers/explore_controller.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/controllers/page_state_service.dart';
import '../../../core/data/models/page_state_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../../widgets/common/loading_states.dart';
import '../../../../widgets/common/error_states.dart';
import '../../../../widgets/common/robust_network_image.dart';
import '../../../../widgets/common/unified_top_bar.dart';
import '../../../widgets/common/property_filter_widget.dart';

class ExploreView extends GetView<ExploreController> {
  const ExploreView({super.key});
  
  FilterService get filterService => Get.find<FilterService>();

  @override
  Widget build(BuildContext context) {
    DebugLogger.info('🎨 ExploreView build() called. Current state: ${controller.state.value}');

    return Obx(() {
      final pageStateService = Get.find<PageStateService>();
      
      // Make Scaffold reactive to search visibility changes for proper space allocation
      final searchVisible = pageStateService.isSearchVisible(PageType.explore);
      
      return Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: ExploreTopBar(
          key: ValueKey('explore_topbar_$searchVisible'), // Force recreation when visibility changes
          onSearchChanged: (query) => controller.updateSearchQuery(query),
          onFilterTap: () => showPropertyFilterBottomSheet(context, pageType: 'explore'),
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                ),
              // Main content
              Expanded(
                child: Obx(() {
                  final currentState = controller.state.value;
                  final propertiesCount = controller.properties.length;
                  DebugLogger.info('🌨️ View Builder (Obx) - State: $currentState, Properties: $propertiesCount');
                  
                  switch (currentState) {
                    case ExploreState.loading:
                      DebugLogger.info('💻 Rendering loading state');
                      return _buildLoadingState();
                      
                    case ExploreState.error:
                      DebugLogger.info('⚠️ Rendering error state');
                      return _buildErrorState();
                      
                    case ExploreState.empty:
                      DebugLogger.info('💭 Rendering empty state');
                      return _buildEmptyState(context);
                      
                    case ExploreState.loaded:
                    case ExploreState.loadingMore:
                      DebugLogger.info('🗺️ Rendering map interface with $propertiesCount properties');
                      return _buildMapInterface(context);
                      
                    default:
                      DebugLogger.info('🔄 Rendering default loading state');
                      return _buildLoadingState();
                  }
                }),
              ),
            ],
          );
        }),
      );
    });
  }

  Widget _buildLoadingState() {
    return Stack(
      children: [
        // Skeleton map
        Container(
          color: AppColors.surface,
          child: Center(
            child: Icon(
              Icons.map,
              size: 100,
              color: AppColors.divider,
            ),
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
          return LoadingStates.mapLoadingOverlay();
        }),
      ],
    );
  }

  Widget _buildErrorState() {
    return Obx(() {
      final errorMessage = controller.error.value;
      if (errorMessage == null) return const SizedBox();
      
      try {
        final exception = ErrorMapper.mapApiError(Exception(errorMessage));
        return ErrorStates.genericError(
          error: exception,
          onRetry: controller.retryLoading,
        );
      } catch (e) {
        return ErrorStates.networkError(
          onRetry: controller.retryLoading,
          customMessage: errorMessage,
        );
      }
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return ErrorStates.emptyState(
      title: 'No Properties Found',
      message: 'No properties found in this area.\nTry adjusting your search location or filters.',
      icon: Icons.location_off,
      onAction: () => showPropertyFilterBottomSheet(Get.context ?? context, pageType: 'explore'),
      actionText: 'Adjust Filters',
    );
  }

  Widget _buildMapInterface(BuildContext context) {
    DebugLogger.info('🌎 Building map interface');
    return Stack(
      children: [
        // Main map
        Positioned.fill(
          child: Obx(() {
            final markers = controller.propertyMarkers;
            DebugLogger.info('🗺️ Map rebuild - ${markers.length} markers, center: ${controller.currentCenter.value}');
            
            return FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(
                initialCenter: controller.currentCenter.value,
                initialZoom: controller.currentZoom.value,
                onPositionChanged: controller.onMapMove,
                onMapReady: () {
                  DebugLogger.success('🗺️ Map is ready!');
                  // Map is now ready for programmatic moves
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // Map tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ghar360.app',
                  maxZoom: 19,
                ),
                
                // Search radius circle
                if (filterService.hasLocation)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: controller.currentCenter.value,
                        radius: controller.currentRadius.value * 1000, // Convert to meters
                        color: AppColors.primaryYellow.withValues(alpha: 0.1),
                        borderColor: AppColors.primaryYellow.withValues(alpha: 0.5),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                
                // Property markers
                if (markers.isNotEmpty)
                  MarkerLayer(
                    markers: markers.map((marker) => Marker(
                      point: marker.position,
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          DebugLogger.info('📍 Property marker tapped: ${marker.property.title}');
                          controller.selectProperty(marker.property);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: marker.isSelected ? AppColors.primaryYellow : AppColors.accentBlue,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              marker.property.formattedPrice.isNotEmpty 
                                ? (marker.property.formattedPrice.length > 4 
                                   ? marker.property.formattedPrice.substring(0, 4)
                                   : marker.property.formattedPrice)
                                : '₹--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
              ],
            );
          }),
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
            bottom: 100,
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading more properties...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Selected property bottom sheet
        Obx(() {
          final hasSelection = controller.hasSelection;
          DebugLogger.info('📋 Bottom sheet update - has selection: $hasSelection');
          
          if (hasSelection) {
            return _buildPropertyBottomSheet();
          }
          return const SizedBox();
        }),
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
              Container(
                width: 1,
                height: 1,
                color: AppColors.divider,
              ),
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
        
        DebugLogger.info('📊 Info panel update - properties: $propertiesCountText, area: $currentAreaText');
        
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
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (locationDisplayText != 'All Locations' && locationDisplayText != 'Select Location') ...[
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

  Widget _buildPropertyBottomSheet() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: AppColors.getCardShadow(),
        ),
        child: Obx(() {
          final property = controller.selectedProperty.value;
          if (property == null) {
            DebugLogger.info('🏠 Bottom sheet - no property selected');
            return const SizedBox();
          }
          
          DebugLogger.info('🏠 Bottom sheet rebuilding for property: ${property.title}');
          
          return Column(
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
              
              // Property details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Property image
                      RobustNetworkImage(
                        imageUrl: property.mainImage,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(12),
                        errorWidget: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.home, color: AppColors.iconColor),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Property info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              property.addressDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  property.formattedPrice,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryYellow,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    property.purposeString,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Action buttons
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.close, color: AppColors.textSecondary),
                            onPressed: controller.clearSelection,
                          ),
                          IconButton(
                            icon: Icon(Icons.info, color: AppColors.primaryYellow),
                            onPressed: () => controller.viewPropertyDetails(property),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

}
