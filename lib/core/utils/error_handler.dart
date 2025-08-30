import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'debug_logger.dart';

class ErrorHandler {
  static void handleAuthError(dynamic error, {VoidCallback? onRetry, StackTrace? stackTrace}) {
    // Enhanced error logging with stack trace preservation
    DebugLogger.logDetailedError(
      operation: 'handleAuthError',
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      additionalData: {'hasRetryCallback': onRetry != null},
    );

    String message;
    String title = 'Error';
    Color backgroundColor = Colors.red;

    if (error is AuthException) {
      title = 'Authentication Error';
      final msg = error.message;
      String code = '';
      try {
        // AuthApiException has a code field
        // ignore: invalid_use_of_visible_for_testing_member
        code = (error as dynamic).code ?? '';
      } catch (_) {}
      switch (msg) {
        case 'Invalid login credentials':
          message = 'Invalid phone or password. Please check your credentials.';
          break;
        case 'Email not confirmed':
        case 'Phone not confirmed':
        case 'User not confirmed':
          message = 'Please verify your phone number before signing in.';
          backgroundColor = Colors.orange;
          break;
        case 'User already registered':
          message =
              'An account with this phone already exists. Please sign in instead.';
          break;
        case 'Password should be at least 6 characters':
          message = 'Password must be at least 6 characters long.';
          break;
        case 'Invalid email':
          message = 'Please enter a valid email address.';
          break;
        case 'Invalid phone':
        case 'Invalid phone number':
          message = 'Please enter a valid phone number.';
          break;
        case 'Signup disabled':
          message = 'New user registration is currently disabled.';
          break;
        case 'User not found':
          message = 'No account found with this phone number.';
          break;
        case 'Wrong password':
        case 'Incorrect password':
          message = 'Password is incorrect. Please try again or reset your password.';
          break;
        case 'Email rate limit exceeded':
        case 'SMS rate limit exceeded':
          message = 'Too many attempts. Please wait before trying again.';
          backgroundColor = Colors.orange;
          break;
        case 'Token has expired or is invalid':
          message = 'OTP has expired or is invalid. Please request a new code.';
          backgroundColor = Colors.orange;
          break;
        case 'Session not found':
          message = 'Your session has expired. Please sign in again.';
          break;
        default:
          // Map by code if available
          if (code == 'otp_expired') {
            message = 'OTP has expired. Please request a new code.';
            backgroundColor = Colors.orange;
          } else {
            message = msg;
          }
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
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  static void handleNetworkError(dynamic error, {VoidCallback? onRetry, StackTrace? stackTrace}) {
    // Enhanced error logging with stack trace preservation
    DebugLogger.logDetailedError(
      operation: 'handleNetworkError',
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      additionalData: {
        'hasRetryCallback': onRetry != null,
        'errorString': error.toString(),
      },
    );

    String message;

    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException')) {
      message =
          'No internet connection. Please check your network and try again.';
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
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
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
            Icon(icon ?? Icons.inbox_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}

class ApiErrorHandler {
  /// Handles API errors and provides user-friendly messages and debugging info
  static String handleError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    final errorMessage = error.toString();

    DebugLogger.error(
      'API Error in ${context ?? 'unknown context'}: $errorMessage',
      error,
      stackTrace,
    );

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
    DebugLogger.warning(
      'Type casting error detected: backend data types don\'t match frontend expectations',
    );

    if (error.contains("'int' is not a subtype of type 'String'")) {
      DebugLogger.info(
        'Solution: Backend is returning integer where string is expected',
      );
      return 'Data format mismatch - contact support';
    } else if (error.contains(
      "'List<dynamic>' is not a subtype of type 'Map<String, dynamic>'",
    )) {
      DebugLogger.info(
        'Solution: Backend is returning array where object is expected',
      );
      return 'Data structure mismatch - please try again';
    } else if (error.contains("'String' is not a subtype of type 'int'")) {
      DebugLogger.info(
        'Solution: Backend is returning string where number is expected',
      );
      return 'Numeric data format issue - please try again';
    }

    return 'Data format error - please try again';
  }

  static String _handleNetworkError(String error, String? context) {
    DebugLogger.warning('Network connectivity issue detected');
    DebugLogger.debug(
      'Solutions: 1. Check backend server 2. Verify connectivity 3. Check firewall',
    );

    return 'Unable to connect to server - please try again later';
  }

  static String _handleHttpError(int statusCode, String? context) {
    switch (statusCode) {
      case 401:
        DebugLogger.warning('Authentication error: invalid or expired token');
        return 'Please log in again';

      case 403:
        DebugLogger.warning('Authorization error: insufficient permissions');
        return 'Access denied - insufficient permissions';

      case 404:
        DebugLogger.warning('Resource not found');
        return 'Requested data not found';

      case 500:
        DebugLogger.error('Server error: backend is experiencing issues');
        return 'Server error - please try again later';

      default:
        DebugLogger.error('HTTP Error $statusCode');
        return 'Server responded with error $statusCode';
    }
  }

  static String _handleJsonError(String error, String? context) {
    DebugLogger.warning('JSON parsing error: invalid response format');
    DebugLogger.debug('Check backend response format and verify valid JSON');

    return 'Invalid data format received - please try again';
  }

  static String _handleAuthError(String error, String? context) {
    DebugLogger.warning('Authentication failed');
    DebugLogger.debug('Verify credentials and account status');

    return 'Authentication failed - please check credentials';
  }

  static String _handleGenericError(String error, String? context) {
    DebugLogger.error('Unhandled error type: $error');
    DebugLogger.debug('Request failed - please retry');

    return 'Unexpected error occurred - please try again later';
  }

  /// Logs detailed error information for debugging
  static void logDetailedError({
    required String operation,
    required dynamic error,
    required StackTrace stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    // Use the enhanced logger's built-in detailed error method
    DebugLogger.logDetailedError(
      operation: operation,
      error: error,
      stackTrace: stackTrace,
      additionalData: additionalData,
    );
  }
}
