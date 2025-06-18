import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../controllers/property_controller.dart';
import '../../../data/models/property_model.dart';
import '../../../utils/theme.dart';
import '../../../../widgets/property/compact_property_card.dart';
import '../../../../widgets/navigation/bottom_nav_bar.dart';
import '../../../../widgets/common/property_filter_widget.dart';

class FavouritesView extends GetView<PropertyController> {
  const FavouritesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'My Properties',
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            PropertyFilterWidget(
              pageType: 'favourites',
              onFiltersApplied: () {
                // The UI will automatically update due to Obx in build method
                // No additional action needed as filters are reactive
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: AppTheme.primaryYellow,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryYellow,
            indicatorWeight: 3,
            labelStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'Liked'),
              Tab(text: 'Passed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLikedPropertiesTab(),
            _buildPassedPropertiesTab(),
          ],
        ),
        bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 3),
      ),
    );
  }

  Widget _buildLikedPropertiesTab() {
    return Obx(() {
      final filteredProperties = controller.getFilteredFavourites();
      
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryYellow,
          ),
        );
      }

      if (filteredProperties.isEmpty) {
        return _buildEmptyState(
          icon: Icons.favorite_border,
          title: 'No Liked Properties',
          subtitle: 'Properties you like will appear here.\nStart swiping to find your dream home!',
        );
      }

      return RefreshIndicator(
        color: AppTheme.primaryYellow,
        onRefresh: () => controller.fetchFavouriteProperties(),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75, // Adjust for card height
          ),
          itemCount: filteredProperties.length,
          itemBuilder: (context, index) {
            final property = filteredProperties[index];
            return CompactPropertyCard(
              property: property,
              isFavourite: true,
              onFavouriteToggle: () {
                controller.removeFromFavourites(property.id);
                Get.snackbar(
                  'Removed',
                  'Property removed from liked list',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: AppTheme.primaryYellow,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildPassedPropertiesTab() {
    return Obx(() {
      final filteredProperties = controller.getFilteredPassed();
      
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryYellow,
          ),
        );
      }

      if (filteredProperties.isEmpty) {
        return _buildEmptyState(
          icon: Icons.not_interested,
          title: 'No Passed Properties',
          subtitle: 'Properties you\'ve passed on will appear here.\nYou can always give them another chance!',
        );
      }

      return RefreshIndicator(
        color: AppTheme.primaryYellow,
        onRefresh: () => controller.fetchPassedProperties(),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75, // Adjust for card height
          ),
          itemCount: filteredProperties.length,
          itemBuilder: (context, index) {
            final property = filteredProperties[index];
            return CompactPropertyCard(
              property: property,
              isFavourite: false,
              onFavouriteToggle: () {
                controller.addToFavourites(property.id);
                controller.removeFromPassedProperties(property.id);
                Get.snackbar(
                  'Added to Liked',
                  'Property moved to liked list',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: AppTheme.primaryYellow,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildPropertyCard(PropertyModel property, {required bool isLiked}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: property.images.first,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryYellow,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
                // Action buttons overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _buildActionButton(
                        icon: isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        onTap: () {
                          if (isLiked) {
                            controller.removeFromFavourites(property.id);
                            Get.snackbar(
                              'Removed',
                              'Property removed from liked list',
                              snackPosition: SnackPosition.TOP,
                              duration: const Duration(seconds: 2),
                            );
                          } else {
                            controller.addToFavourites(property.id);
                            controller.removeFromPassedProperties(property.id);
                            Get.snackbar(
                              'Added to Liked',
                              'Property moved to liked list',
                              snackPosition: SnackPosition.TOP,
                              duration: const Duration(seconds: 2),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.share,
                        color: Colors.white,
                        onTap: () {
                          // Implement share functionality
                          Get.snackbar(
                            'Share',
                            'Sharing ${property.title}',
                            snackPosition: SnackPosition.TOP,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Property Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child:                       Text(
                        property.formattedPrice,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (!isLiked)
                      TextButton.icon(
                        onPressed: () {
                          controller.addToFavourites(property.id);
                          controller.removeFromPassedProperties(property.id);
                          Get.snackbar(
                            'Second Chance!',
                            'Property moved to liked list',
                            snackPosition: SnackPosition.TOP,
                            duration: const Duration(seconds: 2),
                          );
                        },
                        icon: const Icon(Icons.refresh, color: AppTheme.primaryYellow),
                        label: const Text(
                          'Give Another Chance',
                          style: TextStyle(color: AppTheme.primaryYellow),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  property.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildPropertySpec(Icons.bed, '${property.bedrooms} bed'),
                    const SizedBox(width: 16),
                    _buildPropertySpec(Icons.bathtub, '${property.bathrooms} bath'),
                    const SizedBox(width: 16),
                    _buildPropertySpec(Icons.square_foot, '${property.area.toInt()} sqft'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.toNamed('/property-details', arguments: property);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color == Colors.white ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: color == Colors.white
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: color == Colors.white ? Colors.black : color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPropertySpec(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 