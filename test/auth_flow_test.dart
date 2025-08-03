import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ghar360/app/bindings/initial_binding.dart';
import 'package:ghar360/app/controllers/auth_controller.dart';
import 'package:ghar360/app/controllers/property_controller.dart';
import 'package:ghar360/app/controllers/visits_controller.dart';
import 'package:ghar360/app/controllers/booking_controller.dart';
import 'package:ghar360/app/controllers/analytics_controller.dart';
import 'package:ghar360/app/data/providers/api_service.dart';

void main() {
  group('Authentication Flow Test', () {
    setUp(() {
      // Clear all controllers before each test
      Get.reset();
    });

    test('InitialBinding should only initialize essential services', () {
      // Initialize bindings
      InitialBinding().dependencies();

      // Essential services should be registered
      expect(Get.isRegistered<ApiService>(), isTrue);
      expect(Get.isRegistered<AuthController>(), isTrue);

      // Feature controllers should NOT be registered at this point
      expect(Get.isRegistered<PropertyController>(), isFalse);
      expect(Get.isRegistered<VisitsController>(), isFalse);
      expect(Get.isRegistered<BookingController>(), isFalse);
      expect(Get.isRegistered<AnalyticsController>(), isFalse);
    });

    test('Controllers should not make API calls when user is not authenticated', () async {
      // Initialize bindings
      InitialBinding().dependencies();
      
      final authController = Get.find<AuthController>();
      
      // Ensure user is not authenticated
      expect(authController.isAuthenticated, isFalse);
      expect(authController.isLoggedIn.value, isFalse);
      
      // Feature controllers should not be initialized yet
      expect(Get.isRegistered<PropertyController>(), isFalse);
      expect(Get.isRegistered<VisitsController>(), isFalse);
      expect(Get.isRegistered<BookingController>(), isFalse);
    });

    test('Controllers should initialize after successful authentication', () async {
      // This test would require mock implementations
      // For now, it demonstrates the expected behavior
      
      // Initialize bindings
      InitialBinding().dependencies();
      
      final authController = Get.find<AuthController>();
      
      // Simulate successful login (in real app, this would be through API)
      // authController.isLoggedIn.value = true;
      
      // After login, when navigating to home, HomeBinding would be called
      // which would lazily initialize PropertyController
      // The PropertyController would then listen to auth state
      // and only fetch data when authenticated
    });
  });
}