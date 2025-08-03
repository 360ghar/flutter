import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/safe_get_view.dart';
import '../../../utils/app_colors.dart';
import '../../../../widgets/property/compact_property_card.dart';
import '../../../../widgets/navigation/bottom_nav_bar.dart';
import '../../../../widgets/common/property_filter_widget.dart';
import '../../../../widgets/common/paginated_grid_view.dart';

class FavouritesView extends SafePropertyView {
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
            IconButton(
              onPressed: () {
                propertyController.fetchFavouriteProperties();
                Get.snackbar(
                  'Refreshed',
                  'Favourite properties updated',
                  snackPosition: SnackPosition.TOP,
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.primaryYellow,
                  colorText: Colors.white,
                );
              },
              icon: Icon(
                Icons.refresh,
                color: AppColors.appBarText,
              ),
            ),
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
      // Lazy load favourites data when tab is accessed
      if (propertyController.favouriteProperties.isEmpty && !propertyController.isLoading.value) {
        propertyController.fetchFavouritePropertiesLazy();
      }
      
      final filteredProperties = propertyController.getFilteredFavourites();
      
      return PaginatedGridView(
        items: filteredProperties,
        onLoadMore: () async {
          // For favourites, we typically don't paginate since it's user's limited list
          // But we can refresh to get any new favourites
        },
        hasMore: false, // Favourites typically don't need pagination
        isLoadingMore: false,
        isLoading: propertyController.isLoading.value,
        onRefresh: () => propertyController.fetchFavouriteProperties(),
        emptyWidget: _buildEmptyState(
          icon: Icons.favorite_border,
          title: 'no_favorites'.tr,
          subtitle: 'no_favorites_message'.tr,
        ),
        itemBuilder: (context, property, index) {
          return CompactPropertyCard(
            property: property,
            isFavourite: true,
            onFavouriteToggle: () {
              propertyController.removeFromFavourites(property.id);
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
      );
    });
  }

  Widget _buildPassedPropertiesTab() {
    return Obx(() {
      // Lazy load passed properties data when tab is accessed
      if (propertyController.passedProperties.isEmpty && !propertyController.isLoading.value) {
        propertyController.fetchPassedPropertiesLazy();
      }
      
      final filteredProperties = propertyController.getFilteredPassed();
      
      return PaginatedGridView(
        items: filteredProperties,
        onLoadMore: () async {
          // For passed properties, we typically don't paginate since it's user's limited list
        },
        hasMore: false, // Passed properties typically don't need pagination
        isLoadingMore: false,
        isLoading: propertyController.isLoading.value,
        onRefresh: () => propertyController.fetchPassedProperties(),
        emptyWidget: _buildEmptyState(
          icon: Icons.not_interested,
          title: 'No Passed Properties',
          subtitle: 'Properties you\'ve passed on will appear here.\nYou can always give them another chance!',
        ),
        itemBuilder: (context, property, index) {
          return CompactPropertyCard(
            property: property,
            isFavourite: false,
            onFavouriteToggle: () {
              propertyController.addToFavourites(property.id);
              propertyController.removeFromPassedProperties(property.id);
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryYellow.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.offAllNamed('/home'),
              icon: const Icon(Icons.explore),
              label: const Text('Explore Properties'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 