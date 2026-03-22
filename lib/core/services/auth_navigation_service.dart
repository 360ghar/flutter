import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:ghar360/core/controllers/app_update_controller.dart';
import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/data/models/auth_status.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Service responsible for navigating the user based on auth status changes.
///
/// This separates navigation side-effects from [AuthController], which now
/// only manages reactive auth state. Register this service after
/// [AuthController] in the binding so the worker fires for the initial status.
class AuthNavigationService extends GetxService {
  Worker? _authStatusWorker;

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthController>();
    _authStatusWorker = ever(authController.authStatus, _handleAuthNavigation);
    DebugLogger.info('🧭 AuthNavigationService: listening for auth status changes');
    final initialStatus = authController.authStatus.value;
    DebugLogger.info('🧭 AuthNavigationService: handling initial auth status -> $initialStatus');
    _handleAuthNavigation(initialStatus);
  }

  void _handleAuthNavigation(AuthStatus status) {
    Future.microtask(() {
      DebugLogger.info('🧭 AuthNavigationService: handling auth status -> $status');

      switch (status) {
        case AuthStatus.initial:
          break;

        case AuthStatus.unauthenticated:
          final storage = GetStorage();
          final hasSeenOnboarding = storage.read('has_seen_onboarding') == true;
          if (!hasSeenOnboarding) {
            if (Get.currentRoute != AppRoutes.splash) {
              Get.offAllNamed(AppRoutes.splash);
            }
          } else {
            if (Get.currentRoute != AppRoutes.phoneEntry) {
              Get.offAllNamed(AppRoutes.phoneEntry);
            }
          }
          break;

        case AuthStatus.requiresProfileCompletion:
          if (Get.currentRoute != AppRoutes.profileCompletion) {
            Get.offAllNamed(AppRoutes.profileCompletion);
          }
          break;

        case AuthStatus.authenticated:
          final authController = Get.find<AuthController>();
          if (authController.redirectRoute.value != null) {
            navigateToRedirectRoute();
          } else if (Get.currentRoute != AppRoutes.dashboard) {
            Get.offAllNamed(AppRoutes.dashboard);
            try {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Get.isRegistered<AppUpdateController>()) {
                  Get.find<AppUpdateController>().scheduleCheckAfterFirstFrame();
                }
              });
            } catch (_) {}
          }
          break;

        case AuthStatus.error:
          break;
      }
    });
  }

  /// Navigates to the stored redirect route and clears it.
  void navigateToRedirectRoute() {
    final authController = Get.find<AuthController>();
    final route = authController.redirectRoute.value;
    if (route != null) {
      DebugLogger.info('🔄 Navigating to stored redirect route: ${route.name}');
      Get.offAllNamed(route.name!, arguments: route.arguments);
      authController.redirectRoute.value = null;
    }
  }

  @override
  void onClose() {
    _authStatusWorker?.dispose();
    super.onClose();
  }
}
