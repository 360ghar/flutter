// lib/features/auth/bindings/phone_entry_binding.dart

import 'package:get/get.dart';

import 'package:ghar360/features/auth/controllers/phone_entry_controller.dart';

class PhoneEntryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PhoneEntryController>(() => PhoneEntryController());
  }
}
