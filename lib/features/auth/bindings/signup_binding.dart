// lib/features/auth/bindings/signup_binding.dart
import 'package:get/get.dart';
import '../controllers/signup_controller.dart';

class SignUpBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController and AuthRepository are already registered globally in InitialBinding
    Get.lazyPut<SignUpController>(() => SignUpController());
  }
}
