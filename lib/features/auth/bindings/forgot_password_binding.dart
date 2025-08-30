// lib/features/auth/bindings/forgot_password_binding.dart
import 'package:get/get.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController and AuthRepository are already registered globally in InitialBinding
    Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
  }
}