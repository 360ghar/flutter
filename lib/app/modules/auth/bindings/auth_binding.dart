import 'package:get/get.dart';
import '../../../controllers/user_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.find<UserController>();
  }
} 