import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/property_controller.dart';
import '../../../controllers/swipe_controller.dart';
import '../widgets/property_swipe_card.dart';
import '../../../utils/theme.dart';
import '../../../../widgets/navigation/bottom_nav_bar.dart';
import '../../../../widgets/common/property_filter_widget.dart';

class HomeView extends GetView<PropertyController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final SwipeController swipeController = Get.find<SwipeController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '360Ghar',
          style: TextStyle(
            color: Colors.black,
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
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryYellow,
            ),
          );
        }

        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => controller.fetchProperties(),
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
