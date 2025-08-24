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
    return GestureDetector(
      onTap: onTap ?? () => _viewPropertyDetails(),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.primaryYellow, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            _buildImageSection(),

            // Property Details
            _buildDetailsSection(),

            // Action Buttons
            _buildActionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Main Image
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            image: DecorationImage(
              image: NetworkImage(property.mainImage),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Gradient Overlay
        Container(
          height: 140,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),

        // Price Badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryYellow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              property.formattedPrice,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Like Button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: onLikeTap ?? () => _toggleLike(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                property.liked ? Icons.favorite : Icons.favorite_border,
                color: property.liked ? Colors.red : Colors.grey,
                size: 20,
              ),
            ),
          ),
        ),

        // Property Type Badge
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              property.purposeString,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Expanded(
      child: Padding(
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
                  const SizedBox(width: 12),
                ],
                if (property.bathrooms != null) ...[
                  _buildFeatureIcon(Icons.bathtub, '${property.bathrooms}Ba'),
                  const SizedBox(width: 12),
                ],
                if (property.areaSqft != null) ...[
                  _buildFeatureIcon(Icons.square_foot, '${property.areaSqft}ft²'),
                ],
              ],
            ),

            const Spacer(),

            // Distance (if available)
            if (property.distanceKm != null) ...[
              Text(
                property.distanceText,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // View Details Button
          Expanded(
            child: ElevatedButton(
              onPressed: onTap ?? () => _viewPropertyDetails(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('View Details'),
            ),
          ),

          const SizedBox(width: 8),

          // Contact Button
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _contactOwner(),
              icon: Icon(
                Icons.phone,
                size: 16,
                color: Colors.grey[600],
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
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

  void _contactOwner() {
    DebugLogger.api('Contacting owner for property: ${property.title}');

    if (property.ownerContact?.isNotEmpty == true) {
      // You can implement phone call or WhatsApp functionality here
      Get.snackbar(
        'Contact Owner',
        'Phone: ${property.ownerContact}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryYellow,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Contact Info',
        'Contact information not available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
