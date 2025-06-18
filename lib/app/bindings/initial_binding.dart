import 'package:get/get.dart';
import '../data/providers/api_provider.dart';
import '../data/repositories/property_repository.dart';
import '../data/repositories/user_repository.dart';
import '../controllers/property_controller.dart';
import '../controllers/user_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register API Provider
    Get.put<IApiProvider>(MockApiProvider());

    // Register Repositories
    Get.put<PropertyRepository>(
      PropertyRepository(Get.find<IApiProvider>()),
    );
    Get.put<UserRepository>(
      UserRepository(Get.find<IApiProvider>()),
    );

    // Register Controllers
    Get.put<PropertyController>(
      PropertyController(Get.find<PropertyRepository>()),
    );
    Get.put<UserController>(
      UserController(Get.find<UserRepository>()),
    );
  }
} 