import 'package:flutter/material.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class LoadingStates {
  // Skeleton loaders for different content types
  static Widget propertyCardSkeleton() {
    final baseColor = AppColors.textSecondary.withValues(alpha: 0.2);
    final highlightColor = AppColors.textSecondary.withValues(alpha: 0.05);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image skeleton
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle skeleton
                  Container(
                    height: 16,
                    width: 200,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Price skeleton
                      Container(
                        height: 18,
                        width: 100,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      // Details skeleton
                      Container(
                        height: 16,
                        width: 80,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget propertyListSkeleton({int itemCount = 5}) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => propertyCardSkeleton(),
    );
  }

  static Widget propertyGridSkeleton({int itemCount = 6}) {
    final baseColor = AppColors.textSecondary.withValues(alpha: 0.2);
    final highlightColor = AppColors.textSecondary.withValues(alpha: 0.05);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder:
          (context, index) => Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 12,
                            width: 100,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 14,
                            width: 80,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  static Widget swipeCardSkeleton() {
    final baseColor = AppColors.textSecondary.withValues(alpha: 0.2);
    final highlightColor = AppColors.textSecondary.withValues(alpha: 0.05);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 24,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 200,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          height: 20,
                          width: 120,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 18,
                          width: 100,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget mapLoadingOverlay(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.surface.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading properties...',
              style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  static Widget progressiveLoadingIndicator({
    required int current,
    required int total,
    String? message,
    BuildContext? context,
  }) {
    final theme = context != null ? Theme.of(context) : null;
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.inputBackground,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme?.colorScheme.primary ?? AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message ?? 'Loading page $current of $total...',
            style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // Pull-to-refresh indicator
  static Widget pullToRefreshIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
    );
  }

  // Load more indicator for infinite scroll
  static Widget loadMoreIndicator({BuildContext? context}) {
    final theme = context != null ? Theme.of(context) : null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            theme?.colorScheme.primary ?? AppColors.primaryYellow,
          ),
        ),
      ),
    );
  }

  // Inline loading for buttons
  static Widget inlineLoading({double size = 16.0, Color? color, BuildContext? context}) {
    final theme = context != null ? Theme.of(context) : null;
    final indicatorColor = color ?? theme?.colorScheme.primary ?? AppColors.primaryYellow;

    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      ),
    );
  }

  // Shimmer text placeholder
  static Widget textSkeleton({
    required double width,
    double height = 16,
    BorderRadius? borderRadius,
  }) {
    final baseColor = AppColors.textSecondary.withValues(alpha: 0.2);
    final highlightColor = AppColors.textSecondary.withValues(alpha: 0.05);
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }

  // Full screen loading overlay
  static Widget fullScreenLoading({String? message, BuildContext? context}) {
    final theme = context != null ? Theme.of(context) : null;

    return Container(
      color: AppColors.surface.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme?.colorScheme.primary ?? AppColors.primaryYellow,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Search loading state
  static Widget searchLoading({BuildContext? context}) {
    final theme = context != null ? Theme.of(context) : null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme?.colorScheme.primary ?? AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching properties...',
            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // Location loading state
  static Widget locationLoading({BuildContext? context}) {
    final theme = context != null ? Theme.of(context) : null;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme?.colorScheme.primary ?? AppColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Getting your location...',
            style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
