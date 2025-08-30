// lib/core/middlewares/auth_middleware.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../models/auth_status.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    
    // If the user is authenticated, allow access.
    if (authController.authStatus.value == AuthStatus.authenticated) {
      return null;
    }
    
    // Otherwise, redirect to the login page.
    return const RouteSettings(name: AppRoutes.login);
  }
}

class GuestMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    // If the user is authenticated, redirect them away from guest-only pages.
    if (authController.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }
    
    // Otherwise, allow access.
    return null;
  }
}