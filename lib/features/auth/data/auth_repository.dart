// lib/features/auth/data/auth_repository.dart

import 'package:get/get.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository extends GetxService {
  final _supabase = Supabase.instance.client;

  // --- STREAMS & GETTERS ---

  /// Stream of user authentication state changes from Supabase.
  Stream<User?> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange.map((data) => data.session?.user);

  /// The current logged-in Supabase user.
  User? get currentUser => _supabase.auth.currentUser;

  /// The current active session, containing the JWT access token.
  Session? get currentSession => _supabase.auth.currentSession;

  // --- AUTHENTICATION METHODS ---

  /// Signs up a new user with a phone number and password.
  /// Supabase will automatically send an OTP for verification.
  Future<AuthResponse> signUpWithPhonePassword(
    String phone,
    String password, {
    Map<String, dynamic>? data,
  }) {
    DebugLogger.auth('Attempting to sign up with phone: $phone');
    return _supabase.auth.signUp(phone: phone, password: password, data: data);
  }

  /// Signs in an existing user with their phone number and password.
  Future<AuthResponse> signInWithPhonePassword(String phone, String password) {
    DebugLogger.auth('Attempting to sign in with phone: $phone');
    return _supabase.auth.signInWithPassword(phone: phone, password: password);
  }

  /// Verifies the OTP sent to the user's phone to complete sign-up or sign-in.
  Future<AuthResponse> verifyPhoneOtp({required String phone, required String token}) {
    DebugLogger.auth('Verifying OTP for phone: $phone');
    return _supabase.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  }

  /// Sends a one-time password (OTP) to a phone for password reset or login.
  Future<void> sendPhoneOtp(String phone) {
    DebugLogger.auth('Sending password reset OTP to phone: $phone');
    return _supabase.auth.signInWithOtp(phone: phone);
  }

  /// Updates the current user's password. Requires the user to be logged in.
  Future<User> updateUserPassword(String newPassword) async {
    DebugLogger.auth('Updating user password.');
    final response = await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    if (response.user == null) {
      throw const AuthException('Failed to update password. User not found.');
    }
    return response.user!;
  }

  /// Signs out the current user and invalidates their session.
  Future<void> signOut() {
    DebugLogger.auth('Signing out user.');
    return _supabase.auth.signOut();
  }

  /// Waits for a valid access token to become available.
  /// Tries a session refresh once if needed to avoid race conditions after OTP verification.
  Future<String> waitForAccessToken({Duration timeout = const Duration(seconds: 2)}) async {
    final deadline = DateTime.now().add(timeout);
    Session? session = _supabase.auth.currentSession;
    if (session?.accessToken.isNotEmpty == true) {
      return session!.accessToken;
    }

    bool refreshed = false;
    while (DateTime.now().isBefore(deadline)) {
      // Try a single refresh early in the wait window
      if (!refreshed) {
        try {
          DebugLogger.auth('Attempting session refresh while waiting for access token');
          await _supabase.auth.refreshSession();
        } catch (_) {}
        refreshed = true;
      }
      await Future.delayed(const Duration(milliseconds: 50));
      session = _supabase.auth.currentSession;
      if (session?.accessToken.isNotEmpty == true) {
        return session!.accessToken;
      }
    }
    throw const AuthException('Access token not available in time');
  }
}
