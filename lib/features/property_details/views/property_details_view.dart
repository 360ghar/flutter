import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/data/repositories/properties_repository.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/utils/share_utils.dart';
import 'package:ghar360/core/widgets/common/loading_states.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';
import 'package:ghar360/core/widgets/property/property_details_features.dart';
import 'package:ghar360/features/likes/controllers/likes_controller.dart';
import 'package:ghar360/features/visits/controllers/visits_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PropertyDetailsView extends StatelessWidget {
  const PropertyDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Handle both PropertyModel object and String ID
    final dynamic arguments = Get.arguments;
    PropertyModel? property;

    if (arguments is PropertyModel) {
      property = arguments;
    } else if (arguments is String || arguments is int) {
      final int? propertyId = arguments is int ? arguments : int.tryParse(arguments as String);
      if (propertyId == null) {
        return const _PropertyErrorScaffold(message: 'Invalid property id');
      }
      // Fetch property by id, then navigate to the same route with full data
      final repo = Get.find<PropertiesRepository>();
      return FutureBuilder<PropertyModel>(
        future: repo.getPropertyDetail(propertyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _PropertyLoadingScaffold();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const _PropertyErrorScaffold(message: 'Failed to load property');
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Replace current route with one that has a full PropertyModel argument
            Get.offNamed(AppRoutes.propertyDetails, arguments: snapshot.data);
          });
          return const _PropertyLoadingScaffold();
        },
      );
    }

    if (property == null) {
      return const _PropertyErrorScaffold(message: 'Property not found');
    }

    // Use LikesController for favorite management
    final controller = Get.find<LikesController>();
    final visitsController = Get.find<VisitsController>();

    // Add null check to ensure property is not null
    final PropertyModel safeProperty = property;

    // Ensure visits are loaded to reflect scheduled state in UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!visitsController.hasLoadedVisits.value && !visitsController.isLoading.value) {
        visitsController.loadVisitsLazy();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.appBarBackground,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
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
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Obx(
                  () => IconButton(
                    icon: Icon(
                      controller.isFavourite(safeProperty.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: controller.isFavourite(safeProperty.id)
                          ? AppColors.favoriteActive
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
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () => ShareUtils.shareProperty(safeProperty, context: context),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _PropertyImageGallery(property: safeProperty),
            ),
          ),

          // Property Details Content
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.scaffoldBackground,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price and Title
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.getCardShadow(),
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
                                        text: safeProperty.formattedPrice,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.propertyCardPrice,
                                        ),
                                      ),
                                      if (safeProperty.purpose == PropertyPurpose.rent)
                                        TextSpan(
                                          text: ' /mo',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      if (safeProperty.purpose == PropertyPurpose.shortStay)
                                        TextSpan(
                                          text: ' /day',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  safeProperty.title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Quick pricing chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (safeProperty.pricePerSqft != null)
                                      _chip(
                                        '₹${safeProperty.pricePerSqft!.toStringAsFixed(0)}/sqft',
                                      ),
                                    if (safeProperty.securityDeposit != null)
                                      _chip(
                                        'Deposit ₹${safeProperty.securityDeposit!.toStringAsFixed(0)}',
                                      ),
                                    if (safeProperty.maintenanceCharges != null)
                                      _chip(
                                        'Maintenance ₹${safeProperty.maintenanceCharges!.toStringAsFixed(0)}',
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
                                  color: AppColors.primaryYellow,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  safeProperty.propertyTypeString,
                                  style: TextStyle(
                                    color: AppColors.buttonText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.inputBackground,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  safeProperty.purposeString,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 360° Tour: priority after basic info
                    if (safeProperty.virtualTourUrl != null &&
                        safeProperty.virtualTourUrl!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _VirtualTourSection(
                        tourUrl: safeProperty.virtualTourUrl!,
                        thumbnailUrl: safeProperty.mainImage,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Property Features
                    PropertyDetailsFeatures(property: safeProperty),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      safeProperty.description ?? 'No description available',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    if ((safeProperty.features?.isNotEmpty ?? false)) ...[
                      Text(
                        'Highlights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (safeProperty.features ?? [])
                            .take(6)
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryYellow.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.primaryYellow.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 24),

                    // Additional Property Information
                    _buildPropertyInfoSection(safeProperty),
                    const SizedBox(height: 24),

                    // Pricing Details
                    _buildPricingSection(safeProperty),
                    const SizedBox(height: 24),

                    // Builder Information (no owner details shown)
                    if (safeProperty.builderName?.isNotEmpty == true) ...[
                      _buildContactSection(safeProperty),
                      const SizedBox(height: 24),
                    ],

                    // Amenities
                    Text(
                      'Amenities',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          safeProperty.amenities?.map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryYellow.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryYellow.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (amenity.icon != null && amenity.icon!.startsWith('http')) ...[
                                    Image.network(
                                      amenity.icon!,
                                      width: 16,
                                      height: 16,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox.shrink(),
                                    ),
                                    const SizedBox(width: 6),
                                  ] else ...[
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    amenity.title,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList() ??
                          [],
                    ),
                    const SizedBox(height: 24),

                    // Location + Get Directions at the very end
                    if (safeProperty.hasLocation) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.getCardShadow(),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: AppColors.iconColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                safeProperty.shortAddressDisplay,
                                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.getCardShadow(),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(safeProperty.latitude!, safeProperty.longitude!),
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
                                  point: LatLng(safeProperty.latitude!, safeProperty.longitude!),
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
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () => _openGoogleMaps(
                            safeProperty.latitude!,
                            safeProperty.longitude!,
                            safeProperty.title,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryYellow),
                            foregroundColor: AppColors.textPrimary,
                          ),
                          icon: const Icon(Icons.directions),
                          label: Text('get_directions'.tr),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Buttons
      bottomNavigationBar: Obx(() {
        // Find any upcoming scheduled visit for this property
        VisitModel? scheduledVisit;
        for (final v in visitsController.upcomingVisitsList) {
          if (v.propertyId == safeProperty.id) {
            scheduledVisit = v;
            break;
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: const Offset(0, -5)),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: (() {
              // Prefer server-provided schedule info
              final DateTime? scheduledDate =
                  safeProperty.userNextVisitDate ?? scheduledVisit?.scheduledDate;
              final bool alreadyScheduled =
                  safeProperty.userHasScheduledVisit || scheduledDate != null;

              return alreadyScheduled
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.accentGreen),
                          const SizedBox(width: 8),
                          Text(
                            scheduledDate != null
                                ? 'Scheduled on ${scheduledDate.day}/${scheduledDate.month}/${scheduledDate.year}'
                                : 'Visit Scheduled',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: () =>
                          _showBookVisitDialog(context, safeProperty, visitsController),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
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
            })(),
          ),
        );
      }),
    );
  }

  Widget _buildPropertyInfoSection(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Property Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Purpose', property.purposeString),
          if (property.ageText.isNotEmpty) _buildInfoRow('Age', property.ageText),
        ],
      ),
    );
  }

  Widget _buildPricingSection(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pricing Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(() {
            final purpose = property.purpose;
            final rows = <Widget>[];
            if (purpose == PropertyPurpose.rent) {
              final rent = property.monthlyRent ?? property.basePrice;
              rows.add(_buildInfoRow('Monthly Rent', '₹${rent.toStringAsFixed(0)}'));
              if (property.securityDeposit != null) {
                rows.add(
                  _buildInfoRow(
                    'Security Deposit',
                    '₹${property.securityDeposit!.toStringAsFixed(0)}',
                  ),
                );
              }
              if (property.maintenanceCharges != null) {
                rows.add(
                  _buildInfoRow(
                    'Maintenance',
                    '₹${property.maintenanceCharges!.toStringAsFixed(0)}',
                  ),
                );
              }
            } else if (purpose == PropertyPurpose.shortStay) {
              final rate = property.dailyRate ?? property.basePrice;
              rows.add(_buildInfoRow('Daily Rate', '₹${rate.toStringAsFixed(0)}'));
              if (property.securityDeposit != null) {
                rows.add(
                  _buildInfoRow(
                    'Security Deposit',
                    '₹${property.securityDeposit!.toStringAsFixed(0)}',
                  ),
                );
              }
            } else {
              // Buy/default
              rows.add(_buildInfoRow('Sale Price', '₹${property.basePrice.toStringAsFixed(0)}'));
              if (property.pricePerSqft != null) {
                rows.add(
                  _buildInfoRow('Price per Sq Ft', '₹${property.pricePerSqft!.toStringAsFixed(0)}'),
                );
              }
              if (property.maintenanceCharges != null) {
                rows.add(
                  _buildInfoRow(
                    'Maintenance',
                    '₹${property.maintenanceCharges!.toStringAsFixed(0)}',
                  ),
                );
              }
            }
            return rows;
          })(),
        ],
      ),
    );
  }

  Widget _buildContactSection(PropertyModel property) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contact_phone, color: AppColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Builder Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (property.builderName?.isNotEmpty == true)
            _buildInfoRow('Builder', property.builderName!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // Small UI helpers
  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showBookVisitDialog(
    BuildContext context,
    PropertyModel safeProperty,
    VisitsController visitsController,
  ) {
    // Default to next day and a fixed time for backend
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    const defaultHour = 10; // 10:00 AM default
    const defaultMinute = 0;
    final TextEditingController notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Schedule Visit', style: TextStyle(color: AppColors.textPrimary)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Schedule a visit to ${safeProperty.title}',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Date Selection
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: AppColors.primaryYellow),
                  title: Text('Date', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Special requirements / notes
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'special_requirements_label'.tr,
                    hintText: 'special_requirements_hint'.tr,
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final visitDateTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                defaultHour,
                defaultMinute,
              );

              final notes = notesController.text.trim().isEmpty
                  ? null
                  : notesController.text.trim();

              visitsController.bookVisit(safeProperty, visitDateTime, notes: notes);
              Get.back();

              Get.snackbar(
                'visit_scheduled'.tr,
                '${'visit_scheduled_message_prefix'.tr} ${safeProperty.title} ${'visit_scheduled_message_infix'.tr} ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.accentGreen,
                colorText: AppColors.snackbarText,
                duration: const Duration(seconds: 3),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: Text('schedule_visit'.tr),
          ),
        ],
      ),
    );
  }
}

