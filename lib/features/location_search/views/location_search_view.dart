import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/location_search_controller.dart';
import '../../../core/utils/theme.dart';
import '../../../core/controllers/location_controller.dart';

class LocationSearchView extends GetView<LocationSearchController> {
  const LocationSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Location'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildCurrentLocationTile(context),
          Expanded(
            child: _buildSuggestionsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search for a city or area...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: controller.clearSearch,
                )
              : const SizedBox.shrink()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        onChanged: controller.onSearchChanged,
      ),
    );
  }

  Widget _buildCurrentLocationTile(BuildContext context) {
    final locationController = Get.find<LocationController>();
    
    return Obx(() {
      if (!locationController.hasLocation) {
        return ListTile(
          leading: const Icon(Icons.my_location, color: AppTheme.primaryColor),
          title: const Text('Use Current Location'),
          subtitle: const Text('Tap to get your current location'),
          onTap: controller.useCurrentLocation,
        );
      }
      
      return ListTile(
        leading: const Icon(Icons.my_location, color: AppTheme.primaryColor),
        title: const Text('Use Current Location'),
        subtitle: Text(
          locationController.currentAddress.value.isNotEmpty
              ? locationController.currentAddress.value
              : 'Location detected',
        ),
        onTap: controller.useCurrentLocation,
      );
    });
  }

  Widget _buildSuggestionsList(BuildContext context) {
    final locationController = Get.find<LocationController>();
    
    return Obx(() {
      if (controller.isLoading.value || locationController.isSearchingPlaces.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
      
      final suggestions = locationController.placeSuggestions;
      
      if (suggestions.isEmpty && controller.searchQuery.value.isNotEmpty) {
        return _buildEmptyState(context);
      }
      
      if (suggestions.isEmpty) {
        return _buildPopularCities(context);
      }
      
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(suggestion.mainText),
            subtitle: suggestion.secondaryText.isNotEmpty
                ? Text(suggestion.secondaryText)
                : null,
            onTap: () => controller.selectPlace(suggestion),
          );
        },
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No locations found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for a different location',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCities(BuildContext context) {
    final popularCities = [
      {'name': 'Mumbai', 'state': 'Maharashtra'},
      {'name': 'Delhi', 'state': 'NCR'},
      {'name': 'Bangalore', 'state': 'Karnataka'},
      {'name': 'Hyderabad', 'state': 'Telangana'},
      {'name': 'Chennai', 'state': 'Tamil Nadu'},
      {'name': 'Kolkata', 'state': 'West Bengal'},
      {'name': 'Pune', 'state': 'Maharashtra'},
      {'name': 'Ahmedabad', 'state': 'Gujarat'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Popular Cities',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: popularCities.length,
            itemBuilder: (context, index) {
              final city = popularCities[index];
              return ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: Text(city['name']!),
                subtitle: Text(city['state']!),
                onTap: () => controller.selectCity(city['name']!, city['state']!),
              );
            },
          ),
        ),
      ],
    );
  }
}