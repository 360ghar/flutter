import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides authentication headers for API requests.
class AuthHeaderProvider {
  /// Gets the current auth header if user is authenticated.
  Future<Map<String, String>?> getAuthHeader() async {
    try {
      // Get token directly from Supabase session
      final session = Supabase.instance.client.auth.currentSession;
      final token = session?.accessToken;

      if (token == null || token.isEmpty) {
        return null;
      }

      return {'Authorization': 'Bearer $token'};
    } catch (e) {
      DebugLogger.warning('Failed to get auth header: $e');
      return null;
    }
  }
}
