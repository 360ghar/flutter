import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/data/models/property_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/debug_logger.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;

  const PropertyCard({
    super.key,
    required this.property,
    this.isSelected = false,
    this.onTap,
    this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 400 ? 320.0 : (screenWidth - 48); // Responsive width
    final cardHeight = 120.0;

    return GestureDetector(
      onTap: onTap ?? () => _viewPropertyDetails(),
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppColors.primaryYellow, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left: Property Image
            _buildImageSection(),

            // Right: Property Details
            Expanded(
              child: _buildDetailsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final imageWidth = screenWidth > 400 ? 100.0 : 80.0;

    return Stack(
      children: [
        // Main Image
        Container(
          width: imageWidth,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            image: DecorationImage(
              image: NetworkImage(property.mainImage),
              fit: BoxFit.cover,
              onError: (error, stackTrace) {
                // Handle image loading errors
                debugPrint('Error loading image: $error');
              },
            ),
          ),
        ),

        // Price Badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              property.formattedPrice,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Like Button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onLikeTap ?? () => _toggleLike(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                property.liked ? Icons.favorite : Icons.favorite_border,
                color: property.liked ? Colors.red : Colors.grey,
                size: 16,
              ),
            ),
          ),
        ),

        // Property Type Badge
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              property.purposeString,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            property.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  property.addressDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Property Features
          Row(
            children: [
              if (property.bedrooms != null) ...[
                _buildFeatureIcon(Icons.bed, '${property.bedrooms}B'),
                const SizedBox(width: 8),
              ],
              if (property.bathrooms != null) ...[
                _buildFeatureIcon(Icons.bathtub, '${property.bathrooms}Ba'),
                const SizedBox(width: 8),
              ],
              if (property.areaSqft != null) ...[
                _buildFeatureIcon(Icons.square_foot, '${property.areaSqft}ft²'),
              ],
            ],
          ),

          const Spacer(),

          // Distance and View Details Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (property.distanceKm != null)
                Text(
                  property.distanceText,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                )
              else
                const SizedBox(),

              // View Details Button
              TextButton(
                onPressed: onTap ?? () => _viewPropertyDetails(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 12,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }



  void _viewPropertyDetails() {
    DebugLogger.api('Viewing property details: ${property.title}');
    Get.toNamed('/property-details', arguments: {'property': property});
  }

  void _toggleLike() {
    DebugLogger.api('Toggling like for property: ${property.title}');
    // This will be handled by the controller
    onLikeTap?.call();
  }


}
