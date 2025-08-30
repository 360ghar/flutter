import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/debug_logger.dart';

/// Secure token manager that provides enhanced token storage and management
/// Uses flutter_secure_storage for sensitive data and GetStorage for fallback
class SecureTokenManager {
  static SecureTokenManager? _instance;
  static SecureTokenManager get instance =>
      _instance ??= SecureTokenManager._();

  SecureTokenManager._();

  // Secure storage for sensitive data
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Fallback storage for non-sensitive data
  final _localStorage = GetStorage();

  // Storage keys
  static const String _accessTokenKey = 'secure_access_token';
  static const String _refreshTokenKey = 'secure_refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _sessionValidKey = 'session_valid';

  /// Initialize the token manager
  Future<void> initialize() async {
    try {
      await _localStorage.initStorage;
      DebugLogger.success('SecureTokenManager initialized successfully');
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to initialize SecureTokenManager',
        e,
        stackTrace,
      );
    }
  }

  /// Store authentication session securely
  Future<void> storeSession({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? userId,
    bool rememberMe = false,
  }) async {
    try {
      // Store sensitive tokens in secure storage
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);

      if (refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      }

      // Store metadata in regular storage
      if (expiresAt != null) {
        await _localStorage.write(
          _tokenExpiryKey,
          expiresAt.millisecondsSinceEpoch,
        );
      }

      if (userId != null) {
        await _localStorage.write(_userIdKey, userId);
      }

      await _localStorage.write(_rememberMeKey, rememberMe);
      await _localStorage.write(_sessionValidKey, true);

      DebugLogger.auth('Session stored securely (Remember Me: $rememberMe)');
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to store session', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieve stored access token
  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _accessTokenKey);
      return token;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to retrieve access token', e, stackTrace);
      return null;
    }
  }

  /// Retrieve stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: _refreshTokenKey);
      return token;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to retrieve refresh token', e, stackTrace);
      return null;
    }
  }

  /// Get token expiry date
  DateTime? getTokenExpiry() {
    try {
      final expiry = _localStorage.read(_tokenExpiryKey);
      if (expiry != null) {
        return DateTime.fromMillisecondsSinceEpoch(expiry as int);
      }
      return null;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to get token expiry', e, stackTrace);
      return null;
    }
  }

  /// Get stored user ID
  String? getUserId() {
    try {
      return _localStorage.read(_userIdKey);
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to get user ID', e, stackTrace);
      return null;
    }
  }

  /// Check if user opted for "Remember Me"
  bool getRememberMe() {
    try {
      return _localStorage.read(_rememberMeKey) ?? false;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to get remember me preference', e, stackTrace);
      return false;
    }
  }

  /// Check if stored session is valid
  bool isSessionValid() {
    try {
      final sessionValid = _localStorage.read(_sessionValidKey) ?? false;
      final expiry = getTokenExpiry();

      if (!sessionValid) {
        DebugLogger.warning('Session marked as invalid');
        return false;
      }

      if (expiry != null && DateTime.now().isAfter(expiry)) {
        DebugLogger.warning('Token has expired');
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to check session validity', e, stackTrace);
      return false;
    }
  }

  /// Check if token will expire soon (within next 5 minutes)
  bool isTokenExpiringSoon() {
    try {
      final expiry = getTokenExpiry();
      if (expiry == null) return false;

      final now = DateTime.now();
      final fiveMinutesFromNow = now.add(const Duration(minutes: 5));

      return expiry.isBefore(fiveMinutesFromNow);
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to check token expiry', e, stackTrace);
      return false;
    }
  }

  /// Update session with new Supabase session data
  Future<void> updateFromSupabaseSession(Session session) async {
    try {
      await storeSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        expiresAt: session.expiresAt != null
            ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)
            : null,
        userId: session.user.id,
        rememberMe: getRememberMe(), // Preserve existing preference
      );

      DebugLogger.auth('Session updated from Supabase session');
    } catch (e, stackTrace) {
      DebugLogger.error(
        'Failed to update session from Supabase',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Clear all stored session data
  Future<void> clearSession() async {
    try {
      // Clear secure storage
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);

      // Clear regular storage
      await _localStorage.remove(_tokenExpiryKey);
      await _localStorage.remove(_userIdKey);
      await _localStorage.remove(_sessionValidKey);
      // Note: Keep _rememberMeKey for user preference

      DebugLogger.auth('Session cleared from secure storage');
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to clear session', e, stackTrace);
    }
  }

  /// Mark session as invalid without clearing remember me preference
  Future<void> invalidateSession() async {
    try {
      await _localStorage.write(_sessionValidKey, false);
      DebugLogger.auth('Session marked as invalid');
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to invalidate session', e, stackTrace);
    }
  }

  /// Completely clear all data including user preferences
  Future<void> clearAll() async {
    try {
      // Clear all secure storage
      await _secureStorage.deleteAll();

      // Clear all regular storage
      await _localStorage.erase();

      DebugLogger.auth('All stored data cleared');
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to clear all data', e, stackTrace);
    }
  }

  /// Get session info for debugging
  Future<Map<String, dynamic>> getSessionInfo() async {
    try {
      final hasAccessToken = await getAccessToken() != null;
      final hasRefreshToken = await getRefreshToken() != null;

      return {
        'has_access_token': hasAccessToken,
        'has_refresh_token': hasRefreshToken,
        'token_expiry': getTokenExpiry()?.toIso8601String(),
        'user_id': getUserId(),
        'remember_me': getRememberMe(),
        'session_valid': isSessionValid(),
        'token_expiring_soon': isTokenExpiringSoon(),
      };
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to get session info', e, stackTrace);
      return {'error': e.toString()};
    }
  }

  /// Restore session from Supabase if available
  Future<Session?> restoreSupabaseSession() async {
    try {
      // First check if we have a valid stored session
      if (!isSessionValid()) {
        DebugLogger.warning('No valid stored session found');
        return null;
      }

      // Try to get current session from Supabase
      final supabase = Supabase.instance.client;
      final currentSession = supabase.auth.currentSession;

      if (currentSession != null) {
        // Update our storage with current session
        await updateFromSupabaseSession(currentSession);
        return currentSession;
      }

      // If no current session but we have stored tokens, try to refresh
      final refreshToken = await getRefreshToken();
      if (refreshToken != null) {
        DebugLogger.auth(
          'Attempting to refresh session with stored refresh token',
        );

        try {
          final response = await supabase.auth.refreshSession(refreshToken);
          if (response.session != null) {
            await updateFromSupabaseSession(response.session!);
            return response.session;
          }
        } catch (e) {
          DebugLogger.warning(
            'Failed to refresh session with stored token: $e',
          );
        }
      }

      // If all else fails, mark session as invalid
      await invalidateSession();
      return null;
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to restore Supabase session', e, stackTrace);
      await invalidateSession();
      return null;
    }
  }
}
