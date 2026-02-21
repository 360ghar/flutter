import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/utils/app_toast.dart';
import 'package:ghar360/core/utils/share_utils.dart';
import 'package:ghar360/core/widgets/common/loading_states.dart';
import 'package:ghar360/core/widgets/common/scroll_reveal_widget.dart';
import 'package:ghar360/core/widgets/property/property_details_features.dart';
import 'package:ghar360/features/likes/presentation/controllers/likes_controller.dart';
import 'package:ghar360/features/property_details/presentation/controllers/property_details_controller.dart';
import 'package:ghar360/features/property_details/presentation/widgets/property_details_image_gallery.dart';
import 'package:ghar360/features/property_details/presentation/widgets/property_details_info_sections.dart';
import 'package:ghar360/features/property_details/presentation/widgets/property_details_visit_dialog.dart';
import 'package:ghar360/features/property_details/presentation/widgets/property_media_hub.dart';
import 'package:ghar360/features/visits/presentation/controllers/visits_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailsView extends GetView<PropertyDetailsController> {
  const PropertyDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Widget child;
      final Key key;

      if (controller.isLoading.value) {
        key = const ValueKey('loading');
        child = const _PropertyLoadingScaffold();
      } else {
        final errorMessage = controller.errorMessage;
        if (errorMessage != null) {
          key = const ValueKey('error');
          child = _PropertyErrorScaffold(message: errorMessage);
        } else {
          final property = controller.property.value;
          if (property == null) {
            key = const ValueKey('not_found');
            child = _PropertyErrorScaffold(message: 'property_not_found'.tr);
          } else {
            key = const ValueKey('content');
            child = _PropertyContentView(property: property);
          }
        }
      }

      return AnimatedSwitcher(
        duration: AppDurations.contentFade,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: KeyedSubtree(key: key, child: child),
      );
    });
  }
}

/// Encapsulates property content rendering.
class _PropertyContentView extends StatelessWidget {
  const _PropertyContentView({required this.property});

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LikesController>();
    final visitsController = Get.find<VisitsController>();
    final PropertyModel safeProperty = property;

