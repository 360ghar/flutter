import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/utils/share_utils.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';

/// The hero image section of a swipe card, including the property image,
/// gradient overlays, share button, type badge, price/title/specs overlay,
/// and the "scroll for more" indicator.
class SwipeCardHeroSection extends StatelessWidget {
  final PropertyModel property;

  const SwipeCardHeroSection({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = math.min(screenHeight * 0.78, 680.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        children: [
          // Main property image
          Positioned.fill(
            child: RobustNetworkImage(
              imageUrl: property.mainImage,
              fit: BoxFit.cover,
              placeholder: Container(
                color: AppDesign.inputBackground,
                child: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
              ),
              errorWidget: Container(
                color: AppDesign.surface,
                child: Icon(Icons.error, color: colorScheme.error),
              ),
            ),
          ),

          // Gradient overlay for text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppDesign.transparent, AppDesign.shadowColor.withValues(alpha: 0.85)],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ),

          // Share button
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => ShareUtils.shareProperty(property, context: context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppDesign.shadowColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.share, color: colorScheme.onPrimary, size: 20),
              ),
            ),
          ),

          // Property type badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppDesign.shadowColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.apartment, color: AppDesign.darkTextPrimary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    property.propertyTypeString,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppDesign.darkTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Property details overlay at bottom
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomOverlay(context)),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppDesign.shadowColor.withValues(alpha: 0.0),
            AppDesign.shadowColor.withValues(alpha: 0.65),
            AppDesign.shadowColor.withValues(alpha: 0.88),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price with purpose-based display
          _buildPriceRow(context),
          const SizedBox(height: 4),

          // Title
          Text(
            property.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppDesign.darkTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppDesign.darkTextPrimary.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.shortAddressDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppDesign.darkTextPrimary.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Property specs
          _buildSpecsWrap(context),
          const SizedBox(height: 10),

          // Lightweight metrics
          _buildMetricsRow(context),
          const SizedBox(height: 16),

          // Scroll indicator
          _buildScrollIndicator(context),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppDesign.darkTextPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(text: property.formattedPrice),
              if (property.purpose == PropertyPurpose.rent)
                TextSpan(
                  text: 'per_month_short'.tr,
                  style: TextStyle(
                    color: AppDesign.darkTextPrimary.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (property.purpose == PropertyPurpose.shortStay)
                TextSpan(
                  text: 'per_day_short'.tr,
                  style: TextStyle(
                    color: AppDesign.darkTextPrimary.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            property.purposeString,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsWrap(BuildContext context) {
    final specs = <Widget>[];

    if (property.bedrooms != null) {
      specs.add(
        _buildSpecPill(context, icon: Icons.bed_outlined, label: '${property.bedrooms} BHK'),
      );
    }
    if (property.bathrooms != null) {
      specs.add(
        _buildSpecPill(context, icon: Icons.bathtub_outlined, label: '${property.bathrooms} Bath'),
      );
    }
    if (property.areaText.isNotEmpty) {
      specs.add(_buildSpecPill(context, icon: Icons.square_foot, label: property.areaText));
    }
    if (property.floorText.isNotEmpty) {
      specs.add(_buildSpecPill(context, icon: Icons.layers_outlined, label: property.floorText));
    }
    if (property.pricePerSqft != null) {
      specs.add(
        _buildSpecPill(
          context,
          icon: Icons.trending_up,
          label: 'price_per_sq_ft_amount'.trParams({
            'price': property.pricePerSqft!.toStringAsFixed(0),
          }),
        ),
      );
    }
    if (property.parkingSpaces != null) {
      specs.add(
        _buildSpecPill(
          context,
          icon: Icons.local_parking,
          label: 'parking_spaces'.trParams({'count': '${property.parkingSpaces}'}),
        ),
      );
    }
    if (specs.isEmpty) {
      specs.add(_buildSpecPill(context, icon: Icons.info_outline, label: 'property_label'.tr));
    }

    return Wrap(spacing: 8, runSpacing: 6, children: specs);
  }

  Widget _buildMetricsRow(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Row(
          children: [
            Icon(
              Icons.visibility,
              color: AppDesign.darkTextPrimary.withValues(alpha: 0.7),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '${property.viewCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppDesign.darkTextPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            Icon(Icons.favorite, color: AppDesign.darkTextPrimary.withValues(alpha: 0.7), size: 14),
            const SizedBox(width: 4),
            Text(
              '${property.likeCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppDesign.darkTextPrimary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScrollIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface, size: 16),
            const SizedBox(width: 4),
            Text(
              'scroll_for_more_details'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecPill(BuildContext context, {required IconData icon, required String label}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppDesign.darkTextPrimary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppDesign.darkTextPrimary.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppDesign.darkTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
