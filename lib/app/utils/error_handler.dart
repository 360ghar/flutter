import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'debug_logger.dart';

class ErrorHandler {
  static void handleAuthError(dynamic error, {VoidCallback? onRetry}) {
    String message;
    String title = 'Error';
    Color backgroundColor = Colors.red;
    
    if (error is AuthException) {
      title = 'Authentication Error';
      switch (error.message) {
        case 'Invalid login credentials':
          message = 'Invalid email or password. Please check your credentials.';
          break;
        case 'Email not confirmed':
          message = 'Please verify your email address before signing in.';
          break;
        case 'User already registered':
          message = 'An account with this email already exists. Please sign in instead.';
          break;
        case 'Password should be at least 6 characters':
          message = 'Password must be at least 6 characters long.';
          break;
        case 'Invalid email':
          message = 'Please enter a valid email address.';
          break;
        case 'Signup disabled':
          message = 'New user registration is currently disabled.';
          break;
        case 'Email rate limit exceeded':
          message = 'Too many attempts. Please wait before trying again.';
          backgroundColor = Colors.orange;
          break;
        case 'Session not found':
          message = 'Your session has expired. Please sign in again.';
          break;
        default:
          message = error.message;
      }
    } else if (error is Exception) {
      message = error.toString().replaceAll('Exception: ', '');
    } else {
      message = 'An unexpected error occurred. Please try again.';
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      mainButton: onRetry != null
          ? TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  static void handleNetworkError(dynamic error, {VoidCallback? onRetry}) {
    String message;
    
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      message = 'No internet connection. Please check your network and try again.';
    } else if (error.toString().contains('Connection refused')) {
      message = 'Unable to connect to server. Please try again later.';
    } else if (error.toString().contains('401')) {
      message = 'Authentication failed. Please sign in again.';
    } else if (error.toString().contains('403')) {
      message = 'Access denied. Please check your permissions.';
    } else if (error.toString().contains('404')) {
      message = 'Requested resource not found.';
    } else if (error.toString().contains('500')) {
      message = 'Server error. Please try again later.';
    } else {
      message = 'Network error occurred. Please try again.';
    }

    Get.snackbar(
      'Network Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      mainButton: onRetry != null
          ? TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  static void handleValidationError(String field, String message) {
    Get.snackbar(
      'Validation Error',
      '$field: $message',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static void showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static void showInfo(String message) {
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  static Widget buildErrorWidget(String error, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildLoadingWidget({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildEmptyWidget({
    required String title,
    required String message,
    IconData? icon,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ApiErrorHandler {
  static const String _tag = 'ApiErrorHandler';

  /// Handles API errors and provides user-friendly messages and debugging info
  static String handleError(dynamic error, {String? context}) {
    final errorMessage = error.toString();
    
    DebugLogger.error('💥 API Error in ${context ?? 'unknown context'}: $errorMessage');
    
    // Type casting errors
    if (errorMessage.contains('is not a subtype of type')) {
      return _handleTypeCastingError(errorMessage, context);
    }
    
    // Network errors
    if (errorMessage.contains('Connection refused') ||
        errorMessage.contains('Failed host lookup') ||
        errorMessage.contains('SocketException') ||
        errorMessage.contains('NetworkException')) {
      return _handleNetworkError(errorMessage, context);
    }
    
    // HTTP errors
    if (errorMessage.contains('404')) {
      return _handleHttpError(404, context);
    } else if (errorMessage.contains('401')) {
      return _handleHttpError(401, context);
    } else if (errorMessage.contains('403')) {
      return _handleHttpError(403, context);
    } else if (errorMessage.contains('500')) {
      return _handleHttpError(500, context);
    }
    
    // JSON parsing errors
    if (errorMessage.contains('FormatException') ||
        errorMessage.contains('Unexpected character') ||
        errorMessage.contains('Invalid JSON')) {
      return _handleJsonError(errorMessage, context);
    }
    
    // Authentication errors
    if (errorMessage.contains('Invalid email or password') ||
        errorMessage.contains('User not found') ||
        errorMessage.contains('Invalid credentials')) {
      return _handleAuthError(errorMessage, context);
    }
    
    // Generic error
    return _handleGenericError(errorMessage, context);
  }

  static String _handleTypeCastingError(String error, String? context) {
    DebugLogger.warning('🔄 Type casting error detected - Backend data types don\'t match frontend expectations');
    
    if (error.contains("'int' is not a subtype of type 'String'")) {
      DebugLogger.info('💡 Solution: Backend is returning integer where string is expected');
      return 'Data format mismatch - contact support';
    } else if (error.contains("'List<dynamic>' is not a subtype of type 'Map<String, dynamic>'")) {
      DebugLogger.info('💡 Solution: Backend is returning array where object is expected');
      return 'Data structure mismatch - using fallback data';
    } else if (error.contains("'String' is not a subtype of type 'int'")) {
      DebugLogger.info('💡 Solution: Backend is returning string where number is expected');
      return 'Numeric data format issue - using defaults';
    }
    
    return 'Data format error - using fallback data';
  }

  static String _handleNetworkError(String error, String? context) {
    DebugLogger.warning('🔌 Network connectivity issue detected');
    DebugLogger.info('💡 Solutions:');
    DebugLogger.info('   1. Check if backend server is running on http://localhost:8000');
    DebugLogger.info('   2. Verify network connectivity');
    DebugLogger.info('   3. Check firewall settings');
    DebugLogger.info('   4. Using mock data as fallback');
    
    return 'Unable to connect to server - using offline data';
  }

  static String _handleHttpError(int statusCode, String? context) {
    switch (statusCode) {
      case 401:
        DebugLogger.warning('🔐 Authentication error - Invalid or expired token');
        DebugLogger.info('💡 Solution: Re-authenticate user');
        return 'Please log in again';
        
      case 403:
        DebugLogger.warning('🚫 Authorization error - Insufficient permissions');
        DebugLogger.info('💡 Solution: Check user permissions');
        return 'Access denied - insufficient permissions';
        
      case 404:
        DebugLogger.warning('📭 Resource not found');
        DebugLogger.info('💡 Solution: Check API endpoint or resource ID');
        return 'Requested data not found';
        
      case 500:
        DebugLogger.error('💥 Server error - Backend is experiencing issues');
        DebugLogger.info('💡 Solution: Check backend server logs');
        return 'Server error - please try again later';
        
      default:
        DebugLogger.error('❌ HTTP Error $statusCode');
        return 'Server responded with error $statusCode';
    }
  }

  static String _handleJsonError(String error, String? context) {
    DebugLogger.warning('📋 JSON parsing error - Invalid response format');
    DebugLogger.info('💡 Solutions:');
    DebugLogger.info('   1. Check backend response format');
    DebugLogger.info('   2. Verify API endpoint is returning valid JSON');
    DebugLogger.info('   3. Check for HTML error pages in response');
    
    return 'Invalid data format received - using fallback';
  }

  static String _handleAuthError(String error, String? context) {
    DebugLogger.warning('🔑 Authentication failed');
    DebugLogger.info('💡 Solutions:');
    DebugLogger.info('   1. Verify email and password');
    DebugLogger.info('   2. Check if account is verified');
    DebugLogger.info('   3. Reset password if needed');
    
    return 'Authentication failed - please check credentials';
  }

  static String _handleGenericError(String error, String? context) {
    DebugLogger.error('❓ Unhandled error type: $error');
    DebugLogger.info('💡 Using mock data as fallback');
    
    return 'Unexpected error occurred - using offline data';
  }

  /// Logs detailed error information for debugging
  static void logDetailedError({
    required String operation,
    required dynamic error,
    required StackTrace stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    DebugLogger.error('========================');
    DebugLogger.error('💥 DETAILED ERROR LOG');
    DebugLogger.error('========================');
    DebugLogger.error('🔧 Operation: $operation');
    DebugLogger.error('❌ Error: ${error.toString()}');
    DebugLogger.error('📍 Error Type: ${error.runtimeType}');
    
    if (additionalData != null) {
      DebugLogger.error('📊 Additional Data:');
      additionalData.forEach((key, value) {
        DebugLogger.error('   $key: $value');
      });
    }
    
    if (kDebugMode) {
      DebugLogger.error('📚 Stack Trace:');
      DebugLogger.error(stackTrace.toString());
    }
    
    DebugLogger.error('========================');
  }

  /// Checks if error is recoverable (can fallback to mock data)
  static bool isRecoverableError(dynamic error) {
    final errorMessage = error.toString();
    
    // Network errors are recoverable (use mock data)
    if (errorMessage.contains('Connection refused') ||
        errorMessage.contains('Failed host lookup') ||
        errorMessage.contains('SocketException') ||
        errorMessage.contains('NetworkException')) {
      return true;
    }
    
    // Type casting errors are recoverable (data conversion possible)
    if (errorMessage.contains('is not a subtype of type')) {
      return true;
    }
    
    // HTTP errors are mostly recoverable
    if (errorMessage.contains('404') || 
        errorMessage.contains('500') ||
        errorMessage.contains('503')) {
      return true;
    }
    
    // JSON errors might be recoverable
    if (errorMessage.contains('FormatException') ||
        errorMessage.contains('Invalid JSON')) {
      return true;
    }
    
    return false;
  }
}

/// Extension to add error handling to Future operations
extension FutureErrorHandling<T> on Future<T> {
  /// Catches errors and provides fallback with detailed logging
  Future<T> catchWithFallback({
    required String operation,
    required T fallback,
    bool logDetailedError = false,
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      if (logDetailedError) {
        ApiErrorHandler.logDetailedError(
          operation: operation,
          error: error,
          stackTrace: stackTrace,
        );
      }
      
      final userMessage = ApiErrorHandler.handleError(error, context: operation);
      DebugLogger.warning('🔄 Using fallback for $operation: $userMessage');
      
      return fallback;
    }
  }
}