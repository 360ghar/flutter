import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/property_controller.dart';
import '../../../controllers/swipe_controller.dart';
import '../widgets/property_swipe_card.dart';
import '../../../utils/app_colors.dart';
import '../../../../widgets/navigation/bottom_nav_bar.dart';
import '../../../../widgets/common/property_filter_widget.dart';

class HomeView extends GetView<PropertyController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final SwipeController swipeController = Get.find<SwipeController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          '360Ghar',
          style: TextStyle(
            color: AppColors.appBarText,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PropertyFilterWidget(
            pageType: 'home',
            onFiltersApplied: () {
              // Reset the swipe stack to apply new filters
              Get.find<SwipeController>().resetStack();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.loadingIndicator,
            ),
          );
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => controller.fetchProperties(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: PropertySwipeStack(
            properties: swipeController.visibleCards,
            onSwipeLeft: (property) => swipeController.swipeLeft(property),
            onSwipeRight: (property) => swipeController.swipeRight(property),
            onSwipeUp: (property) => swipeController.swipeUp(property),
          ),
        );
      }),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 2),
    );
  }
}
