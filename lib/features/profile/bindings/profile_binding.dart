import 'package:get/get.dart';
import '../controllers/edit_profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController (which replaces UserController) is already registered in InitialBinding
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
} 