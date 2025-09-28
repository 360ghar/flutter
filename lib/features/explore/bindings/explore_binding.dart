import 'package:get/get.dart';

import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/explore/controllers/explore_controller.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    DebugLogger.info('🔧 ExploreBinding dependencies() called.');

    // Repositories and core services are registered in DashboardBinding

    // Screen controller
    Get.lazyPut<ExploreController>(() => ExploreController());
    DebugLogger.success('✅ ExploreController registered');
  }
}
