import 'package:get/get.dart';
import '../controllers/login_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController is already registered globally in InitialBinding
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
