import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    try {
      // Get the AuthController instance
      final authController = Get.find<AuthController>();
      
      // Check if user is authenticated
      if (!authController.isAuthenticated) {
        // Check if the current route is a public route that doesn't require auth
        if (route != null && _isPublicRoute(route)) {
          return null; // Allow access to public routes
        }
        
        // Redirect to onboarding for protected routes
        return const RouteSettings(name: AppRoutes.onboarding);
      }
      
      // User is authenticated, allow access
      return null;
    } catch (e) {
      // If AuthController is not found (app not initialized), redirect to splash
      return const RouteSettings(name: AppRoutes.splash);
    }
  }

  /// Checks if a route is public and doesn't require authentication
  bool _isPublicRoute(String route) {
    const publicRoutes = [
      AppRoutes.splash,
      AppRoutes.onboarding,
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.profileCompletion,
      // Add any other public routes here
    ];
    
    return publicRoutes.contains(route);
  }
}

/// Middleware specifically for routes that should redirect authenticated users
/// (e.g., login page should redirect to home if user is already logged in)
class GuestMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    try {
      final authController = Get.find<AuthController>();
      
      // If user is authenticated and trying to access guest-only routes
      if (route != null && authController.isAuthenticated && _isGuestOnlyRoute(route)) {
        return const RouteSettings(name: AppRoutes.discover);
      }
      
      return null;
    } catch (e) {
      // If AuthController is not found, allow access
      return null;
    }
  }

  /// Routes that authenticated users shouldn't access
  bool _isGuestOnlyRoute(String route) {
    const guestOnlyRoutes = [
      AppRoutes.login,
      AppRoutes.register,
      AppRoutes.onboarding,
    ];
    
    return guestOnlyRoutes.contains(route);
  }
}