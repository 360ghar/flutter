import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../controllers/property_controller.dart';
import '../controllers/user_controller.dart';
import '../utils/controller_helper.dart';

/// A safe version of GetView that ensures controllers are registered before access
abstract class SafeGetView<T> extends GetView<T> {
  const SafeGetView({Key? key}) : super(key: key);
  
  @override
  T get controller {
    // Ensure the controller is registered based on its type
    if (T == PropertyController) {
      ControllerHelper.ensurePropertyController();
    } else if (T == UserController) {
      ControllerHelper.ensureUserController();
    }
    
    return Get.find<T>();
  }
}

/// Specialized SafeGetView for PropertyController
abstract class SafePropertyView extends SafeGetView<PropertyController> {
  const SafePropertyView({Key? key}) : super(key: key);
  
  /// Direct access to PropertyController with safety guarantees
  PropertyController get propertyController => controller;
}

/// Specialized SafeGetView for UserController
abstract class SafeUserView extends SafeGetView<UserController> {
  const SafeUserView({Key? key}) : super(key: key);
  
  /// Direct access to UserController with safety guarantees
  UserController get userController => controller;
}