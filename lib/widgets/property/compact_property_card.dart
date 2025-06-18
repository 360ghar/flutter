import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import '../../app/data/models/property_model.dart';
import '../../app/utils/theme.dart';
import '../../app/routes/app_routes.dart';

class CompactPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isFavourite;
  final VoidCallback? onFavouriteToggle;
  final bool showFavoriteButton;

  const CompactPropertyCard({
    super.key,
    required this.property,
    this.isFavourite = false,
    this.onFavouriteToggle,
    this.showFavoriteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoutes.propertyDetails,
          arguments: property,
        ),
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image (full card)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: property.mainImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.backgroundGray,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryYellow,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.backgroundGray,
                    child: const Center(
                      child: Icon(
                        Icons.home,
                        color: AppTheme.textGray,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              // Dark gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Favorite Button Overlay (top right)
              if (showFavoriteButton)
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: onFavouriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavourite ? Icons.favorite : Icons.favorite_border,
                        color: isFavourite ? AppTheme.errorRed : AppTheme.textGray,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                             // Property Details at Bottom
               Positioned(
                 bottom: 12,
                 left: 12,
                 right: 12,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     // Property price
                     Text(
                       property.formattedPrice,
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                         color: AppTheme.primaryYellow,
                         fontWeight: FontWeight.bold,
                         fontSize: 18,
                         shadows: [
                           Shadow(
                             offset: const Offset(0, 1),
                             blurRadius: 3,
                             color: Colors.black.withOpacity(0.8),
                           ),
                         ],
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 4),
                     // Property title
                     Text(
                       property.title,
                       style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                         color: Colors.white,
                         fontWeight: FontWeight.w600,
                         fontSize: 14,
                         shadows: [
                           Shadow(
                             offset: const Offset(0, 1),
                             blurRadius: 3,
                             color: Colors.black.withOpacity(0.8),
                           ),
                         ],
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 2),
                     // Property location
                     Text(
                       '${property.city}, ${property.state}',
                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                         color: Colors.white.withOpacity(0.9),
                         fontSize: 12,
                         shadows: [
                           Shadow(
                             offset: const Offset(0, 1),
                             blurRadius: 2,
                             color: Colors.black.withOpacity(0.8),
                           ),
                         ],
                       ),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                     const SizedBox(height: 6),
                     // Property features
                     Row(
                       children: [
                         _buildFeature(Icons.bed, '${property.bedrooms}'),
                         const SizedBox(width: 8),
                         _buildFeature(Icons.bathtub_outlined, '${property.bathrooms}'),
                         const SizedBox(width: 8),
                         _buildFeature(Icons.square_foot, '${property.area.toInt()}'),
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

  Widget _buildFeature(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Colors.white.withOpacity(0.9),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 2,
                color: Colors.black.withOpacity(0.8),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 