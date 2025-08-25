import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/data/models/property_model.dart';
import '../../core/utils/app_colors.dart';
import '../common/robust_network_image.dart';

class CompactPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;

  const CompactPropertyCard({
    super.key,
    required this.property,
    required this.isFavourite,
    required this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 2,
      color: AppColors.propertyCardBackground,
      shadowColor: AppColors.shadowColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed('/property-details', arguments: property);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevent unbounded height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image with fixed height container
            SizedBox(
              height: 120,
              child: Stack(
                children: [
                  // Main image
                  Positioned.fill(
                    child: RobustNetworkImage(
                      imageUrl: property.mainImage,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      memCacheWidth: 200,
                      memCacheHeight: 120,
                      placeholder: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryYellow,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Loading...',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Property type badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        property.propertyTypeString.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavourite ? Icons.favorite : Icons.favorite_border,
                          color: isFavourite ? AppColors.favoriteActive : Colors.white,
                          size: 20,
                        ),
                        onPressed: onFavouriteToggle,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Property Details Section
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property title and price
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            property.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.propertyCardText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          property.formattedPrice,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.propertyCardPrice,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Location
                    Text(
                      property.addressDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.propertyCardSubtext,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Property features row
                    Row(
                      children: [
                        // Bedrooms/Bathrooms
                        if (property.bedroomBathroomText.isNotEmpty) ...[
                          Icon(
                            Icons.bed_outlined,
                            size: 14,
                            color: AppColors.propertyFeatureText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            property.bedroomBathroomText,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.propertyFeatureText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        
                        // Area
                        if (property.areaText.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.square_foot,
                            size: 14,
                            color: AppColors.propertyFeatureText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            property.areaText,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.propertyFeatureText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Additional features row (floor, age, etc.)
                    if (property.floorText.isNotEmpty || property.ageText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Floor information
                          if (property.floorText.isNotEmpty) ...[
                            Icon(
                              Icons.layers_outlined,
                              size: 14,
                              color: AppColors.propertyFeatureText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              property.floorText,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.propertyFeatureText,
                              ),
                            ),
                          ],
                          
                          // Age information
                          if (property.ageText.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time_outlined,
                              size: 14,
                              color: AppColors.propertyFeatureText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              property.ageText,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.propertyFeatureText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}