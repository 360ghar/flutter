import 'package:get/get.dart';
import '../controllers/explore_controller.dart';
import '../../../core/utils/debug_logger.dart';

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
