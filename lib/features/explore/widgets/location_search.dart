import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/explore_controller.dart';
import '../../../core/data/models/location_model.dart';
import '../../../core/utils/app_colors.dart';

class LocationSearch extends GetView<ExploreController> {
  const LocationSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isSearchActive.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search Input
              _buildSearchInput(),

              // Search Results
              if (controller.searchResults.isNotEmpty)
                _buildSearchResults(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() => TextField(
              onChanged: controller.updateSearchQuery,
              controller: TextEditingController(text: controller.searchQuery.value),
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search for a city or area...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              autofocus: true,
            )),
          ),
          Obx(() {
            if (controller.isSearchActive.value) {
              return IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: controller.clearSearch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: controller.searchResults.length,
        itemBuilder: (context, index) {
          final result = controller.searchResults[index];
          return _buildSearchResultItem(result);
        },
      ),
    );
  }

  Widget _buildSearchResultItem(LocationResult result) {
    return InkWell(
      onTap: () => controller.selectLocationResult(result),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey, width: 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result.description != result.displayText) ...[
                    const SizedBox(height: 2),
                    Text(
                      result.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (result.coordinates != null) ...[
              Icon(
                Icons.my_location,
                color: AppColors.primaryYellow,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Enhanced static method to show location search dialog
  static Future<void> showLocationSearch(BuildContext context) async {
    final controller = Get.find<ExploreController>();

    // Show a modal bottom sheet with location search
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryYellow,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_searching,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Search Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Current Location Option
            _buildCurrentLocationOption(controller),

            // Popular Cities Section
            _buildPopularCities(),

            // Search Input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: controller.updateSearchQuery,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search for a city or area...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                autofocus: true,
              ),
            ),

            // Search Results
            Expanded(
              child: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
                  return _buildRecentSearches(controller);
                }

                if (controller.searchResults.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final result = controller.searchResults[index];
                    return ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                      ),
                      title: Text(result.displayText),
                      subtitle: result.description != result.displayText
                          ? Text(result.description)
                          : null,
                      trailing: result.coordinates != null
                          ? Icon(
                              Icons.my_location,
                              color: AppColors.primaryYellow,
                            )
                          : null,
                      onTap: () {
                        controller.selectLocationResult(result);
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPopularCities() {
    final popularCities = [
      {'name': 'Delhi', 'icon': Icons.location_city, 'coordinates': const LatLng(28.6139, 77.2090)},
      {'name': 'Mumbai', 'icon': Icons.business, 'coordinates': const LatLng(19.0760, 72.8777)},
      {'name': 'Bangalore', 'icon': Icons.computer, 'coordinates': const LatLng(12.9716, 77.5946)},
      {'name': 'Chennai', 'icon': Icons.beach_access, 'coordinates': const LatLng(13.0827, 80.2707)},
      {'name': 'Pune', 'icon': Icons.landscape, 'coordinates': const LatLng(18.5204, 73.8567)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Cities',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularCities.map((city) {
              return InkWell(
                onTap: () {
                  final controller = Get.find<ExploreController>();
                  final coordinates = city['coordinates'] as LatLng;
                  final cityName = city['name'] as String;
                  final result = LocationResult(
                    placeId: 'popular_${cityName.toLowerCase()}',
                    description: '$cityName, India',
                    coordinates: coordinates,
                  );
                  controller.selectLocationResult(result);
                  Get.back();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        city['icon'] as IconData,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        city['name'] as String,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static Widget _buildCurrentLocationOption(ExploreController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () async {
          await controller.recenterToCurrentLocation();
          Get.back();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.my_location,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Use Current Location',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Find properties near your current location',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.blue[600],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildRecentSearches(ExploreController controller) {
    // This could be enhanced to show actual recent searches from storage
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent location searches will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No locations found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a different city or area',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
