// lib/core/controllers/auth_controller.dart

import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ghar360/core/controllers/app_update_controller.dart';
import 'package:ghar360/core/data/models/auth_status.dart';
import 'package:ghar360/core/data/models/user_model.dart';
import 'package:ghar360/core/data/repositories/profile_repository.dart';
import 'package:ghar360/core/firebase/analytics_service.dart';
import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_handler.dart';
import 'package:ghar360/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends GetxController {
  // Dependencies (Lazy loaded to avoid circular dependency issues)
  final AuthRepository _authRepository = Get.find();
  // Using lazy getter for repositories with error handling
  ProfileRepository? get _profileRepository {
    try {
      return Get.find<ProfileRepository>();
    } catch (e) {
      DebugLogger.warning('ProfileRepository not yet registered: $e');
      return null;
    }
  }

  // --- Reactive State ---
  final Rx<AuthStatus> authStatus = AuthStatus.initial.obs;
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final Rxn<RouteSettings> redirectRoute = Rxn<RouteSettings>();
  final RxInt _profileCompletionPercentage = 0.obs;

  StreamSubscription<User?>? _authSubscription;
  Timer? _debounceTimer;
  User? _lastProcessedUser;
  Worker? _authStatusWorker;
  Worker? _currentUserWorker;

  @override
  void onInit() {
    super.onInit();
    // Set up navigation worker BEFORE initializing so initial state changes trigger navigation
    _setupNavigationWorker();
    _setupCurrentUserWorker();
    _initialize();
  }

  /// Initialize the controller and listen to auth state changes.
  void _initialize() {
    // Listen to the stream from the repository
    _authSubscription = _authRepository.onAuthStateChange.listen(_onAuthStateChanged);
    DebugLogger.auth('AuthController initialized and listening for auth changes.');

    // Perform an initial check in case the stream has already emitted a value
    final initialUser = _authRepository.currentUser;
    if (initialUser != null) {
      _onAuthStateChanged(initialUser);
    } else {
      authStatus.value = AuthStatus.unauthenticated;
    }
  }

  /// Sets up the navigation worker to handle route changes based on auth status changes
  void _setupNavigationWorker() {
    _authStatusWorker = ever(authStatus, _handleAuthNavigation);
    DebugLogger.info('🧭 Navigation worker set up to listen for auth status changes');
  }

  /// Sets up the current user worker to update profile completion percentage
  void _setupCurrentUserWorker() {
    _currentUserWorker = ever(currentUser, (UserModel? user) {
      _profileCompletionPercentage.value = user?.profileCompletionPercentage ?? 0;
    });
    DebugLogger.info('👤 Current user worker set up to update profile completion percentage');
  }

  /// Handles navigation based on auth status changes
  /// This is called outside of the build cycle to prevent build-time navigation issues
  void _handleAuthNavigation(AuthStatus status) {
    // Add a small delay to ensure UI is not in a build phase and to prevent race conditions
    Future.microtask(() {
      DebugLogger.info('🧭 Navigation worker: Handling auth status change to $status');

      switch (status) {
        case AuthStatus.initial:
          // Do nothing on initial; wait for resolved auth state
          DebugLogger.debug('⏳ AuthStatus.initial - waiting for resolved auth state');
          break;

        case AuthStatus.unauthenticated:
          // Gate splash/onboarding with persisted flag
          final storage = GetStorage();
          final hasSeenOnboarding = storage.read('has_seen_onboarding') == true;
          if (!hasSeenOnboarding) {
            if (Get.currentRoute != AppRoutes.splash) {
              DebugLogger.debug('📱 Navigation worker: Navigating to Splash (first run)');
              Get.offAllNamed(AppRoutes.splash);
            }
          } else {
            if (Get.currentRoute != AppRoutes.phoneEntry) {
              DebugLogger.debug('📱 Navigation worker: Navigating to Phone Entry');
              Get.offAllNamed(AppRoutes.phoneEntry);
            }
          }
          break;

        case AuthStatus.requiresProfileCompletion:
          if (Get.currentRoute != AppRoutes.profileCompletion) {
            DebugLogger.debug('📱 Navigation worker: Navigating to Profile Completion route');
            Get.offAllNamed(AppRoutes.profileCompletion);
          }
          break;

        case AuthStatus.authenticated:
          // Check if there's a stored redirect route
          if (redirectRoute.value != null) {
            DebugLogger.debug(
              '📱 Navigation worker: Navigating to stored redirect route: ${redirectRoute.value!.name}',
            );
            navigateToRedirectRoute();
          } else if (Get.currentRoute != AppRoutes.dashboard) {
            DebugLogger.debug('📱 Navigation worker: Navigating to Dashboard route');
            Get.offAllNamed(AppRoutes.dashboard);
            // Defer app update check to post-frame, only after user is active
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
          // Error state doesn't trigger navigation - it's handled by UI display
          DebugLogger.debug('📱 Navigation worker: Auth error state - no navigation needed');
          break;
      }
    });
  }

  /// Callback triggered when Supabase auth state changes (sign-in, sign-out, token refresh).
  /// Uses debouncing to prevent duplicate processing.
  Future<void> _onAuthStateChanged(User? supabaseUser) async {
    // Cancel any existing debounce timer
    _debounceTimer?.cancel();

    // Debounce rapid auth state changes to prevent duplicate processing
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      _processAuthStateChange(supabaseUser);
    });
  }

  /// Process the actual auth state change after debouncing
  Future<void> _processAuthStateChange(User? supabaseUser) async {
    // Skip if we've already processed this user
    if (_lastProcessedUser?.id == supabaseUser?.id && _lastProcessedUser?.id != null) {
      DebugLogger.debug('Skipping duplicate auth state change for user: ${supabaseUser?.id}');
      return;
    }

    _lastProcessedUser = supabaseUser;

    if (supabaseUser == null) {
      // --- USER IS SIGNED OUT ---
      DebugLogger.auth('Auth state changed: User is signed out.');
      currentUser.value = null;
      authStatus.value = AuthStatus.unauthenticated;
      // Clear analytics/Crashlytics user context
      try {
        await AnalyticsService.setUserId(null);
        await FirebaseCrashlytics.instance.setUserIdentifier('');
      } catch (_) {}
    } else {
      // --- USER IS SIGNED IN ---
      DebugLogger.auth('Auth state changed: User is signed in. UID: ${supabaseUser.id}');
      // Set analytics/Crashlytics user context
      try {
        await AnalyticsService.setUserId(supabaseUser.id);
        await FirebaseCrashlytics.instance.setUserIdentifier(supabaseUser.id);
      } catch (_) {}
      // Ensure access token is available before calling our backend (block until ready)
      await _ensureTokenThenLoadProfile();
    }
  }

  Future<void> _ensureTokenThenLoadProfile({int retries = 5}) async {
    try {
      await _authRepository.waitForAccessToken(timeout: const Duration(seconds: 3));
      await _loadUserProfile();
    } catch (e) {
      if (retries > 0) {
        DebugLogger.warning('Access token not ready yet, retrying... ($retries)');
        await Future.delayed(const Duration(seconds: 1));
        await _ensureTokenThenLoadProfile(retries: retries - 1);
      } else {
        DebugLogger.error('Failed to obtain access token after retries.');
        // Surface an error state that allows retry or sign-out
        authStatus.value = AuthStatus.error;
      }
    }
  }

  /// Fetches the user profile from our backend and updates the app's auth status.
  /// Adds a bounded retry when `ProfileRepository` is not yet registered to avoid infinite loops.
  Future<void> _loadUserProfile({int retryCount = 0}) async {
    try {
      // Check if ProfileRepository is available
      final profileRepo = _profileRepository;
      if (profileRepo == null) {
        if (retryCount >= 5) {
          DebugLogger.error('Failed to load user profile after 5 retries. Setting state to error.');
          authStatus.value = AuthStatus.error;
          return;
        }

        DebugLogger.warning(
          'ProfileRepository not available, retrying in 1 second... (Attempt ${retryCount + 1})',
        );
        await Future.delayed(const Duration(seconds: 1));
        return _loadUserProfile(retryCount: retryCount + 1); // Retry with limit
      }

      // Use ProfileRepository to fetch user data from your backend
      final userProfile = await profileRepo.getCurrentUserProfile();
      currentUser.value = userProfile;
      DebugLogger.success('Successfully loaded user profile: ${userProfile.fullName}');

      // Determine the final auth status based on profile completeness
      final newStatus = userProfile.isProfileComplete
          ? AuthStatus.authenticated
          : AuthStatus.requiresProfileCompletion;

      // Only update if status actually changed to prevent unnecessary rebuilds
      if (authStatus.value != newStatus) {
        DebugLogger.auth('Changing auth status from ${authStatus.value} to $newStatus');
        authStatus.value = newStatus;

        if (newStatus == AuthStatus.authenticated) {
          DebugLogger.auth('User is fully authenticated and profile is complete.');
        } else {
          DebugLogger.auth('User authenticated, but profile completion is required.');
          // Force a UI rebuild to ensure navigation happens
          Future.delayed(const Duration(milliseconds: 50), () {
            authStatus.refresh();
          });
        }
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to load user profile after sign-in.', e, stackTrace);

      // If we already have a user and were authenticated, treat this as a transient refresh failure.
      // Do not knock the app into an error state; keep current auth status.
      if (currentUser.value != null && authStatus.value == AuthStatus.authenticated) {
        DebugLogger.warning('Transient profile refresh failure; preserving authenticated state.');
        try {
          if (Get.context != null) {
            ErrorHandler.showInfo('Could not refresh profile. Will retry later.');
          }
        } catch (_) {}
        return;
      }

      // Otherwise, this is initial load failure; set error state so user can retry or sign out.
      authStatus.value = AuthStatus.error;

      try {
        if (Get.context != null) {
          ErrorHandler.showInfo('Could not retrieve your profile. Please try again.');
        } else {
          DebugLogger.warning('Cannot show snackbar: GetX context not available');
        }
      } catch (snackbarError) {
        DebugLogger.error('Failed to show error snackbar', snackbarError);
      }
    }
  }

  /// Signs out the user from Supabase. The `_onAuthStateChanged` listener will handle the rest.
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await _authRepository.signOut();
      // The listener will automatically set the state to unauthenticated and navigation worker will handle routing
    } catch (e) {
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Allows the UI to retry loading the profile if it fails.
  Future<void> retryProfileLoad() async {
    if (authStatus.value == AuthStatus.error) {
      DebugLogger.info('Retrying user profile load...');
      await _loadUserProfile();
    }
  }

  /// Updates the user profile and refreshes the auth state.
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      isLoading.value = true;
      final profileRepo = _profileRepository;
      if (profileRepo == null) {
        DebugLogger.error('ProfileRepository not available for profile update');
        return false;
      }

      final updatedUser = await profileRepo.updateUserProfile(profileData);
      currentUser.value = updatedUser;

      // Debug profile completion check
      DebugLogger.info('🔍 Profile completion check:');
      DebugLogger.info('  - Email: "${updatedUser.email}" (isEmpty: ${updatedUser.email.isEmpty})');
      DebugLogger.info(
        '  - Full Name: "${updatedUser.fullName}" (null/empty: ${updatedUser.fullName == null || updatedUser.fullName!.isEmpty})',
      );
      DebugLogger.info(
        '  - Date of Birth: "${updatedUser.dateOfBirth}" (null/empty: ${updatedUser.dateOfBirth == null || updatedUser.dateOfBirth!.isEmpty})',
      );
      DebugLogger.info('  - isProfileComplete: ${updatedUser.isProfileComplete}');
      DebugLogger.info('  - Current auth status: ${authStatus.value}');

      // After updating, re-evaluate the auth status.
      if (updatedUser.isProfileComplete &&
          authStatus.value == AuthStatus.requiresProfileCompletion) {
        DebugLogger.success('✅ Profile is complete! Changing auth status to authenticated');
        authStatus.value = AuthStatus.authenticated;
      } else if (!updatedUser.isProfileComplete) {
        DebugLogger.warning('⚠️ Profile is still incomplete after update');
      } else if (authStatus.value != AuthStatus.requiresProfileCompletion) {
        DebugLogger.info(
          'ℹ️ Auth status is not requiresProfileCompletion, current: ${authStatus.value}',
        );
      }

      Get.snackbar('Success', 'Profile updated successfully!', snackPosition: SnackPosition.TOP);
      return true;
    } catch (e) {
      ErrorHandler.handleNetworkError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Updates the user's location using ProfileRepository
  Future<bool> updateUserLocation(Map<String, dynamic> locationData) async {
    try {
      final profileRepo = _profileRepository;
      if (profileRepo == null) {
        DebugLogger.error('ProfileRepository not available for location update');
        return false;
      }

      final updatedUser = await profileRepo.updateUserLocation(locationData);
      currentUser.value = updatedUser;
      return true;
    } catch (e) {
      DebugLogger.error('Failed to update user location', e);
      return false;
    }
  }

  /// Updates the user's preferences using ProfileRepository
  Future<bool> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final profileRepo = _profileRepository;
      if (profileRepo == null) {
        DebugLogger.error('ProfileRepository not available for preferences update');
        return false;
      }

      final updatedUser = await profileRepo.updateUserPreferences(preferences);
      currentUser.value = updatedUser;
      return true;
    } catch (e) {
      DebugLogger.error('Failed to update user preferences', e);
      return false;
    }
  }

  /// Navigates to the stored redirect route after successful authentication
  void navigateToRedirectRoute() {
    final route = redirectRoute.value;
    if (route != null) {
      DebugLogger.info('🔄 Navigating to stored redirect route: ${route.name}');
      Get.offAllNamed(route.name!, arguments: route.arguments);
      // Clear the stored route after navigation
      redirectRoute.value = null;
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _debounceTimer?.cancel();
    _authStatusWorker?.dispose();
    _currentUserWorker?.dispose();
    super.onClose();
  }

  // Convenience Getters
  bool get isAuthenticated => authStatus.value == AuthStatus.authenticated;
  String? get userEmail => currentUser.value?.email;
  String? get userId => _authRepository.currentUser?.id;
  RxInt get profileCompletionPercentage => _profileCompletionPercentage;
}