class _PropertyLoadingScaffold extends StatelessWidget {
  const _PropertyLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.appBarIcon),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'property_details'.tr,
          style: TextStyle(color: AppColors.appBarText, fontWeight: FontWeight.bold),
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
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.appBarIcon),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'property_details'.tr,
          style: TextStyle(color: AppColors.appBarText, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(message, style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
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

// Image gallery for the header
class _PropertyImageGallery extends StatefulWidget {
  final PropertyModel property;
  const _PropertyImageGallery({required this.property});

  @override
  State<_PropertyImageGallery> createState() => _PropertyImageGalleryState();
}

class _PropertyImageGalleryState extends State<_PropertyImageGallery> {
  late final PageController _pageController;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.property.galleryImageUrls;
    final itemCount = images.isNotEmpty ? images.length : 1;
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: itemCount,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (context, index) {
            final url = images.isNotEmpty ? images[index] : widget.property.mainImage;
            return RobustNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: AppColors.inputBackground,
                child: Icon(Icons.image, size: 50, color: AppColors.disabledColor),
              ),
            );
          },
        ),
        if (itemCount > 1)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.shadowColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_current + 1}/$itemCount',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _VirtualTourSection extends StatefulWidget {
  const _VirtualTourSection({required this.tourUrl, this.thumbnailUrl});

  final String tourUrl;
  final String? thumbnailUrl;

  @override
  State<_VirtualTourSection> createState() => _VirtualTourSectionState();
}

