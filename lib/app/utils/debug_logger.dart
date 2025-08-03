import 'package:flutter_dotenv/flutter_dotenv.dart';

class DebugLogger {
  static bool get isDebugMode => dotenv.env['DEBUG_MODE'] == 'true';
  static bool get shouldLogAPICalls => dotenv.env['LOG_API_CALLS'] == 'true';

  static void info(String message) {
    if (isDebugMode) {
      print('ℹ️ $message');
    }
  }

  static void success(String message) {
    if (isDebugMode) {
      print('✅ $message');
    }
  }

  static void warning(String message) {
    if (isDebugMode) {
      print('⚠️ $message');
    }
  }

  static void error(String message) {
    if (isDebugMode) {
      print('❌ $message');
    }
  }

  static void api(String message) {
    if (shouldLogAPICalls) {
      print('🌐 $message');
    }
  }

  static void auth(String message) {
    if (isDebugMode) {
      print('🔐 $message');
    }
  }

  static void jwt(String message) {
    if (isDebugMode) {
      print('🔑 $message');
    }
  }

  static void user(String message) {
    if (isDebugMode) {
      print('👤 $message');
    }
  }

  static void property(String message) {
    if (isDebugMode) {
      print('🏠 $message');
    }
  }

  static void network(String message) {
    if (shouldLogAPICalls) {
      print('📡 $message');
    }
  }

  static void connection(String message) {
    if (isDebugMode) {
      print('🔌 $message');
    }
  }

  static void init(String message) {
    if (isDebugMode) {
      print('🔧 $message');
    }
  }

  /// Log JWT token details securely (only in debug mode)
  static void logJWTToken(String token, {DateTime? expiresAt, String? userId, String? userEmail}) {
    if (isDebugMode) {
      // Only log first and last few characters for security
      final tokenPreview = token.length > 20 
          ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
          : token;
    }
  }

  /// Log API request details
  static void logAPIRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (shouldLogAPICalls) {
      print('=== API REQUEST ===');
      print('🌐 $method $endpoint');
      if (headers != null) print('📋 Headers: $headers');
      if (body != null) print('📦 Body: $body');
      print('==================');
    }
  }

  /// Log API response details
  static void logAPIResponse({
    required int statusCode,
    required String endpoint,
    dynamic body,
  }) {
    if (shouldLogAPICalls) {
      print('=== API RESPONSE ===');
      print('📨 Status: $statusCode');
      print('🌐 Endpoint: $endpoint');
      if (body != null) print('📦 Body: $body');
      print('====================');
    }
  }
} 