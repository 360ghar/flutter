import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/discover_controller.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/controllers/page_state_service.dart';
import '../../../widgets/common/loading_states.dart';
import '../../../widgets/common/error_states.dart';
import '../../../widgets/common/unified_top_bar.dart';
import '../../../widgets/common/property_filter_widget.dart';
import '../widgets/property_swipe_card.dart';

class DiscoverView extends GetView<DiscoverController> {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    final pageStateService = Get.find<PageStateService>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: DiscoverTopBar(
        onFilterTap: () =>
            showPropertyFilterBottomSheet(context, pageType: 'discover'),
      ),
      body: Obx(() {
        // Debug snapshot of controller and page state for diagnosing stuck loaders
        // ignore: unused_local_variable
        final debug = () {
          try {
            final ps = pageStateService.discoverState.value;
            // Lightweight log; avoid spamming every frame
            if (controller.state.value == DiscoverState.loading &&
                (DateTime.now().millisecond % 7 == 0)) {
              DebugLogger.info(
                '🧭 DiscoverView: state=${controller.state.value}, deck=${controller.deck.length}, ps.loading=${ps.isLoading}, ps.refreshing=${ps.isRefreshing}, ps.props=${ps.properties.length}',
              );
            }
          } catch (_) {}
        }();
        final isRefreshing = pageStateService.discoverState.value.isRefreshing;

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
              child: Builder(
                builder: (context) {
                  // Show different states based on controller state
                  switch (controller.state.value) {
                    case DiscoverState.loading:
                      return _buildLoadingState();

                    case DiscoverState.error:
                      return _buildErrorState();

                    case DiscoverState.empty:
                      return _buildEmptyState(context);

                    case DiscoverState.loaded:
                    case DiscoverState.prefetching:
                      return _buildSwipeInterface(context);

                    default:
                      return _buildLoadingState();
                  }
                },
              ),
            ),
          ],
        );
      }),
    );
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryYellow,
                      ),
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
        Expanded(child: LoadingStates.swipeCardSkeleton()),
      ],
    );
  }

  Widget _buildErrorState() {
    return Obx(() {
      final errorMessage = controller.error.value;
      if (errorMessage == null) return const SizedBox();

      // Try to map the error for better user experience
      try {
        // Don't wrap in Exception() - pass the original error message directly
        final exception = ErrorMapper.mapApiError(errorMessage);
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
    return ErrorStates.swipeDeckEmpty(
      onRefresh: controller.refreshDeck,
      onChangeFilters: () => showPropertyFilterBottomSheet(
        Get.context ?? context,
        pageType: 'discover',
      ),
    );
  }

  Widget _buildSwipeInterface(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(
              () => PropertySwipeStack(
                properties: controller.deck
                    .take(3)
                    .toList(), // Show max 3 cards in stack
                onSwipeLeft: controller.swipeLeft,
                onSwipeRight: controller.swipeRight,
                onSwipeUp: (property) =>
                    controller.viewPropertyDetails(property),
                showSwipeInstructions:
                    controller.totalSwipesInSession.value < 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
