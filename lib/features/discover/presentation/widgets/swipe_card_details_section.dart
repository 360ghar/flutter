import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/utils/app_toast.dart';
import 'package:ghar360/features/discover/presentation/widgets/embedded_swipe_360_tour.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// The scrollable details section below the hero image in a swipe card.
/// Contains description, highlights, amenities, 360° tour, property
/// details table, location map, and swipe instructions.
class SwipeCardDetailsSection extends StatelessWidget {
  final PropertyModel property;
  final bool showSwipeInstructions;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  const SwipeCardDetailsSection({
    super.key,
    required this.property,
    this.showSwipeInstructions = false,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            _buildDescription(context),
            const SizedBox(height: AppSpacing.screenPadding),

            // Highlights
            if ((property.features?.isNotEmpty ?? false)) ..._buildHighlights(context),

            // Amenities
            if (property.hasAmenities) ..._buildAmenities(context),

            // 360° Tour
            if (property.virtualTourUrl != null && property.virtualTourUrl!.isNotEmpty)
              ..._buildVirtualTour(context),

            // Property Details table
            _buildPropertyDetailsCard(context),
            const SizedBox(height: 20),

            // Location map
            if (property.hasLocation) ..._buildLocationSection(context),

            // Swipe Instructions
            ..._buildSwipeInstructions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'description'.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          property.description?.isNotEmpty == true
              ? property.description!
              : 'no_description_available'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHighlights(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return [
      Text(
        'highlights'.tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (property.features ?? [])
            .take(4)
            .map(
              (t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppDesign.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppDesign.accentOrange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  t,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppDesign.accentOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildAmenities(BuildContext context) {
    final theme = Theme.of(context);

    return [
      Text(
        'amenities'.tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: property.amenitiesList
            .take(6)
            .map(
              (amenity) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppDesign.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppDesign.accentBlue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  amenity,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppDesign.accentBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      if (property.amenitiesList.length > 6)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '+${property.amenitiesList.length - 6} more amenities',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppDesign.accentBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildVirtualTour(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.threesixty, size: 20, color: AppDesign.primaryYellow),
          const SizedBox(width: 8),
          Text(
            'virtual_tour_title'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              Get.toNamed(AppRoutes.tour, arguments: property.virtualTourUrl);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppDesign.primaryYellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppDesign.primaryYellow.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fullscreen, size: 14, color: AppDesign.primaryYellow),
                  const SizedBox(width: 4),
                  Text(
                    'fullscreen_mode'.tr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                      color: AppDesign.primaryYellow,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      // 360° Tour with interaction signaling
      Listener(
        onPointerDown: (_) => onInteractionStart?.call(),
        onPointerUp: (_) => onInteractionEnd?.call(),
        onPointerCancel: (_) => onInteractionEnd?.call(),
        child: Container(
          height: 500,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppDesign.border),
            boxShadow: [
              BoxShadow(
                color: AppDesign.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: EmbeddedSwipe360Tour(tourUrl: property.virtualTourUrl!),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildPropertyDetailsCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'property_details'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(context, 'property_type'.tr, property.propertyTypeString),
          _buildDetailRow(context, 'purpose'.tr, property.purposeString),
          if (property.bedrooms != null)
            _buildDetailRow(context, 'bedrooms'.tr, '${property.bedrooms}'),
          if (property.bathrooms != null)
            _buildDetailRow(context, 'bathrooms'.tr, '${property.bathrooms}'),
          if (property.areaSqft != null) _buildDetailRow(context, 'area'.tr, property.areaText),
          if (property.floorText.isNotEmpty)
            _buildDetailRow(context, 'floor'.tr, property.floorText),
          if (property.ageText.isNotEmpty) _buildDetailRow(context, 'age'.tr, property.ageText),
          if (property.parkingSpaces != null)
            _buildDetailRow(
              context,
              'parking'.tr,
              'parking_spaces'.trParams({'count': '${property.parkingSpaces}'}),
            ),
          if (property.balconies != null)
            _buildDetailRow(context, 'balconies'.tr, '${property.balconies}'),
          if (property.distanceKm != null)
            _buildDetailRow(context, 'distance'.tr, property.distanceText),
          _buildDetailRow(context, 'location'.tr, property.shortAddressDisplay),
          if (property.builderName?.isNotEmpty == true)
            _buildDetailRow(context, 'builder'.tr, property.builderName!),
        ],
      ),
    );
  }

  List<Widget> _buildLocationSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return [
      const SizedBox(height: 12),
      Text(
        'location'.tr,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        height: 180,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesign.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(property.latitude!, property.longitude!),
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.ghar360.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(property.latitude!, property.longitude!),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, size: 36, color: AppDesign.primaryYellow),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _openGoogleMaps(property.latitude!, property.longitude!, property.title),
          icon: const Icon(Icons.directions),
          label: Text('get_directions'.tr),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppDesign.primaryYellow)),
        ),
      ),
      const SizedBox(height: 8),
    ];
  }

  List<Widget> _buildSwipeInstructions(BuildContext context) {
    if (!showSwipeInstructions) return const [];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppDesign.primaryYellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppDesign.primaryYellow.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.swipe, color: AppDesign.primaryYellow, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'swipe_instructions'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openGoogleMaps(double latitude, double longitude, String label) async {
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1'
    '&destination=$latitude,$longitude&travelmode=driving',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    AppToast.warning('unable_to_open_maps'.tr, 'check_device_settings'.tr);
  }
}
