import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/utils/app_colors.dart';

class VisitSkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const VisitSkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
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

  const VisitCardSkeleton({
    super.key,
    this.width,
    this.height,
    this.padding,
    this.margin,
  });

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
              const VisitSkeletonLoader(
                width: 60,
                height: 60,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VisitSkeletonLoader(
                      width: double.infinity,
                      height: 16,
                    ),
                    const SizedBox(height: 8),
                    const VisitSkeletonLoader(
                      width: 200,
                      height: 14,
                    ),
                    const SizedBox(height: 8),
                    const VisitSkeletonLoader(
                      width: 150,
                      height: 14,
                    ),
                  ],
                ),
              ),
              const VisitSkeletonLoader(
                width: 80,
                height: 24,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const VisitSkeletonLoader(
            width: double.infinity,
            height: 14,
          ),
          const SizedBox(height: 8),
          const VisitSkeletonLoader(
            width: 250,
            height: 14,
          ),
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
        border: Border.all(
          color: AppColors.primaryYellow.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const VisitSkeletonLoader(
            width: 44,
            height: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const VisitSkeletonLoader(
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 6),
                    const VisitSkeletonLoader(
                      width: 140,
                      height: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const VisitSkeletonLoader(
                  width: 160,
                  height: 16,
                ),
                const SizedBox(height: 4),
                const VisitSkeletonLoader(
                  width: 120,
                  height: 12,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const VisitSkeletonLoader(
            width: 36,
            height: 36,
          ),
          const SizedBox(width: 8),
          const VisitSkeletonLoader(
            width: 36,
            height: 36,
          ),
        ],
      ),
    );
  }
}
