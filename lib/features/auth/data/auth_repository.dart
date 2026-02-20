// lib/features/auth/data/auth_repository.dart

import 'package:get/get.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository extends GetxService {
  final _supabase = Supabase.instance.client;
  static const int _defaultMinTokenTtlSeconds = 45;

  // --- STREAMS & GETTERS ---

  // --- USER EXISTENCE CHECK ---

  /// Check if a user with the given phone number exists in the system.
  /// Queries the users table to determine if the phone is already registered.
  Future<bool> checkUserExists(String phone) async {
    try {
      DebugLogger.auth('Checking if user exists for phone: $phone');

      // Query the users table to check if phone exists
      final response = await _supabase.from('users').select('id').eq('phone', phone).maybeSingle();

      final exists = response != null;
      DebugLogger.auth('User exists check result: $exists');
      return exists;
    } catch (e, stackTrace) {
      DebugLogger.error('Error checking user existence', e, stackTrace);
      rethrow;
    }
  }

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

  /// Waits for a valid access token to become available with robust retries.
  /// Useful immediately after signup/OTP verification where the session may lag.
  Future<String> waitForAccessToken({
    Duration timeout = const Duration(seconds: 8),
    int minTtlSeconds = _defaultMinTokenTtlSeconds,
  }) async {
    final effectiveMinTtlSeconds = minTtlSeconds < 0 ? 0 : minTtlSeconds;
    final deadline = DateTime.now().add(timeout);

    // Check immediately first
    Session? session = _supabase.auth.currentSession;
    if (_hasUsableAccessToken(session, minTtlSeconds: effectiveMinTtlSeconds)) {
      DebugLogger.auth(
        'Access token available immediately (length: ${session!.accessToken.length}, '
        'expiresIn: ${_sessionExpiresInSeconds(session)}s)',
      );
      return session.accessToken;
    }
    final immediateTtl = _sessionExpiresInSeconds(session);
    if (session?.accessToken.isNotEmpty == true) {
      DebugLogger.warning(
        'Access token present but stale/near expiry '
        '(expiresIn: ${immediateTtl ?? 'unknown'}s, '
        'minTtlRequired: ${effectiveMinTtlSeconds}s). Refreshing...',
      );
    }

    int refreshAttempts = 0;
    int pollCount = 0;
    const maxRefreshAttempts = 4;
    while (DateTime.now().isBefore(deadline)) {
      // Attempt periodic refreshes (throttled) to ensure token is ready
      if (refreshAttempts < maxRefreshAttempts) {
        try {
          DebugLogger.auth(
            'Attempting session refresh while waiting for access token (attempt ${refreshAttempts + 1})',
          );
          await _supabase.auth.refreshSession();
        } catch (e) {
          DebugLogger.debug('Session refresh attempt failed: $e');
        }
        refreshAttempts++;
      }
      await Future.delayed(const Duration(milliseconds: 150));
      pollCount++;

      session = _supabase.auth.currentSession;
      if (_hasUsableAccessToken(session, minTtlSeconds: effectiveMinTtlSeconds)) {
        DebugLogger.auth(
          'Access token obtained after $pollCount polls (length: ${session!.accessToken.length}, '
          'expiresIn: ${_sessionExpiresInSeconds(session)}s)',
        );
        return session.accessToken;
      }
    }

    DebugLogger.error(
      'Access token not available or still stale after ${timeout.inSeconds}s '
      'and $pollCount polls',
    );
    throw const AuthException('Access token not available in time');
  }

  bool _hasUsableAccessToken(Session? session, {required int minTtlSeconds}) {
    final token = session?.accessToken;
    if (token == null || token.isEmpty) return false;

    final expiresIn = _sessionExpiresInSeconds(session);
    if (expiresIn == null) {
      // If SDK doesn't expose expiry, treat token as usable and rely on server checks.
      return true;
    }
    return expiresIn > minTtlSeconds;
  }

  int? _sessionExpiresInSeconds(Session? session) {
    final expiresAt = session?.expiresAt;
    if (expiresAt == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt - now;
  }
}
