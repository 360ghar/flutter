import 'package:get/get.dart';
import '../../../core/utils/controller_helper.dart';
import '../controllers/edit_profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure UserController is available
    ControllerHelper.ensureUserController();
    
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
} 