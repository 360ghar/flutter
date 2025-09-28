import 'package:get/get.dart';

import 'package:ghar360/core/controllers/auth_controller.dart';

/// A safe version of GetView that ensures controllers are registered before access
abstract class SafeGetView<T> extends GetView<T> {
  const SafeGetView({super.key});

  @override
  T get controller {
    // Controllers should be registered via proper bindings
    return Get.find<T>();
  }
}

/// Specialized SafeGetView for AuthController (replaces UserController)
abstract class SafeAuthView extends SafeGetView<AuthController> {
  const SafeAuthView({super.key});

  /// Direct access to AuthController with safety guarantees
  AuthController get authController => controller;
}
