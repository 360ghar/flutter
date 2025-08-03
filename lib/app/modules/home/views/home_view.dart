import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/swipe_controller.dart';
import '../../../widgets/safe_get_view.dart';
import '../widgets/property_swipe_card.dart';
import '../../../utils/app_colors.dart';
import '../../../../widgets/common/property_filter_widget.dart';

class HomeView extends SafePropertyView {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure SwipeController is available
    final SwipeController swipeController = Get.find<SwipeController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'app_name'.tr,
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
        if (propertyController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.loadingIndicator,
            ),
          );
        }

        if (propertyController.error.value.isNotEmpty) {
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
                  'error'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => propertyController.fetchProperties(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: AppColors.buttonText,
                  ),
                  child: Text('retry'.tr),
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
    );
  }
}
