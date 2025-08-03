import 'dart:async';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/providers/api_service.dart';
import '../data/models/user_model.dart';
import '../routes/app_routes.dart';
import '../utils/debug_logger.dart';
import '../utils/error_handler.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find<AuthController>();

  final _supabase = Supabase.instance.client;
  late final ApiService apiService;

  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;
  final Rxn<User> currentSupabaseUser = Rxn<User>();
  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  final RxString errorMessage = ''.obs;
  

  @override
  void onInit() {
    super.onInit();
    try {
      apiService = Get.find<ApiService>();
      _initializeAuth();
    } catch (e) {
      DebugLogger.error('❌ Error initializing AuthController: $e');
    }
  }


  void _initializeAuth() {
    // Check initial session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      currentSupabaseUser.value = session.user;
      isLoggedIn.value = true;
      _loadUserProfile();
    }

    // Listen to auth changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          if (session?.user != null) {
            currentSupabaseUser.value = session!.user;
            isLoggedIn.value = true;
            errorMessage.value = '';
            _loadUserProfile().then((_) {
              // Only navigate if not already on home screen
              if (Get.currentRoute != AppRoutes.home) {
                Get.offAllNamed(AppRoutes.home);
              }
            });
          }
          break;
        case AuthChangeEvent.signedOut:
          currentSupabaseUser.value = null;
          currentUser.value = null;
          isLoggedIn.value = false;
          // Only navigate to login if not already on auth screens
          if (!_isOnAuthScreen()) {
            Get.offAllNamed(AppRoutes.onboarding);
          }
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (session?.user != null) {
            currentSupabaseUser.value = session!.user;
            // Optionally refresh user profile on token refresh
            _loadUserProfile();
          }
          break;
        default:
          break;
      }
    });
  }


  bool _isOnAuthScreen() {
    final currentRoute = Get.currentRoute;
    return currentRoute == AppRoutes.login ||
           currentRoute == AppRoutes.register ||
           currentRoute == AppRoutes.onboarding ||
           currentRoute == AppRoutes.splash ||
           currentRoute == AppRoutes.profileCompletion;
  }

  Future<void> _loadUserProfile() async {
    try {
      final userProfile = await apiService.getCurrentUser();
      currentUser.value = userProfile;
    } catch (e) {
      DebugLogger.error('Failed to load user profile: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await apiService.signUp(
        email,
        password,
        fullName: fullName,
        phone: phone,
      );

      if (response.user != null) {
        DebugLogger.success('🎉 Signup successful!');
        DebugLogger.user('👤 New User: ${response.user!.email}');
        
        Get.snackbar(
          'Success',
          'Account created successfully! Please check your email to verify your account.',
          snackPosition: SnackPosition.TOP,
        );
        
        // If auto-confirm is enabled, user will be signed in automatically
        // Otherwise, they need to verify their email first
        if (response.session != null) {
          DebugLogger.jwt('🔑 JWT Token: ${response.session!.accessToken}');
          DebugLogger.jwt('⏰ Token expires: ${DateTime.fromMillisecondsSinceEpoch(response.session!.expiresAt! * 1000)}');
          
          currentSupabaseUser.value = response.user;
          isLoggedIn.value = true;
          await _loadUserProfile();
          Get.offAllNamed(AppRoutes.home);
        } else {
          DebugLogger.info('📧 Email verification required');
          Get.toNamed(AppRoutes.login);
        }
        return true;
      } else {
        errorMessage.value = 'Failed to create account';
        return false;
      }
    } catch (e) {
      DebugLogger.error('🔴 Signup error: $e');
      ErrorHandler.handleAuthError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await apiService.signIn(email, password);

      if (response.user != null && response.session != null) {
        // Log JWT Token
        DebugLogger.success('🎉 Login successful!');
        DebugLogger.user('👤 User: ${response.user!.email}');
        DebugLogger.jwt('🔑 JWT Token: ${response.session!.accessToken}');
        DebugLogger.jwt('⏰ Token expires: ${DateTime.fromMillisecondsSinceEpoch(response.session!.expiresAt! * 1000)}');
        
        currentSupabaseUser.value = response.user;
        isLoggedIn.value = true;
        await _loadUserProfile();
        Get.offAllNamed(AppRoutes.home);
        return true;
      } else {
        errorMessage.value = 'Failed to sign in';
        return false;
      }
    } catch (e) {
      DebugLogger.error('🔴 Login error: $e');
      ErrorHandler.handleAuthError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;
      await apiService.signOut();
      
      // The auth state listener will handle the UI updates
    } catch (e) {
      ErrorHandler.handleAuthError(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await apiService.resetPassword(email);
      
      Get.snackbar(
        'Success',
        'Password reset email sent! Please check your inbox.',
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } catch (e) {
      ErrorHandler.handleAuthError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      Get.snackbar(
        'Success',
        'Password updated successfully!',
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } catch (e) {
      ErrorHandler.handleAuthError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      Get.snackbar(
        'Success',
        'Email update requested! Please check both old and new email addresses.',
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } catch (e) {
      ErrorHandler.handleAuthError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshUserProfile() async {
    try {
      await _loadUserProfile();
    } catch (e) {
      DebugLogger.error('Failed to refresh user profile: $e');
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      isLoading.value = true;
      
      final updatedUser = await apiService.updateUserProfile(profileData);
      currentUser.value = updatedUser;
      
      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } catch (e) {
      ErrorHandler.handleNetworkError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await apiService.updateUserPreferences(preferences);
      
      // Update local user object
      final user = currentUser.value;
      if (user != null) {
        currentUser.value = user.copyWith(preferences: preferences);
      }
      
      Get.snackbar(
        'Success',
        'Preferences updated successfully!',
        snackPosition: SnackPosition.TOP,
      );
      return true;
    } catch (e) {
      ErrorHandler.handleNetworkError(e);
      return false;
    }
  }

  Future<bool> updateUserLocation(double latitude, double longitude) async {
    try {
      await apiService.updateUserLocation(latitude, longitude);
      return true;
    } catch (e) {
      DebugLogger.error('Failed to update user location: $e');
      return false;
    }
  }

  // Session management
  Future<bool> checkSessionValidity() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        return false;
      }

      // Check if session is expired
      if (session.expiresAt != null && 
          DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000))) {
        await signOut();
        return false;
      }

      // Validate with backend
      final response = await apiService.checkSession();
      return response['valid'] == true;
    } catch (e) {
      DebugLogger.error('Session validation failed: $e');
      return false;
    }
  }

  Future<void> restoreSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        final isValid = await checkSessionValidity();
        if (isValid) {
          currentSupabaseUser.value = session.user;
          isLoggedIn.value = true;
          await _loadUserProfile();
        } else {
          await signOut();
        }
      }
    } catch (e) {
      DebugLogger.error('Session restoration failed: $e');
      await signOut();
    }
  }

  // Helper methods
  bool get isAuthenticated {
    final loggedIn = isLoggedIn.value;
    final user = currentSupabaseUser.value;
    return loggedIn && user != null;
  }
  
  String? get userEmail {
    final user = currentSupabaseUser.value;
    return user?.email;
  }
  
  String? get userId {
    final user = currentSupabaseUser.value;
    return user?.id;
  }
  
  bool get isEmailVerified {
    final user = currentSupabaseUser.value;
    return user?.emailConfirmedAt != null;
  }

  // Removed custom error handling - using centralized ErrorHandler instead

  void clearError() {
    errorMessage.value = '';
  }

  // Social authentication methods (optional - can be implemented later)
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.360ghar.app://login-callback/',
      );

      return response;
    } catch (e) {
      ErrorHandler.handleAuthError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // For development/testing - remove in production
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      
      // Note: This requires additional backend implementation
      // Supabase doesn't provide direct user deletion from client
      
      Get.snackbar(
        'Info',
        'Account deletion requires contacting support',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      ErrorHandler.handleNetworkError(e);
    } finally {
      isLoading.value = false;
    }
  }
}