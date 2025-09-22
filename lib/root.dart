// lib/root.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/controllers/auth_controller.dart';
import 'package:ghar360/core/data/models/auth_status.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/widgets/common/error_states.dart';

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      final currentStatus = authController.authStatus.value;
      DebugLogger.info('🏠 Root widget rebuilding with authStatus: $currentStatus');

      switch (currentStatus) {
        case AuthStatus.initial:
        case AuthStatus.unauthenticated:
        case AuthStatus.requiresProfileCompletion:
        case AuthStatus.authenticated:
          // For all normal states, show a loading indicator while navigation worker handles routing
          // Navigation is now handled by the AuthController navigation worker, not in build method
          DebugLogger.debug('📱 Root: Showing loading state for $currentStatus');
          return const Scaffold(body: Center(child: CircularProgressIndicator()));

        case AuthStatus.error:
          DebugLogger.debug('📱 Root: Showing error state');
          // User authentication error - show retry/logout options
          return ErrorStates.profileLoadError(
            onRetry: () => authController.retryProfileLoad(),
            onSignOut: () => authController.signOut(),
          );
      }
    });
  }
}
