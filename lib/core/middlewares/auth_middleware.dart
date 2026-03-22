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
      DebugLogger.warning('AuthController not yet registered, redirecting to phone entry');
      return const RouteSettings(name: AppRoutes.phoneEntry);
    }

    final authController = Get.find<AuthController>();
    final currentStatus = authController.authStatus.value;

    // If the user is fully authenticated, allow access.
    if (currentStatus == AuthStatus.authenticated) {
      return null;
    }

    // If the user needs to complete their profile, redirect to profile completion
    // unless they're already on that route.
    if (currentStatus == AuthStatus.requiresProfileCompletion) {
      if (route == AppRoutes.profileCompletion) {
        return null; // Already on profile completion page
      }
      DebugLogger.info('🔒 User requires profile completion, redirecting from $route');
      return const RouteSettings(name: AppRoutes.profileCompletion);
    }

    // Store the attempted route for post-login navigation
    if (route != null && route != AppRoutes.phoneEntry) {
      final attemptedRoute = RouteSettings(name: route, arguments: Get.arguments);
      authController.redirectRoute.value = attemptedRoute;
      DebugLogger.info('🔒 Storing redirect route: $route');
    }

    // Otherwise, redirect to phone entry.
    return const RouteSettings(name: AppRoutes.phoneEntry);
  }
}

class GuestMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    // Safely check if AuthController is registered
    if (!Get.isRegistered<AuthController>()) {
      // Not yet registered - allow access to guest routes
      return null;
    }

    final authController = Get.find<AuthController>();

    // If the user is authenticated, redirect them away from guest-only pages.
    if (authController.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.dashboard);
    }

    // Otherwise, allow access.
    return null;
  }
}
