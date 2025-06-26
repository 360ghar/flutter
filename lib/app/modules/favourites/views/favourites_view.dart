import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/property_controller.dart';
import '../../../utils/app_colors.dart';
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
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBarBackground,
          elevation: 0,
          title: Text(
            'my_favorites'.tr,
            style: TextStyle(
              color: AppColors.appBarText,
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
          bottom: TabBar(
            labelColor: AppColors.tabSelected,
            unselectedLabelColor: AppColors.tabUnselected,
            indicatorColor: AppColors.tabIndicator,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'liked'.tr),
              Tab(text: 'passed'.tr),
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
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.loadingIndicator,
          ),
        );
      }

      if (filteredProperties.isEmpty) {
        return _buildEmptyState(
          icon: Icons.favorite_border,
          title: 'no_favorites'.tr,
          subtitle: 'no_favorites_message'.tr,
        );
      }

      return RefreshIndicator(
        color: AppColors.loadingIndicator,
        backgroundColor: AppColors.surface,
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
                  backgroundColor: AppColors.snackbarBackground,
                  colorText: AppColors.snackbarText,
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
        return Center(
          child: CircularProgressIndicator(
            color: AppColors.loadingIndicator,
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
        color: AppColors.loadingIndicator,
        backgroundColor: AppColors.surface,
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
                  backgroundColor: AppColors.snackbarBackground,
                  colorText: AppColors.snackbarText,
                  duration: const Duration(seconds: 2),
                );
              },
            );
          },
        ),
      );
    });
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
              color: AppColors.disabledColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 