import 'package:flutter/material.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';

class VisitSkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const VisitSkeletonLoader({super.key, this.width, this.height, this.borderRadius, this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Shimmer.fromColors(
      baseColor: AppColors.inputBackground,
      highlightColor: AppColors.surface,
      child:
          child ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
          ),
    );
  }
}

class VisitCardSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const VisitCardSkeleton({super.key, this.width, this.height, this.padding, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VisitSkeletonLoader(width: 60, height: 60, borderRadius: BorderRadius.circular(8)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VisitSkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    VisitSkeletonLoader(
                      width: 200,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    VisitSkeletonLoader(
                      width: 150,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              VisitSkeletonLoader(width: 80, height: 24, borderRadius: BorderRadius.circular(12)),
            ],
          ),
          const SizedBox(height: 12),
          VisitSkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          VisitSkeletonLoader(width: 250, height: 14, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}

class RelationshipManagerSkeleton extends StatelessWidget {
  const RelationshipManagerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryYellow.withValues(alpha: 0.1),
            AppColors.primaryYellow.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          VisitSkeletonLoader(width: 44, height: 44, borderRadius: BorderRadius.circular(22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    VisitSkeletonLoader(
                      width: 16,
                      height: 16,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 6),
                    VisitSkeletonLoader(
                      width: 140,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                VisitSkeletonLoader(width: 160, height: 16, borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 4),
                VisitSkeletonLoader(width: 120, height: 12, borderRadius: BorderRadius.circular(4)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          VisitSkeletonLoader(width: 36, height: 36, borderRadius: BorderRadius.circular(18)),
          const SizedBox(width: 8),
          VisitSkeletonLoader(width: 36, height: 36, borderRadius: BorderRadius.circular(18)),
        ],
      ),
    );
  }
}