class _VirtualTourSectionState extends State<_VirtualTourSection> {
  bool _showEmbeddedTour = false;

  void _openFullScreen() {
    Get.toNamed('/tour', arguments: widget.tourUrl);
  }

  void _handleLoadTour() {
    if (!_showEmbeddedTour) {
      setState(() {
        _showEmbeddedTour = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.threesixty, size: 24, color: AppColors.primaryYellow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '360° Virtual Tour',
                      style:
                          theme.textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ) ??
                          TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _openFullScreen,
              icon: const Icon(Icons.fullscreen, size: 18, color: AppColors.primaryYellow),
              label: const Text('Fullscreen'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                backgroundColor: AppColors.primaryYellow.withValues(alpha: 0.1),
                foregroundColor: AppColors.primaryYellow,
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.primaryYellow.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _showEmbeddedTour
              ? _TourContainer(
                  key: const ValueKey('embeddedTour'),
                  child: _Embedded360TourDetails(tourUrl: widget.tourUrl),
                )
              : _TourContainer(
                  key: const ValueKey('tourPlaceholder'),
                  child: GestureDetector(
                    onTap: _handleLoadTour,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
                          RobustNetworkImage(
                            imageUrl: widget.thumbnailUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                            memCacheHeight: 450,
                          )
                        else
                          Container(color: AppColors.inputBackground),
                        Container(color: Colors.black.withValues(alpha: 0.35)),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_circle_fill,
                                size: 64,
                                color: AppColors.primaryYellow,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tap to load virtual tour',
                                style:
                                    theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ) ??
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TourContainer extends StatelessWidget {
  const _TourContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }
}

class _Embedded360TourDetails extends StatefulWidget {
  final String tourUrl;

  const _Embedded360TourDetails({required this.tourUrl});

  @override
  State<_Embedded360TourDetails> createState() => _Embedded360TourDetailsState();
}

class _Embedded360TourDetailsState extends State<_Embedded360TourDetails> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    const consoleSilencer = '''
      if (window && window.console) {
        window.console.log = function() {};
        window.console.warn = function() {};
        window.console.error = function() {};
        window.console.info = function() {};
        window.console.debug = function() {};
      }
    ''';

    controller = WebViewController()
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
            controller.runJavaScript(consoleSilencer);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
            controller.runJavaScript(consoleSilencer);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                isLoading = false;
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

    controller.loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (isLoading)
          Container(
            color: AppColors.inputBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 3),
                  const SizedBox(height: 12),
                  Text(
                    'Loading 360° Tour...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
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
