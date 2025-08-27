import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/likes_controller.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../../widgets/common/loading_states.dart';
import '../../../../widgets/common/error_states.dart';
import '../../../../widgets/property/compact_property_card.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/widgets/common/unified_app_bar.dart';
import '../../../core/routes/app_routes.dart';

class LikesView extends GetView<LikesController> {
  const LikesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: UnifiedAppBar(
          onSearchTap: () => _showSearchDialog(),
          onRefreshTap: controller.refreshCurrentSegment,
          onFilterTap: () => Get.toNamed(AppRoutes.filters),
        ),
        body: Column(
          children: [
            // Search bar section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Obx(() => TextField(
                onChanged: controller.updateSearchQuery,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search in your likes...',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: controller.hasSearchQuery
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: controller.clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
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
              color: Colors.white,
              child: TabBar(
                labelColor: const Color(0xFFFFC107), // Amber
                unselectedLabelColor: Colors.black54,
                indicatorColor: const Color(0xFFFFC107), // Amber
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
                              color: const Color(0xFFFFC107), // Amber
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
            
            // TabBarView for content
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
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search in your likes...',
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
                onChanged: (value) {
                  controller.updateSearchQuery(value);
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}