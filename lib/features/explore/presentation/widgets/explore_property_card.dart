import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
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
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppDesignTokens.darkSurfaceAlt : AppDesignTokens.warmCream;
    final cardBorder = isDark ? AppDesignTokens.darkBorder : AppDesignTokens.neutral300;
    final textPrimary = isDark ? AppDesignTokens.darkTextPrimary : AppDesignTokens.neutral900;
    final textSecondary = isDark ? AppDesignTokens.darkTextSecondary : AppDesignTokens.neutral500;
    final iconColor = isDark ? AppDesignTokens.darkTextTertiary : AppDesignTokens.neutral500;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Material(
        color: AppDesign.transparent,
        borderRadius: BorderRadius.circular(AppBorderRadius.card),
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
                height: 112,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: RobustNetworkImage(
                        imageUrl: property.mainImage,
                        height: 112,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        memCacheWidth: 200,
                        memCacheHeight: 112,
                        placeholder: Container(
                          height: 112,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppDesign.inputBackground,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppDesignTokens.brandGold,
                                strokeWidth: 1.5,
                              ),
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
                          color: isDark
                              ? AppDesignTokens.darkSurfaceAlt
                              : AppDesignTokens.warmCream,
                          borderRadius: BorderRadius.circular(AppBorderRadius.chip),
                        ),
                        child: Text(
                          property.propertyTypeTranslationKey.tr.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: 0.5,
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
                            color: isFavourite
                                ? AppDesign.favoriteActive
                                : AppDesignTokens.neutralWhite,
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            property.formattedPrice,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        property.shortAddressDisplay,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (property.bedroomBathroomText.isNotEmpty) ...[
                            Icon(Icons.bed_outlined, size: 14, color: iconColor),
                            const SizedBox(width: 4),
                            Text(
                              property.bedroomBathroomText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
                              ),
                            ),
                          ],
                          if (property.areaText.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.square_foot, size: 14, color: iconColor),
                            const SizedBox(width: 4),
                            Text(
                              property.areaText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: textSecondary,
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
      ),
    );
  }
}
