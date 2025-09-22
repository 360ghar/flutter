import 'package:flutter/material.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/utils/app_colors.dart';

class PropertyDetailsFeatures extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailsFeatures({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (property.bedrooms != null)
                _buildFeature(Icons.bed, '${property.bedrooms}', 'Bedrooms'),
              if (property.bathrooms != null)
                _buildFeature(Icons.bathtub_outlined, '${property.bathrooms}', 'Bathrooms'),
              if (property.areaSqft != null)
                _buildFeature(Icons.square_foot, '${property.areaSqft?.toInt()}', 'Sq Ft'),
            ],
          ),
          if (property.balconies != null ||
              property.parkingSpaces != null ||
              property.floorNumber != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (property.balconies != null)
                  _buildFeature(Icons.balcony, '${property.balconies}', 'Balconies'),
                if (property.parkingSpaces != null)
                  _buildFeature(Icons.local_parking, '${property.parkingSpaces}', 'Parking'),
                if (property.floorNumber != null)
                  _buildFeature(
                    Icons.layers,
                    '${property.floorNumber}/${property.totalFloors ?? "?"}',
                    'Floor',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
