import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';

class ExplorePropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;

  const ExplorePropertyCard({
    super.key,
    required this.property,
    required this.isFavourite,
    required this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      color: AppDesign.propertyCardBackground,
      shadowColor: AppDesign.shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.card)),
      child: InkWell(
        onTap: () {
          Get.toNamed(AppRoutes.propertyDetails, arguments: property);
        },
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RobustNetworkImage(
                      imageUrl: property.mainImage,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      memCacheWidth: 200,
                      memCacheHeight: 120,
                      placeholder: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppDesign.inputBackground,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppDesign.primaryYellow,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'loading'.tr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppDesign.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesign.primaryYellow,
                        borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                        boxShadow: [
                          BoxShadow(
                            color: AppDesign.shadowColor,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        property.propertyTypeString.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppDesign.shadowColor.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          color: isFavourite ? AppDesign.favoriteActive : colorScheme.onPrimary,
                          size: 20,
                        ),
                        onPressed: onFavouriteToggle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppDesign.propertyCardText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          property.formattedPrice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppDesign.propertyCardPrice,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      property.shortAddressDisplay,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppDesign.propertyCardSubtext,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (property.bedroomBathroomText.isNotEmpty) ...[
                          Icon(Icons.bed_outlined, size: 14, color: AppDesign.propertyFeatureText),
                          const SizedBox(width: 4),
                          Text(
                            property.bedroomBathroomText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppDesign.propertyFeatureText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (property.areaText.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.square_foot, size: 14, color: AppDesign.propertyFeatureText),
                          const SizedBox(width: 4),
                          Text(
                            property.areaText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppDesign.propertyFeatureText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
}
