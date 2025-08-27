import 'package:flutter/material.dart';
import '../../../core/data/models/property_model.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final double? width;

  const PropertyCard({
    super.key,
    required this.property,
    this.isSelected = false,
    this.onTap,
    this.onLikeTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width ?? 320,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                                image: property.mainImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(property.mainImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
              color: property.mainImageUrl == null
                      ? Colors.grey[300]
                      : null,
                ),
                child: property.mainImageUrl == null
                    ? const Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: Colors.grey,
                      )
                    : null,
              ),

              // Property Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price
                    Text(
                      '₹${property.basePrice?.toStringAsFixed(0) ?? 'N/A'}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Property Title
                    Text(
                      property.title ?? 'Property Title',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Property Features
                    Row(
                      children: [
                        if (property.bedrooms != null) ...[
                          Icon(
                            Icons.king_bed_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${property.bedrooms}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (property.bathrooms != null) ...[
                          Icon(
                            Icons.bathtub_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${property.bathrooms}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (property.areaSqft != null && property.areaSqft! > 0) ...[
                          Icon(
                            Icons.square_foot,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${property.areaSqft?.toStringAsFixed(0) ?? 'N/A'} sq ft',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            property.fullAddress ?? property.city ?? 'Location not available',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
