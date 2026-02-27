import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:google_fonts/google_fonts.dart';

/// Property information card (purpose, age).
class PropertyDetailsInfoSection extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsInfoSection({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppDesign.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditorialSectionHeader(context, 'property_information'.tr),
          buildInfoRow('purpose'.tr, property.purposeString),
          if (property.ageText.isNotEmpty) buildInfoRow('age'.tr, property.ageText),
        ],
      ),
    );
  }
}

/// Pricing details card with purpose-aware rows.
class PropertyDetailsPricingSection extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsPricingSection({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppDesign.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditorialSectionHeader(context, 'pricing_details'.tr),
          ..._buildPricingRows(),
        ],
      ),
    );
  }

  List<Widget> _buildPricingRows() {
    final purpose = property.purpose;
    final rows = <Widget>[];

    if (purpose == PropertyPurpose.rent) {
      final rent = property.monthlyRent ?? property.basePrice;
      rows.add(buildInfoRow('monthly_rent'.tr, '₹${rent.toStringAsFixed(0)}'));
      if (property.securityDeposit != null) {
        rows.add(
          buildInfoRow('security_deposit'.tr, '₹${property.securityDeposit!.toStringAsFixed(0)}'),
        );
      }
      if (property.maintenanceCharges != null) {
        rows.add(
          buildInfoRow('maintenance'.tr, '₹${property.maintenanceCharges!.toStringAsFixed(0)}'),
        );
      }
    } else if (purpose == PropertyPurpose.shortStay) {
      final rate = property.dailyRate ?? property.basePrice;
      rows.add(buildInfoRow('daily_rate'.tr, '₹${rate.toStringAsFixed(0)}'));
      if (property.securityDeposit != null) {
        rows.add(
          buildInfoRow('security_deposit'.tr, '₹${property.securityDeposit!.toStringAsFixed(0)}'),
        );
      }
    } else {
      rows.add(buildInfoRow('sale_price'.tr, '₹${property.basePrice.toStringAsFixed(0)}'));
      if (property.pricePerSqft != null) {
        rows.add(
          buildInfoRow('price_per_sq_ft'.tr, '₹${property.pricePerSqft!.toStringAsFixed(0)}'),
        );
      }
      if (property.maintenanceCharges != null) {
        rows.add(
          buildInfoRow('maintenance'.tr, '₹${property.maintenanceCharges!.toStringAsFixed(0)}'),
        );
      }
    }

    return rows;
  }
}

/// Builder/contact information card.
class PropertyDetailsContactSection extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsContactSection({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppDesign.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEditorialSectionHeader(context, 'builder_information'.tr),
          if (property.builderName?.isNotEmpty == true)
            buildInfoRow('builder'.tr, property.builderName!),
        ],
      ),
    );
  }
}

/// Shared label–value row used by the info section widgets above.
Widget buildInfoRow(String label, String value) {
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
            color: AppDesign.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppDesign.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}

Widget _buildEditorialSectionHeader(BuildContext context, String title) {
  final theme = Theme.of(context);

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            textStyle: theme.textTheme.headlineSmall?.copyWith(
              color: AppDesign.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 56, height: 1, color: AppDesign.primaryYellow.withValues(alpha: 0.75)),
      ],
    ),
  );
}
