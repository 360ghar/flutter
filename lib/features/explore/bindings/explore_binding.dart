import 'package:get/get.dart';
import '../controllers/explore_controller.dart';
import '../../../core/data/repositories/properties_repository.dart';
import '../../../core/utils/debug_logger.dart';

class ExploreBinding extends Bindings {
  @override
  void dependencies() {
    DebugLogger.info('🔧 ExploreBinding dependencies() called.');
    
    // Repositories (ApiService already registered in InitialBinding)
    if (!Get.isRegistered<PropertiesRepository>()) {
      Get.lazyPut<PropertiesRepository>(() => PropertiesRepository(), fenix: true);
      DebugLogger.success('✅ PropertiesRepository registered');
    } else {
      DebugLogger.info('ℹ️ PropertiesRepository already registered');
    }
    
    // LocationController and FilterService are already registered globally in InitialBinding
    
    // Screen controller
    Get.lazyPut<ExploreController>(() => ExploreController());
    DebugLogger.success('✅ ExploreController registered');
  }
}