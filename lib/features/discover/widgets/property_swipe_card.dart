import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/share_utils.dart';
import 'package:ghar360/core/utils/webview_helper.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PropertySwipeCard extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback? onTap;
  final bool showSwipeInstructions;
  final VoidCallback? onInteractionStart; // e.g., 360 tour grab
  final VoidCallback? onInteractionEnd;

  const PropertySwipeCard({
    super.key,
    required this.property,
    this.onTap,
    this.showSwipeInstructions = false,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  @override
  State<PropertySwipeCard> createState() => _PropertySwipeCardState();
}

class _PropertySwipeCardState extends State<PropertySwipeCard> {
  bool _interactiveChildActive = false; // disables vertical scroll when true

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: colorScheme.surface,
          child: SingleChildScrollView(
            physics: _interactiveChildActive
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image with overlay info (Use available height properly)
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use available parent height instead of full screen height
                    // This ensures we don't overlap with app bar or other UI elements
                    final availableHeight = constraints.maxHeight > 0
                        ? constraints.maxHeight
                        : MediaQuery.of(context).size.height - 200; // Fallback with safe margins

                    return SizedBox(
                      height: math.min(availableHeight * 0.8, 600), // Cap at reasonable max height
                      child: Stack(
                        children: [
                          // Main property image
                          Positioned.fill(
                            child: RobustNetworkImage(
                              imageUrl: widget.property.mainImage,
                              fit: BoxFit.cover,
                              placeholder: Container(
                                color: AppColors.inputBackground,
                                child: Center(
                                  child: CircularProgressIndicator(color: colorScheme.primary),
                                ),
                              ),
                              errorWidget: Container(
                                color: AppColors.surface,
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
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Share button
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () =>
                                  ShareUtils.shareProperty(widget.property, context: context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
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
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.apartment, color: Colors.white, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.property.propertyTypeString,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Property details overlay at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Price with purpose-based display
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          children: [
                                            TextSpan(text: widget.property.formattedPrice),
                                            if (widget.property.purpose == PropertyPurpose.rent)
                                              TextSpan(
                                                text: ' /mo',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            if (widget.property.purpose ==
                                                PropertyPurpose.shortStay)
                                              TextSpan(
                                                text: ' /day',
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          widget.property.purposeString,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Title
                                  Text(
                                    widget.property.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Location
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: Colors.white.withValues(alpha: 0.7),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.property.shortAddressDisplay,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.7),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Property specs with enhanced info
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      // Basic specs
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          widget.property.bedroomBathroomText.isNotEmpty
                                              ? widget.property.bedroomBathroomText
                                              : 'Property',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),

                                      // Area if available
                                      if (widget.property.areaText.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            widget.property.areaText,
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),

                                      // Floor info if available
                                      if (widget.property.floorText.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            widget.property.floorText,
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      // Price per sqft if available
                                      if (widget.property.pricePerSqft != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '₹${widget.property.pricePerSqft!.toStringAsFixed(0)}/sqft',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      // Parking if available
                                      if (widget.property.parkingSpaces != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${widget.property.parkingSpaces} Parking',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Lightweight metrics
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.visibility,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.property.viewCount}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.favorite,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.property.likeCount}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: Colors.white.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Scroll indicator
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: colorScheme.onSurface,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Scroll for more details',
                                            style: theme.textTheme.labelMedium?.copyWith(
                                              color: colorScheme.onSurface,
                                              fontWeight: FontWeight.w500,
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
                        ],
                      ),
                    );
                  },
                ),

                // Additional Details Section (Scrollable content)
                Container(
                  color: colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text(
                          'Description',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.property.description?.isNotEmpty == true
                              ? widget.property.description!
                              : 'Beautiful ${widget.property.propertyTypeString} in ${widget.property.city ?? "prime location"}. ${widget.property.areaSqft != null ? "Spacious ${widget.property.areaSqft!.toInt()} sq ft area with modern amenities." : "Perfect for your needs."}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Highlights (features/tags)
                        if ((widget.property.features?.isNotEmpty ?? false)) ...[
                          Text(
                            'Highlights',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (widget.property.features ?? [])
                                .take(4)
                                .map(
                                  (t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentOrange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.accentOrange.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      t,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: AppColors.accentOrange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Amenities section
                        if (widget.property.hasAmenities) ...[
                          Text(
                            'Amenities',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.property.amenitiesList
                                .take(6)
                                .map(
                                  (amenity) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.accentBlue.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      amenity,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: AppColors.accentBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          if (widget.property.amenitiesList.length > 6)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+${widget.property.amenitiesList.length - 6} more amenities',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.accentBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                        ],

                        // Note: Additional images not available in PropertyCardModel

                        // 360° Tour Embedded Section
                        if (widget.property.virtualTourUrl != null &&
                            widget.property.virtualTourUrl!.isNotEmpty) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.threesixty,
                                size: 20,
                                color: AppColors.primaryYellow,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '360° Virtual Tour',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  Get.toNamed('/tour', arguments: widget.property.virtualTourUrl);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryYellow.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primaryYellow.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.fullscreen,
                                        size: 14,
                                        color: AppColors.primaryYellow,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Fullscreen',
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontSize: 12,
                                          color: AppColors.primaryYellow,
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
                          // 360° Tour with interaction signaling to block parent gestures/scroll
                          Listener(
                            onPointerDown: (_) {
                              setState(() => _interactiveChildActive = true);
                              widget.onInteractionStart?.call();
                            },
                            onPointerUp: (_) {
                              setState(() => _interactiveChildActive = false);
                              widget.onInteractionEnd?.call();
                            },
                            onPointerCancel: (_) {
                              setState(() => _interactiveChildActive = false);
                              widget.onInteractionEnd?.call();
                            },
                            child: Container(
                              height: 500,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowColor,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _EmbeddedSwipe360Tour(
                                  tourUrl: widget.property.virtualTourUrl!,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Property Details
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Property Details',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                context,
                                'Property Type',
                                widget.property.propertyTypeString,
                              ),
                              _buildDetailRow(context, 'Purpose', widget.property.purposeString),
                              if (widget.property.bedrooms != null)
                                _buildDetailRow(context, 'Bedrooms', '${widget.property.bedrooms}'),
                              if (widget.property.bathrooms != null)
                                _buildDetailRow(
                                  context,
                                  'Bathrooms',
                                  '${widget.property.bathrooms}',
                                ),
                              if (widget.property.areaSqft != null)
                                _buildDetailRow(context, 'Area', widget.property.areaText),
                              if (widget.property.floorText.isNotEmpty)
                                _buildDetailRow(context, 'Floor', widget.property.floorText),
                              if (widget.property.ageText.isNotEmpty)
                                _buildDetailRow(context, 'Age', widget.property.ageText),
                              if (widget.property.parkingSpaces != null)
                                _buildDetailRow(
                                  context,
                                  'Parking',
                                  '${widget.property.parkingSpaces} spaces',
                                ),
                              if (widget.property.balconies != null)
                                _buildDetailRow(
                                  context,
                                  'Balconies',
                                  '${widget.property.balconies}',
                                ),
                              if (widget.property.distanceKm != null)
                                _buildDetailRow(context, 'Distance', widget.property.distanceText),
                              _buildDetailRow(
                                context,
                                'Location',
                                widget.property.shortAddressDisplay,
                              ),
                              if (widget.property.builderName?.isNotEmpty == true)
                                _buildDetailRow(context, 'Builder', widget.property.builderName!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Location map and directions at the very end
                        if (widget.property.hasLocation) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Location',
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
                              border: Border.all(color: AppColors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(
                                  widget.property.latitude!,
                                  widget.property.longitude!,
                                ),
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
                                      point: LatLng(
                                        widget.property.latitude!,
                                        widget.property.longitude!,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 36,
                                        color: AppColors.primaryYellow,
                                      ),
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
                              onPressed: () => _openGoogleMaps(
                                widget.property.latitude!,
                                widget.property.longitude!,
                                widget.property.title,
                              ),
                              icon: const Icon(Icons.directions),
                              label: const Text('Get directions'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primaryYellow),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Swipe Instructions (conditional)
                        ..._buildSwipeInstructions(context, widget.showSwipeInstructions),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSwipeInstructions(BuildContext context, bool show) {
    if (!show) return const [];
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryYellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryYellow.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.swipe, color: AppColors.primaryYellow, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Swipe right to like • Swipe left to pass',
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

// Opens Google Maps with directions to the given coordinates
Future<void> _openGoogleMaps(double latitude, double longitude, String label) async {
  final url = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving',
  );
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    Get.snackbar(
      'Unable to open maps',
      'Please check your device settings',
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.snackbarBackground,
      colorText: AppColors.snackbarText,
    );
  }
}

class PropertySwipeStack extends StatefulWidget {
  final List<PropertyModel> properties;
  final Function(PropertyModel) onSwipeLeft;
  final Function(PropertyModel) onSwipeRight;
  final Function(PropertyModel) onSwipeUp;
  final bool showSwipeInstructions;

  const PropertySwipeStack({
    super.key,
    required this.properties,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    this.showSwipeInstructions = false,
  });

  @override
  State<PropertySwipeStack> createState() => _PropertySwipeStackState();
}

class _PropertySwipeStackState extends State<PropertySwipeStack> with TickerProviderStateMixin {
  late List<PropertyModel> _properties;
  late AnimationController _swipeAnimationController;
  late AnimationController _sparklesAnimationController;
  late Animation<double> _swipeAnimation;
  late Animation<double> _sparklesAnimation;

  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;
  double _rotation = 0;
  bool _showSparkles = false;
  bool _isSwipingRight = false;
  bool _blockGestures = false; // block horizontal drag when interacting with 360

  @override
  void initState() {
    super.initState();
    _properties = List.from(widget.properties);
    DebugLogger.debug('PropertySwipeStack initialized with ${_properties.length} properties');

    // Animation for the swipe out effect
    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _swipeAnimation = CurvedAnimation(parent: _swipeAnimationController, curve: Curves.easeInOut);

    // Animation for sparkles effect
    _sparklesAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sparklesAnimation = CurvedAnimation(
      parent: _sparklesAnimationController,
      curve: Curves.easeOut,
    );

    _swipeAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_properties.isNotEmpty) {
          _properties.removeAt(0);
        }
        _swipeAnimationController.reset();
        _sparklesAnimationController.reset();
        _dragPosition = Offset.zero;
        _rotation = 0;
        _showSparkles = false;
        _isSwipingRight = false;
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(PropertySwipeStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update properties when widget properties change
    if (widget.properties != oldWidget.properties) {
      _properties = List.from(widget.properties);
      DebugLogger.debug('PropertySwipeStack updated with ${_properties.length} properties');
      setState(() {});
    }
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _sparklesAnimationController.dispose();
    super.dispose();
  }

  double _calculateRotation(Offset dragPosition, Size screenSize) {
    // Calculate rotation based on horizontal drag
    // The card rotates from the bottom center like a hinge
    final horizontalRatio = dragPosition.dx / (screenSize.width * 0.5);
    // Limit rotation to a maximum of 45 degrees (π/4 radians)
    final maxRotation = 0.785398; // 45 degrees in radians
    return horizontalRatio * maxRotation * 0.7; // Reduce sensitivity
  }

  void _handlePanEnd(DragEndDetails details, Size screenSize) {
    setState(() {
      _isDragging = false;
    });

    final dragDistance = _dragPosition.dx;
    final dragThreshold = screenSize.width * 0.25;
    final rotationThreshold = 0.3; // About 17 degrees

    // Check if we should trigger a swipe
    if (dragDistance.abs() > dragThreshold || _rotation.abs() > rotationThreshold) {
      if (dragDistance > 0 || _rotation > 0) {
        // Swipe right - like with sparkles
        _isSwipingRight = true;
        _showSparkles = true;
        _sparklesAnimationController.forward();
        widget.onSwipeRight(_properties[0]);
      } else {
        // Swipe left - pass
        widget.onSwipeLeft(_properties[0]);
      }
      _swipeAnimationController.forward();
    } else {
      // Snap back with smooth animation
      _snapBack();
    }
  }

  void _snapBack() {
    final snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final positionTween = Tween<Offset>(begin: _dragPosition, end: Offset.zero);

    final rotationTween = Tween<double>(begin: _rotation, end: 0);

    final snapAnimation = CurvedAnimation(parent: snapController, curve: Curves.elasticOut);

    snapController.addListener(() {
      setState(() {
        _dragPosition = positionTween.evaluate(snapAnimation);
        _rotation = rotationTween.evaluate(snapAnimation);
      });
    });

    snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        snapController.dispose();
      }
    });

    snapController.forward();
  }

  @override
  Widget build(BuildContext context) {
    // Avoid excessively verbose logs on every build to keep UI smooth

    if (_properties.isEmpty) {
      DebugLogger.warning('PropertySwipeStack: No properties to display');
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No more properties to show',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new listings!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    DebugLogger.debug('PropertySwipeStack: Rendering ${_properties.length} properties');

    return GestureDetector(
      onHorizontalDragStart: (details) {
        if (_blockGestures) return;
        setState(() {
          _isDragging = true;
        });
      },
      onHorizontalDragUpdate: (details) {
        if (_blockGestures) return;
        setState(() {
          final dx = details.primaryDelta ?? 0;
          _dragPosition = Offset(_dragPosition.dx + dx, 0);
          _rotation = _calculateRotation(_dragPosition, screenSize);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_blockGestures) return;
        _handlePanEnd(details, screenSize);
      },
      child: Stack(
        clipBehavior: Clip.hardEdge, // Prevent cards from rendering outside bounds
        children: [
          // Background cards with subtle scaling
          if (_properties.length > 1)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.95,
                child: Opacity(
                  opacity: 0.8,
                  child: PropertySwipeCard(
                    property: _properties[1],
                    onInteractionStart: () => setState(() => _blockGestures = true),
                    onInteractionEnd: () => setState(() => _blockGestures = false),
                  ),
                ),
              ),
            ),
          if (_properties.length > 2)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.9,
                child: Opacity(
                  opacity: 0.6,
                  child: PropertySwipeCard(
                    property: _properties[2],
                    onInteractionStart: () => setState(() => _blockGestures = true),
                    onInteractionEnd: () => setState(() => _blockGestures = false),
                  ),
                ),
              ),
            ),

          // Top card with realistic rotation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _swipeAnimation,
              builder: (context, child) {
                final swipeOffset = _isDragging
                    ? Offset(_dragPosition.dx, 0)
                    : Offset(_dragPosition.dx * (1 + _swipeAnimation.value * 2), 0);

                final swipeRotation = _isDragging
                    ? _rotation
                    : _rotation * (1 + _swipeAnimation.value * 2);

                return Transform.translate(
                  offset: swipeOffset,
                  child: Transform(
                    alignment: Alignment.bottomCenter, // Rotate from bottom center like a hinge
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) // Add perspective
                      ..rotateZ(swipeRotation),
                    child: Opacity(
                      opacity: _swipeAnimationController.isAnimating
                          ? (1 - _swipeAnimation.value)
                          : 1.0,
                      child: PropertySwipeCard(
                        property: _properties[0],
                        showSwipeInstructions: widget.showSwipeInstructions,
                        onInteractionStart: () => setState(() => _blockGestures = true),
                        onInteractionEnd: () => setState(() => _blockGestures = false),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sparkles animation for right swipe
          if (_showSparkles && _isSwipingRight)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sparklesAnimation,
                builder: (context, child) {
                  return IgnorePointer(child: SparklesWidget(animation: _sparklesAnimation));
                },
              ),
            ),
        ],
      ),
    );
  }
}

// Sparkles widget for the enthusiasm animation
class SparklesWidget extends StatelessWidget {
  final Animation<double> animation;

  const SparklesWidget({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: SparklesPainter(animation.value), size: Size.infinite);
  }
}

class SparklesPainter extends CustomPainter {
  final double animationValue;

  SparklesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryYellow.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Create sparkles at various positions
    final sparklePositions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.8),
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.9, size.height * 0.4),
      Offset(size.width * 0.4, size.height * 0.2),
    ];

    for (int i = 0; i < sparklePositions.length; i++) {
      final position = sparklePositions[i];
      final delay = i * 0.1;
      final sparkleAnimation = ((animationValue - delay) / (1 - delay)).clamp(0.0, 1.0);

      if (sparkleAnimation > 0) {
        final sparkleSize = 8.0 * sparkleAnimation * (1 - sparkleAnimation * 0.5);
        final sparkleOpacity = (1 - sparkleAnimation).clamp(0.0, 1.0);

        paint.color = AppColors.primaryYellow.withValues(alpha: sparkleOpacity * 0.8);

        // Draw sparkle as a star shape
        _drawStar(canvas, paint, position, sparkleSize);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double size) {
    final path = ui.Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(SparklesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _EmbeddedSwipe360Tour extends StatefulWidget {
  final String tourUrl;

  const _EmbeddedSwipe360Tour({required this.tourUrl});

  @override
  State<_EmbeddedSwipe360Tour> createState() => _EmbeddedSwipe360TourState();
}

class _EmbeddedSwipe360TourState extends State<_EmbeddedSwipe360Tour> {
  WebViewController? controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    try {
      WebViewHelper.ensureInitialized();
      const consoleSilencer = '''
        if (window && window.console) {
          window.console.log = function() {};
          window.console.warn = function() {};
          window.console.error = function() {};
          window.console.info = function() {};
          window.console.debug = function() {};
        }
      ''';

      controller = WebViewController();
      controller!
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = true;
                });
              }
              controller!.runJavaScript(consoleSilencer);
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
              controller!.runJavaScript(consoleSilencer);
            },
            onWebResourceError: (WebResourceError error) {
              DebugLogger.warning('WebView error in 360° tour: ${error.description}');
              if (mounted) {
                setState(() {
                  isLoading = false;
                  hasError = true;
                });
              }
            },
          ),
        );

      final sanitizedUrl = widget.tourUrl;
      final htmlContent =
          '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { 
            margin: 0; 
            padding: 0; 
            background: #f0f0f0;
            overflow: hidden;
          }
          iframe { 
            width: 100vw; 
            height: 100vh; 
            border: none;
            display: block;
          }
        </style>
        <script type="text/javascript">
          $consoleSilencer
        </script>
      </head>
      <body>
        <iframe class="ku-embed" 
                frameborder="0" 
                allow="xr-spatial-tracking; gyroscope; accelerometer" 
                allowfullscreen 
                scrolling="no" 
                src="$sanitizedUrl">
        </iframe>
      </body>
      </html>
    ''';

      controller!.loadHtmlString(htmlContent);
    } catch (e, stackTrace) {
      DebugLogger.error('Error initializing WebView for 360° tour', e, stackTrace);
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  @override
  @override
  @override
  Widget build(BuildContext context) {
    if (hasError || controller == null) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public_off, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(
                '360° Tour Unavailable',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Virtual tour could not be loaded',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: controller!),
        if (isLoading)
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2),
                  const SizedBox(height: 8),
                  Text(
                    'Loading 360° Tour...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
