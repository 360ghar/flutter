import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';

class DebugLogger {
  static late final Logger _logger;
  static bool _initialized = false;

  static bool get isDebugMode {
    try {
      return dotenv.env['DEBUG_MODE'] == 'true';
    } catch (e) {
      return kDebugMode; // Fallback to Flutter's debug mode
    }
  }
  
  static bool get shouldLogAPICalls {
    try {
      return dotenv.env['LOG_API_CALLS'] == 'true';
    } catch (e) {
      return false; // Default to no API call logging
    }
  }

  /// Initialize the logger with appropriate configuration
  static void initialize() {
    if (_initialized) return;

    _logger = Logger(
      filter: _LoggerFilter(),
      printer: kDebugMode ? PrettyPrinter(
        stackTraceBeginIndex: 0,
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ) : SimplePrinter(),
      output: ConsoleOutput(),
    );
    _initialized = true;
  }

  /// Verbose level - Most detailed logs (only in verbose debug mode)
  static void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Debug level - Development debugging info (removed in production)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info level - General information about app state
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i('ℹ️ $message', error: error, stackTrace: stackTrace);
  }

  /// Success level - Successful operations
  static void success(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i('✅ $message', error: error, stackTrace: stackTrace);
  }

  /// Warning level - Important issues that don't stop execution
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.w('⚠️ $message', error: error, stackTrace: stackTrace);
  }

  /// Error level - Errors and exceptions
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.e('❌ $message', error: error, stackTrace: stackTrace);
  }

  /// WTF level - What a Terrible Failure - Should never happen
  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.f('💥 $message', error: error, stackTrace: stackTrace);
  }

  // Categorized logging methods
  
  /// API related logs
  static void api(String message, [dynamic error, StackTrace? stackTrace]) {
    if (shouldLogAPICalls) {
      _ensureInitialized();
      _logger.d('🌐 $message', error: error, stackTrace: stackTrace);
    }
  }

  /// Authentication related logs
  static void auth(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i('🔐 $message', error: error, stackTrace: stackTrace);
  }

  /// JWT token related logs
  static void jwt(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i('🔑 $message', error: error, stackTrace: stackTrace);
  }

  /// User related logs
  static void user(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i('👤 $message', error: error, stackTrace: stackTrace);
  }

  /// Property related logs
  static void property(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i('🏠 $message', error: error, stackTrace: stackTrace);
  }

  /// Network related logs
  static void network(String message, [dynamic error, StackTrace? stackTrace]) {
    if (shouldLogAPICalls) {
      _ensureInitialized();
      _logger.d('📡 $message', error: error, stackTrace: stackTrace);
    }
  }

  /// Connection related logs
  static void connection(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i('🔌 $message', error: error, stackTrace: stackTrace);
  }

  /// Initialization related logs
  static void startup(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i('🔧 $message', error: error, stackTrace: stackTrace);
  }

  /// Log JWT token details securely (only in debug mode)
  static void logJWTToken(String token, {DateTime? expiresAt, String? userId, String? userEmail}) {
    if (!isDebugMode) return;
    
    _ensureInitialized();
    
    // Only log first and last few characters for security
    final tokenPreview = token.length > 20 
        ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
        : token;
    
    String message = '🔑 JWT Token: $tokenPreview';
    if (expiresAt != null) message += '\n   Expires: $expiresAt';
    if (userId != null) message += '\n   User ID: $userId';
    if (userEmail != null) message += '\n   Email: $userEmail';
    
    _logger.d(message);
  }

  /// Log API request details
  static void logAPIRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!shouldLogAPICalls) return;
    
    _ensureInitialized();
    
    StringBuffer message = StringBuffer('🌐 API REQUEST\n');
    message.write('   $method $endpoint\n');
    if (headers != null && headers.isNotEmpty) {
      message.write('   Headers: $headers\n');
    }
    if (body != null) {
      message.write('   Body: ${_sanitizeBody(body)}');
    }
    
    _logger.d(message.toString().trim());
  }

  /// Log API response details
  static void logAPIResponse({
    required int statusCode,
    required String endpoint,
    dynamic body,
    int? responseTime,
  }) {
    if (!shouldLogAPICalls) return;
    
    _ensureInitialized();
    
    StringBuffer message = StringBuffer('📨 API RESPONSE\n');
    message.write('   Status: $statusCode\n');
    message.write('   Endpoint: $endpoint\n');
    if (responseTime != null) {
      message.write('   Time: ${responseTime}ms\n');
    }
    if (body != null) {
      message.write('   Body: ${_sanitizeBody(body)}');
    }
    
    if (statusCode >= 200 && statusCode < 300) {
      _logger.i(message.toString().trim());
    } else if (statusCode >= 400) {
      _logger.w(message.toString().trim());
    } else {
      _logger.d(message.toString().trim());
    }
  }

  /// Log detailed error information for debugging
  static void logDetailedError({
    required String operation,
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    _ensureInitialized();
    
    StringBuffer message = StringBuffer('💥 DETAILED ERROR\n');
    message.write('   Operation: $operation\n');
    message.write('   Error: ${error.toString()}\n');
    message.write('   Type: ${error.runtimeType}');
    
    if (additionalData != null && additionalData.isNotEmpty) {
      message.write('\n   Additional Data:');
      additionalData.forEach((key, value) {
        message.write('\n     $key: $value');
      });
    }
    
    _logger.e(message.toString(), error: error, stackTrace: stackTrace);
  }

  /// Sanitize sensitive data from logs
  static dynamic _sanitizeBody(dynamic body) {
    if (body is String) {
      // Remove potential passwords, tokens, etc.
      return body.replaceAllMapped(
        RegExp(r'"(password|token|key|secret)":\s*"[^"]*"', caseSensitive: false),
        (match) => '"${match.group(1)}": "***HIDDEN***"'
      );
    }
    return body;
  }

  /// Ensure logger is initialized
  static void _ensureInitialized() {
    if (!_initialized) {
      initialize();
    }
  }
}

/// Custom filter for controlling log levels based on environment
class _LoggerFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only show warnings and errors
    if (kReleaseMode) {
      return event.level.value >= Level.warning.value;
    }
    
    // In debug mode, show based on DEBUG_MODE setting
    if (!DebugLogger.isDebugMode) {
      return event.level.value >= Level.info.value;
    }
    
    // In verbose debug mode, show everything
    return true;
  }
}