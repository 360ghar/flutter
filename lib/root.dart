// lib/root.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/controllers/auth_controller.dart';
import 'core/models/auth_status.dart';
import 'core/utils/debug_logger.dart';
import 'features/auth/views/login_view.dart';
import 'features/auth/views/profile_completion_view.dart';
import 'features/auth/controllers/login_controller.dart';
import 'features/auth/controllers/profile_completion_controller.dart';
import 'features/auth/bindings/auth_binding.dart';
import 'features/auth/bindings/profile_completion_binding.dart';
import 'features/dashboard/views/dashboard_view.dart';
import 'features/dashboard/bindings/dashboard_binding.dart';
import 'features/dashboard/controllers/dashboard_controller.dart';
import 'features/splash/views/splash_view.dart';
import 'features/splash/controllers/splash_controller.dart';
import 'widgets/common/error_states.dart';

class Root extends GetView<AuthController> {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentStatus = controller.authStatus.value;
      DebugLogger.info('🏠 Root widget rebuilding with authStatus: $currentStatus');
      
      switch (currentStatus) {
        case AuthStatus.initial:
          DebugLogger.debug('📱 Root: Showing SplashView');
          // Register SplashController if not already registered
          if (!Get.isRegistered<SplashController>()) {
            Get.put<SplashController>(SplashController());
          }
          return const SplashView();
          
        case AuthStatus.unauthenticated:
          DebugLogger.debug('📱 Root: Showing LoginView');
          // Register LoginController if not already registered
          if (!Get.isRegistered<LoginController>()) {
            try {
              AuthBinding().dependencies();
              DebugLogger.success('✅ AuthBinding dependencies registered successfully');
            } catch (e) {
              DebugLogger.error('❌ Failed to register AuthBinding dependencies', e);
            }
          }
          return const LoginView();
          
        case AuthStatus.requiresProfileCompletion:
          DebugLogger.debug('📱 Root: Showing ProfileCompletionView');
          // Register ProfileCompletionController if not already registered
          if (!Get.isRegistered<ProfileCompletionController>()) {
            try {
              ProfileCompletionBinding().dependencies();
              DebugLogger.success('✅ ProfileCompletionController registered successfully');
            } catch (e) {
              DebugLogger.error('❌ Failed to register ProfileCompletionController', e);
              // Fallback: try to recover by going back to login
              DebugLogger.warning('🔄 Fallback: Redirecting to login due to controller registration failure');
              Future.delayed(const Duration(milliseconds: 100), () {
                controller.signOut();
              });
              // Return a temporary loading widget while redirecting
              return const Center(child: CircularProgressIndicator());
            }
          }
          
          
          return const ProfileCompletionView();
          
        case AuthStatus.authenticated:
          DebugLogger.debug('📱 Root: Showing DashboardView');
          // Register DashboardController and all tab controllers if not already registered
          if (!Get.isRegistered<DashboardController>()) {
            try {
              DashboardBinding().dependencies();
              DebugLogger.success('✅ DashboardBinding dependencies registered successfully');
            } catch (e) {
              DebugLogger.error('❌ Failed to register DashboardBinding dependencies', e);
            }
          }
          return const DashboardView();
          
        case AuthStatus.error:
          DebugLogger.debug('📱 Root: Showing error state');
          // User authentication error - show retry/logout options
          return ErrorStates.profileLoadError(
            onRetry: () => controller.retryProfileLoad(),
            onSignOut: () => controller.signOut(),
          );
      }
    });
  }
}