    return Semantics(
      label: 'qa.property_details.screen',
      identifier: 'qa.property_details.screen',
      child: Scaffold(
        key: const ValueKey('qa.property_details.screen'),
        backgroundColor: AppDesign.scaffoldBackground,
        body: CustomScrollView(
          slivers: [
            // App Bar with Image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppDesign.appBarBackground,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppDesign.shadowColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => Get.back(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppDesign.shadowColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Obx(
                    () => IconButton(
                      icon: Icon(
                        controller.isFavourite(safeProperty.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: controller.isFavourite(safeProperty.id)
                            ? AppDesign.favoriteActive
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        if (controller.isFavourite(safeProperty.id)) {
                          controller.removeFromFavourites(safeProperty.id);
                        } else {
                          controller.addToFavourites(safeProperty.id);
                        }
                      },
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppDesign.shadowColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () => ShareUtils.shareProperty(safeProperty, context: context),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: PropertyDetailsImageGallery(property: safeProperty),
              ),
            ),

            // Property Details Content
            SliverToBoxAdapter(
              child: Container(
                color: AppDesign.scaffoldBackground,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and Title
                      ScrollRevealWidget(
                        index: 0,
                        child: _buildPriceTitleCard(context, safeProperty),
                      ),
                      const SizedBox(height: 20),

                      if (safeProperty.hasAnyMedia) ...[
                        ScrollRevealWidget(
                          index: 1,
                          child: PropertyMediaBadges(property: safeProperty),
                        ),
                        const SizedBox(height: 12),
                        ScrollRevealWidget(
                          index: 2,
                          child: PropertyMediaHub(
                            property: safeProperty,
                            googleMapsApiKey: dotenv.env['GOOGLE_PLACES_API_KEY'],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Property Features
                      ScrollRevealWidget(
                        index: 3,
                        child: PropertyDetailsFeatures(property: safeProperty),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      ScrollRevealWidget(index: 4, child: _buildDescriptionSection(safeProperty)),
                      const SizedBox(height: 16),

                      // Highlights
                      if ((safeProperty.features?.isNotEmpty ?? false))
                        ..._buildHighlightsSection(safeProperty),
                      const SizedBox(height: 24),

                      // Property Information
                      ScrollRevealWidget(
                        index: 5,
                        child: PropertyDetailsInfoSection(property: safeProperty),
                      ),
                      const SizedBox(height: 24),

                      // Pricing Details
                      ScrollRevealWidget(
                        index: 6,
                        child: PropertyDetailsPricingSection(property: safeProperty),
                      ),
                      const SizedBox(height: 24),

                      // Builder Information
                      if (safeProperty.builderName?.isNotEmpty == true) ...[
                        ScrollRevealWidget(
                          index: 7,
                          child: PropertyDetailsContactSection(property: safeProperty),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Amenities
                      ScrollRevealWidget(index: 8, child: _buildAmenitiesSection(safeProperty)),
                      const SizedBox(height: 24),

                      // Location + Directions
                      if (safeProperty.hasLocation) ..._buildLocationSection(safeProperty),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Bottom Action Buttons
        bottomNavigationBar: _buildBottomBar(context, safeProperty, visitsController),
      ),
    );
  }

  Widget _buildPriceTitleCard(BuildContext context, PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDesign.getCardShadow(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: property.formattedPrice,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppDesign.propertyCardPrice,
                        ),
                      ),
                      if (property.purpose == PropertyPurpose.rent)
                        TextSpan(
                          text: 'per_month_short'.tr,
                          style: TextStyle(
                            color: AppDesign.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (property.purpose == PropertyPurpose.shortStay)
                        TextSpan(
                          text: 'per_day_short'.tr,
                          style: TextStyle(
                            color: AppDesign.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  property.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppDesign.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (property.pricePerSqft != null)
                      _chip('₹${property.pricePerSqft!.toStringAsFixed(0)}/sqft'),
                    if (property.securityDeposit != null)
                      _chip(
                        'security_deposit_amount'.trParams({
                          'amount': property.securityDeposit!.toStringAsFixed(0),
                        }),
                      ),
                    if (property.maintenanceCharges != null)
                      _chip(
                        'maintenance_amount'.trParams({
                          'amount': property.maintenanceCharges!.toStringAsFixed(0),
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppDesign.primaryYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  property.propertyTypeString,
                  style: TextStyle(color: AppDesign.buttonText, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppDesign.inputBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  property.purposeString,
                  style: TextStyle(color: AppDesign.textPrimary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(PropertyModel property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'description'.tr,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppDesign.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          property.description ?? 'no_description_available'.tr,
          style: TextStyle(fontSize: 16, color: AppDesign.textSecondary, height: 1.5),
        ),
      ],
    );
  }

  List<Widget> _buildHighlightsSection(PropertyModel property) {
    return [
      Text(
        'highlights'.tr,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppDesign.textPrimary),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (property.features ?? [])
            .take(6)
            .map(
              (t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppDesign.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppDesign.primaryYellow.withValues(alpha: 0.3)),
                ),
                child: Text(
                  t,
                  style: TextStyle(color: AppDesign.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 24),
    ];
  }

  Widget _buildAmenitiesSection(PropertyModel property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'amenities'.tr,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppDesign.textPrimary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              property.amenities?.map((amenity) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppDesign.primaryYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppDesign.primaryYellow.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (amenity.icon != null && amenity.icon!.startsWith('http')) ...[
                        Image.network(
                          amenity.icon!,
                          width: 16,
                          height: 16,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 6),
                      ] else ...[
                        Icon(Icons.check_circle_outline, size: 16, color: AppDesign.textSecondary),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        amenity.title,
                        style: TextStyle(color: AppDesign.textPrimary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList() ??
              [],
        ),
      ],
    );
  }

  List<Widget> _buildLocationSection(PropertyModel property) {
    final lat = property.latitude;
    final lng = property.longitude;
    if (lat == null || lng == null) return const [SizedBox.shrink()];

    return [
      const SizedBox(height: 8),
      Text(
        'location'.tr,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppDesign.textPrimary),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppDesign.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppDesign.getCardShadow(),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: AppDesign.iconColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                property.shortAddressDisplay,
                style: TextStyle(fontSize: 16, color: AppDesign.textSecondary),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppDesign.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppDesign.getCardShadow(),
          border: Border.all(color: AppDesign.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lng),
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
                  point: LatLng(lat, lng),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, size: 36, color: AppDesign.primaryYellow),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          key: const ValueKey('qa.property_details.get_directions'),
          onPressed: () => _openGoogleMaps(lat, lng, property.title),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppDesign.primaryYellow),
            foregroundColor: AppDesign.textPrimary,
          ),
          icon: const Icon(Icons.directions),
          label: Text('get_directions'.tr),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  Widget _buildBottomBar(
    BuildContext context,
    PropertyModel property,
    VisitsController visitsController,
  ) {
    return Obx(() {
      VisitModel? scheduledVisit;
      for (final v in visitsController.upcomingVisitsList) {
        if (v.propertyId == property.id) {
          scheduledVisit = v;
          break;
        }
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppDesign.surface,
          boxShadow: [
            BoxShadow(color: AppDesign.shadowColor, blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: (() {
            final DateTime? scheduledDate =
                property.userNextVisitDate ?? scheduledVisit?.scheduledDate;
            final bool alreadyScheduled = property.userHasScheduledVisit || scheduledDate != null;

            return alreadyScheduled
                ? _buildScheduledBanner(scheduledDate)
                : _buildScheduleButton(context, property, visitsController);
          })(),
        ),
      );
    });
  }

  Widget _buildScheduledBanner(DateTime? scheduledDate) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppDesign.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppDesign.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppDesign.accentGreen),
          const SizedBox(width: 8),
          Text(
            (() {
              if (scheduledDate != null) {
                final formatted =
                    '${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}';
                return '${'visit_scheduled'.tr}: $formatted';
              }
              return 'visit_scheduled'.tr;
            })(),
            style: TextStyle(
              color: AppDesign.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleButton(
    BuildContext context,
    PropertyModel property,
    VisitsController visitsController,
  ) {
    return ElevatedButton.icon(
      key: const ValueKey('qa.property_details.schedule_visit'),
      onPressed: () => showBookVisitDialog(context, property, visitsController),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppDesign.primaryYellow,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.calendar_today),
      label: Text(
        'schedule_visit'.tr,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppDesign.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.border),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppDesign.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PropertyLoadingScaffold extends StatelessWidget {
  const _PropertyLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppDesign.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppDesign.appBarIcon),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'property_details'.tr,
          style: TextStyle(color: AppDesign.appBarText, fontWeight: FontWeight.bold),
        ),
      ),
      body: LoadingStates.propertyDetailsSkeleton(),
    );
  }
}

class _PropertyErrorScaffold extends StatelessWidget {
  const _PropertyErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppDesign.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppDesign.appBarIcon),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'property_details'.tr,
          style: TextStyle(color: AppDesign.appBarText, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(message, style: TextStyle(fontSize: 18, color: AppDesign.textSecondary)),
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
