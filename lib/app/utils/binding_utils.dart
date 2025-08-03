import 'package:get/get.dart';
import '../controllers/property_controller.dart';
import '../data/repositories/property_repository.dart';
import '../data/providers/api_provider.dart';

class BindingUtils {
  /// Ensures PropertyController and its dependencies are registered
  static void ensurePropertyController() {
    // Ensure PropertyRepository is available
    if (!Get.isRegistered<PropertyRepository>()) {
      Get.lazyPut<PropertyRepository>(
        () => PropertyRepository(Get.find<IApiProvider>()),
      );
    }
    
    // Ensure PropertyController is available
    if (!Get.isRegistered<PropertyController>()) {
      Get.lazyPut<PropertyController>(
        () => PropertyController(Get.find<PropertyRepository>()),
      );
    }
  }
}