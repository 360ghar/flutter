import 'package:get/get.dart';
import '../../../controllers/user_controller.dart';
import '../controllers/edit_profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.find<UserController>();
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
} 