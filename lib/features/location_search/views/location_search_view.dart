import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/location_controller.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/features/location_search/controllers/location_search_controller.dart';

class LocationSearchView extends GetView<LocationSearchController> {
  const LocationSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('search_location'.tr),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(context),
          _buildCurrentLocationTile(context),
          Expanded(child: _buildSuggestionsList(context)),
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
            color: AppColors.shadowColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller.searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'search_city_or_area_hint'.tr,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(
            () => controller.searchQuery.value.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: controller.clearSearch)
                : const SizedBox.shrink(),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
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
          leading: const Icon(Icons.my_location, color: AppColors.primaryYellow),
          title: Text('use_current_location'.tr),
          subtitle: Text('tap_to_get_current_location'.tr),
          onTap: controller.useCurrentLocation,
        );
      }

      return ListTile(
        leading: const Icon(Icons.my_location, color: AppColors.primaryYellow),
        title: Text('use_current_location'.tr),
        subtitle: Text(
          locationController.currentAddress.value.isNotEmpty
              ? locationController.currentAddress.value
              : 'location_found'.tr,
        ),
        onTap: controller.useCurrentLocation,
      );
    });
  }

  Widget _buildSuggestionsList(BuildContext context) {
    final locationController = Get.find<LocationController>();

    return Obx(() {
      if (controller.isLoading.value || locationController.isSearchingPlaces.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final suggestions = locationController.placeSuggestions;

      if (suggestions.isEmpty && controller.searchQuery.value.isNotEmpty) {
        return _buildEmptyState(context);
      }

      // If there are no suggestions yet and no query, show a gentle prompt
      if (suggestions.isEmpty) {
        return _buildSearchPrompt(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(suggestion.mainText),
            subtitle: suggestion.secondaryText.isNotEmpty ? Text(suggestion.secondaryText) : null,
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
          Icon(Icons.search_off, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text('no_locations_found'.tr, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('try_search_different_location'.tr, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSearchPrompt(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'search_city_or_area_hint'.tr,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
