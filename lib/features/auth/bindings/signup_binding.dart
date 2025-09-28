// lib/features/auth/bindings/signup_binding.dart

import 'package:get/get.dart';

import 'package:ghar360/features/auth/controllers/signup_controller.dart';

class SignUpBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController and AuthRepository are already registered globally in InitialBinding
    Get.lazyPut<SignUpController>(() => SignUpController());
  }
}
