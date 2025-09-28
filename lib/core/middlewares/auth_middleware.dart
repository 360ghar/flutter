// lib/core/middlewares/auth_middleware.dart

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/data/models/auth_status.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Safely check if AuthController is registered
    if (!Get.isRegistered<AuthController>()) {
      DebugLogger.warning('AuthController not yet registered, redirecting to login');
      return const RouteSettings(name: AppRoutes.login);
    }

    final authController = Get.find<AuthController>();

    // If the user is authenticated, allow access.
    if (authController.authStatus.value == AuthStatus.authenticated) {
      return null;
    }

    // Store the attempted route for post-login navigation
    if (route != null && route != AppRoutes.login) {
      final attemptedRoute = RouteSettings(name: route, arguments: Get.arguments);
      authController.redirectRoute.value = attemptedRoute;
      DebugLogger.info('🔒 Storing redirect route: $route');
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
