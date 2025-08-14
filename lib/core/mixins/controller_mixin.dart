import 'package:get/get.dart';
import '../../features/property_details/controllers/property_controller.dart';
import '../controllers/user_controller.dart';
import '../utils/controller_helper.dart';

/// A mixin that provides safe access to controllers with automatic registration
mixin ControllerMixin {
  /// Safely get PropertyController with automatic registration
  PropertyController get safePropertyController {
    ControllerHelper.ensurePropertyController();
    return Get.find<PropertyController>();
  }
  
  /// Safely get UserController with automatic registration  
  UserController get safeUserController {
    ControllerHelper.ensureUserController();
    return Get.find<UserController>();
  }
  
  /// Check if PropertyController is registered without triggering registration
  bool get isPropertyControllerRegistered => Get.isRegistered<PropertyController>();
  
  /// Check if UserController is registered without triggering registration
  bool get isUserControllerRegistered => Get.isRegistered<UserController>();
}