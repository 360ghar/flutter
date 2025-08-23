import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/likes_controller.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../../widgets/common/loading_states.dart';
import '../../../../widgets/common/error_states.dart';
import '../../../../widgets/property/compact_property_card.dart';
import '../../../core/data/models/property_model.dart';

class LikesView extends GetView<LikesController> {
  const LikesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(200), // --- THIS IS THE FIX ---
          // Increased height from 180 to 200 to prevent overflow.
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main app bar
                AppBar(
                  backgroundColor: AppColors.appBarBackground,
                  elevation: 0,
                  toolbarHeight: kToolbarHeight,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'My Likes',
                    style: TextStyle(
                      color: AppColors.appBarText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    // View toggle (grid/list)
                    IconButton(
                      icon: Icon(
                        Icons.view_module,
                        color: AppColors.iconColor,
                      ),
                      onPressed: () {
                        // Toggle view mode if needed
                      },
                    ),
                  ],
                ),
                
                // Search bar
                Container(
                  color: AppColors.appBarBackground,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Obx(() => TextField(
                    onChanged: controller.updateSearchQuery,
                    style: TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search in your likes...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, color: AppColors.iconColor),
                      suffixIcon: controller.hasSearchQuery
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.iconColor),
                              onPressed: controller.clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.inputBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  )),
                ),
                
                // Tab bar
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
                            Icon(Icons.favorite, size: 18),
                            const SizedBox(width: 8),
                            Text('Liked'),
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
                            Icon(Icons.not_interested, size: 18),
                            const SizedBox(width: 8),
                            Text('Passed'),
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
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildLikesTab(),
            _buildPassedTab(),
          ],
        ),
      ),
    );
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
                
                return CompactPropertyCard(
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