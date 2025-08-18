import 'package:get/get.dart';
import '../../features/property_details/controllers/property_controller.dart';
import '../controllers/auth_controller.dart';

/// A mixin that provides safe access to controllers
mixin ControllerMixin {
  /// Safely get PropertyController (should be registered via proper bindings)
  PropertyController? get safePropertyController {
    return Get.isRegistered<PropertyController>() ? Get.find<PropertyController>() : null;
  }
  
  /// Safely get AuthController (replaces UserController functionality)
  AuthController get safeAuthController {
    return Get.find<AuthController>();
  }
  
  /// Check if PropertyController is registered
  bool get isPropertyControllerRegistered => Get.isRegistered<PropertyController>();
  
  /// Check if AuthController is registered
  bool get isAuthControllerRegistered => Get.isRegistered<AuthController>();
}