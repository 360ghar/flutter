import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/likes_controller.dart';
import '../../../core/controllers/page_state_service.dart';
import '../../../core/data/models/page_state_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../widgets/common/loading_states.dart';
import '../../../widgets/common/error_states.dart';
import '../widgets/likes_property_card.dart';
import '../../../core/data/models/property_model.dart';
import '../../../widgets/common/unified_top_bar.dart';
import '../../../widgets/common/property_filter_widget.dart';

class LikesView extends GetView<LikesController> {
  const LikesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final pageStateService = Get.find<PageStateService>();
      
      // Make Scaffold reactive to search visibility changes for proper space allocation
      final searchVisible = pageStateService.isSearchVisible(PageType.likes);
      
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: LikesTopBar(
            key: ValueKey('likes_topbar_$searchVisible'), // Force recreation when visibility changes
            onSearchChanged: controller.updateSearchQuery,
            onFilterTap: () => showPropertyFilterBottomSheet(context, pageType: 'likes'),
          ),
        body: Column(
          children: [
            // Subtle refresh indicator
            if (pageStateService.likesState.value.isRefreshing)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
              ),
            // Tab bar directly under the unified top bar
            Container(
              color: AppColors.appBarBackground,
              child: TabBar(
                labelColor: AppColors.primaryYellow,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryYellow,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                onTap: (index) {
                  final segment = index == 0 ? LikesSegment.liked : LikesSegment.passed;
                  controller.switchToSegment(segment);
                },
                tabs: [
                  Tab(
                    child: Obx(() => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 18),
                        const SizedBox(width: 8),
                        const Text('Liked'),
                        if (controller.currentSegment.value == LikesSegment.liked &&
                            controller.hasCurrentProperties) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryYellow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${controller.currentProperties.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )),
                  ),
                  Tab(
                    child: Obx(() => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.not_interested, size: 18),
                        const SizedBox(width: 8),
                        const Text('Passed'),
                        if (controller.currentSegment.value == LikesSegment.passed &&
                            controller.hasCurrentProperties) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${controller.currentProperties.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildLikesTab(),
                  _buildPassedTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
  }

  Widget _buildLikesTab() {
    return Obx(() {
      // Handle different states
      if (controller.isCurrentLoading) {
        return LoadingStates.propertyGridSkeleton();
      }
      
      if (controller.hasCurrentError) {
        return _buildErrorState();
      }
      
      if (controller.isCurrentEmpty) {
        return _buildEmptyState(true);
      }
      
      return _buildPropertyGrid();
    });
  }

  Widget _buildPassedTab() {
    return Obx(() {
      // Handle different states
      if (controller.isCurrentLoading) {
        return LoadingStates.propertyGridSkeleton();
      }
      
      if (controller.hasCurrentError) {
        return _buildErrorState();
      }
      
      if (controller.isCurrentEmpty) {
        return _buildEmptyState(false);
      }
      
      return _buildPropertyGrid();
    });
  }

  Widget _buildPropertyGrid() {
    return RefreshIndicator(
      onRefresh: controller.refreshCurrentSegment,
      color: AppColors.primaryYellow,
      child: CustomScrollView(
        slivers: [
          // Results header
          SliverToBoxAdapter(
            child: Obx(() => Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    controller.currentCountText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (controller.hasSearchQuery)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Filtered',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ),
                ],
              ),
            )),
          ),
          
          // Properties grid
          Obx(() => SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final properties = controller.currentProperties;
                
                // Show load more indicator at the end
                if (index == properties.length) {
                  if (controller.currentHasMore && !controller.isCurrentLoadingMore) {
                    // Trigger load more
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      controller.loadMoreCurrentSegment();
                    });
                  }
                  
                  return controller.isCurrentLoadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : const SizedBox();
                }
                
                final property = properties[index];
                final isLiked = controller.currentSegment.value == LikesSegment.liked;
                
                return LikesPropertyCard(
                  property: property,
                  isFavourite: isLiked,
                  onFavouriteToggle: () => _handleFavoriteToggle(property, isLiked),
                );
              },
              childCount: controller.currentProperties.length + 
                         (controller.currentHasMore || controller.isCurrentLoadingMore ? 1 : 0),
            ),
          )),
          
          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Obx(() {
      final errorMessage = controller.currentError;
      if (errorMessage == null) return const SizedBox();
      
      try {
        final exception = ErrorMapper.mapApiError(Exception(errorMessage));
        return ErrorStates.genericError(
          error: exception,
          onRetry: controller.retryCurrentSegment,
        );
      } catch (e) {
        return ErrorStates.networkError(
          onRetry: controller.retryCurrentSegment,
          customMessage: errorMessage,
        );
      }
    });
  }

  Widget _buildEmptyState(bool isLiked) {
    if (controller.hasSearchQuery) {
      return ErrorStates.searchEmpty(
        searchQuery: controller.searchQuery.value,
        onClearSearch: controller.clearSearch,
      );
    }
    
    return ErrorStates.emptyState(
      title: isLiked ? 'No Liked Properties' : 'No Passed Properties',
      message: controller.emptyStateMessage,
      icon: isLiked ? Icons.favorite_border : Icons.not_interested,
      onAction: () => Get.offNamed('/discover'),
      actionText: 'Explore Properties',
    );
  }

  void _handleFavoriteToggle(PropertyModel property, bool isCurrentlyLiked) {
    if (isCurrentlyLiked) {
      // Remove from likes
      controller.removeFromLikes(property);
    } else {
      // This would be moving from passed to liked
      // For now, just show a message
      Get.snackbar(
        'Info',
        'Feature coming soon: Move to liked properties',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.1),
        colorText: AppColors.primaryYellow,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
