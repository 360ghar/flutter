import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/discover_controller.dart';
import '../../../core/controllers/filter_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../../widgets/common/loading_states.dart';
import '../../../../widgets/common/error_states.dart';
import '../widgets/property_swipe_card.dart';

class DiscoverView extends GetView<DiscoverController> {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    final filterService = Get.find<FilterService>();

    return Obx(() => Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'app_name'.tr,
          style: TextStyle(
            color: AppColors.appBarText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Filters button
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
        // Show different states based on controller state
        switch (controller.state.value) {
          case DiscoverState.loading:
            return _buildLoadingState();
            
          case DiscoverState.error:
            return _buildErrorState();
            
          case DiscoverState.empty:
            return _buildEmptyState();
            
          case DiscoverState.loaded:
          case DiscoverState.prefetching:
            return _buildSwipeInterface(context);
            
          default:
            return _buildLoadingState();
        }
      }),
    ));
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        // Show loading progress if available
        Obx(() {
          if (controller.isPrefetching.value) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading more properties...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        }),
        
        // Main loading
        Expanded(
          child: LoadingStates.swipeCardSkeleton(),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Obx(() {
      final errorMessage = controller.error.value;
      if (errorMessage == null) return const SizedBox();
      
      // Try to map the error for better user experience
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
    return ErrorStates.swipeDeckEmpty(
      onRefresh: controller.refreshDeck,
      onChangeFilters: () => Get.toNamed('/filters'),
    );
  }

  Widget _buildSwipeInterface(BuildContext context) {
    return Stack(
      children: [
        // Main swipe cards
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() => PropertySwipeStack(
              properties: controller.deck.take(3).toList(), // Show max 3 cards in stack
              onSwipeLeft: controller.swipeLeft,
              onSwipeRight: controller.swipeRight,
              onSwipeUp: (property) => controller.viewPropertyDetails(property),
              showSwipeInstructions: controller.totalSwipesInSession.value < 3,
            )),
          ),
        ),
        
        
      ],
    );
  }

}