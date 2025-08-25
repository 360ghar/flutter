import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import '../controllers/explore_controller.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../../widgets/common/loading_states.dart';
import '../../../../widgets/common/error_states.dart';
import '../../../../widgets/common/robust_network_image.dart';

class ExploreView extends GetView<ExploreController> {
  ExploreView({super.key});
  
  FilterService get filterService => Get.find<FilterService>();

  @override
  Widget build(BuildContext context) {
    DebugLogger.info('🎨 ExploreView build() called. Current state: ${controller.state.value}');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'Explore Properties',
          style: TextStyle(
            color: AppColors.appBarText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Search toggle
          Obx(() => IconButton(
            icon: Icon(
              controller.searchQuery.value.isEmpty ? Icons.search : Icons.search_off,
              color: AppColors.iconColor,
            ),
            onPressed: () => _toggleSearch(context),
          )),
          
          // Filters
          Obx(() => IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.tune,
                  color: AppColors.iconColor,
                ),
                if (filterService.activeFiltersCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${filterService.activeFiltersCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Get.toNamed('/filters'),
          )),
        ],
      ),
      body: Obx(() {
        switch (controller.state.value) {
          case ExploreState.loading:
            return _buildLoadingState();
            
          case ExploreState.error:
            return _buildErrorState();
            
          case ExploreState.empty:
            return _buildEmptyState();
            
          case ExploreState.loaded:
          case ExploreState.loadingMore:
            return _buildMapInterface(context);
            
          default:
            return _buildLoadingState();
        }
      }),
    );
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

  Widget _buildEmptyState() {
    return ErrorStates.emptyState(
      title: 'No Properties Found',
      message: 'No properties found in this area.\nTry adjusting your search location or filters.',
      icon: Icons.location_off,
      onAction: () => Get.toNamed('/filters'),
      actionText: 'Adjust Filters',
    );
  }

  Widget _buildMapInterface(BuildContext context) {
    return Stack(
      children: [
        // Main map
        Positioned.fill(
          child: Obx(() => FlutterMap(
            mapController: controller.mapController,
            options: MapOptions(
              initialCenter: controller.currentCenter.value,
              initialZoom: controller.currentZoom.value,
              onPositionChanged: controller.onMapMove,
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
                      color: AppColors.primaryYellow.withOpacity(0.1),
                      borderColor: AppColors.primaryYellow.withOpacity(0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              
              // Property markers
              MarkerLayer(
                markers: controller.propertyMarkers.map((marker) => Marker(
                  point: marker.position,
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => controller.selectProperty(marker.property),
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
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          marker.property.formattedPrice.replaceAll('₹', '₹').substring(0, 4),
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
          )),
        ),
        
        // Search bar (if active)
        Obx(() {
          if (controller.searchQuery.value.isNotEmpty || _isSearching.value) {
            return _buildSearchBar(context);
          }
          return const SizedBox();
        }),
        
        // Map controls
        Positioned(
          top: MediaQuery.of(context).padding.top + (controller.searchQuery.value.isNotEmpty || _isSearching.value ? 70 : 10),
          right: 16,
          child: _buildMapControls(),
        ),
        
        // Info panel
        Positioned(
          top: MediaQuery.of(context).padding.top + (controller.searchQuery.value.isNotEmpty || _isSearching.value ? 70 : 10),
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
                color: AppColors.surface.withOpacity(0.9),
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
          if (controller.hasSelection) {
            return _buildPropertyBottomSheet();
          }
          return const SizedBox();
        }),
      ],
    );
  }

  // Track search state
  final RxBool _isSearching = false.obs;

  Widget _buildSearchBar(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: AppColors.getCardShadow(),
        ),
        child: TextField(
          onChanged: controller.updateSearchQuery,
          onSubmitted: (value) {
            if (value.isEmpty) _isSearching.value = false;
          },
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search locations...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            prefixIcon: Icon(Icons.search, color: AppColors.iconColor),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: AppColors.iconColor),
              onPressed: () {
                controller.clearSearch();
                _isSearching.value = false;
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
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
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            controller.propertiesCountText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            controller.currentAreaText,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (controller.locationDisplayText != 'All Locations') ...[
            const SizedBox(height: 4),
            Text(
              controller.locationDisplayText,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryYellow,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      )),
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
          if (property == null) return const SizedBox();
          
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
                                    color: AppColors.accentBlue.withOpacity(0.1),
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

  void _toggleSearch(BuildContext context) {
    if (controller.searchQuery.value.isNotEmpty) {
      controller.clearSearch();
      _isSearching.value = false;
    } else {
      _isSearching.value = true;
    }
  }
}