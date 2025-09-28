import 'package:get/get.dart';

import 'package:ghar360/features/auth/controllers/login_controller.dart';
import 'package:ghar360/features/auth/controllers/profile_completion_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already registered globally in InitialBinding
    Get.lazyPut<LoginController>(() => LoginController());

    // Register ProfileCompletionController to ensure it's available when auth flow requires it
    Get.lazyPut<ProfileCompletionController>(() => ProfileCompletionController());
  }
}
