import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../data/providers/api_service.dart';
import 'null_check_trap.dart';
import 'app_exceptions.dart';
import 'debug_logger.dart';

class ErrorMapper {
  // Map API errors to user-friendly messages
  static AppException mapApiError(Object error, [StackTrace? stackTrace]) {
    // Log the incoming error being normalized to an AppException (informational, not a failure)
    DebugLogger.info(
      '🗺️ [ERROR_MAPPER] Mapping incoming error: type=${error.runtimeType}, error=$error',
      error,
      stackTrace,
    );

    // ADD THIS BLOCK AT THE TOP
    // ==========================================================
    if (error is String) {
      NullCheckTrap.captureStringOccurrence(
        error,
        source: 'ErrorMapper.mapApiError(String)',
      );
      // Return a generic exception for string errors.
      return NetworkException(
        'An unexpected error occurred. Please try again.',
        details: error,
      );
    }
    // ==========================================================

    // Special handling for null check operator errors
    // Only emit deep stack analysis for non-String errors to reduce log noise
    if (error.toString().contains('Null check operator used on a null value')) {
      if (error is String) {
        // Capture a one-time stack to identify where this mapping is triggered
        NullCheckTrap.captureStringOccurrence(
          error,
          source: 'ErrorMapper.mapApiError',
        );
      } else if (error is Error || error is Exception) {
        DebugLogger.error(
          '🚨 [ERROR_MAPPER] NULL CHECK OPERATOR ERROR DETECTED!',
        );
        DebugLogger.error('🚨 [ERROR_MAPPER] Error type: ${error.runtimeType}');
        DebugLogger.error(
          '🚨 [ERROR_MAPPER] Error string: ${error.toString()}',
        );

        // CRITICAL: Get the current stack trace to see where this error is coming from
        DebugLogger.error(
          '🚨 [ERROR_MAPPER] CURRENT STACK TRACE (where ErrorMapper.map was called):',
        );
        final currentStackTrace = StackTrace.current;
        DebugLogger.error('🚨 [ERROR_MAPPER] ${currentStackTrace.toString()}');

        // Try to get original stack trace if available
        try {
          if (error is Error) {
            DebugLogger.error('🚨 [ERROR_MAPPER] ORIGINAL ERROR STACK TRACE:');
            DebugLogger.error('🚨 [ERROR_MAPPER] ${error.stackTrace}');
          }
        } catch (e) {
          DebugLogger.error(
            '🚨 [ERROR_MAPPER] Could not get original stack trace: $e',
          );
        }

        // Log error source analysis
        final stackString = currentStackTrace.toString();
        if (stackString.contains('property_model.g.dart')) {
          DebugLogger.error(
            '🚨 [ERROR_MAPPER] ERROR ORIGINATES FROM: property_model.g.dart (generated code)',
          );
        } else if (stackString.contains('property_image_model.g.dart')) {
          DebugLogger.error(
            '🚨 [ERROR_MAPPER] ERROR ORIGINATES FROM: property_image_model.g.dart (generated code)',
          );
        } else if (stackString.contains('explore_controller.dart')) {
          DebugLogger.error(
            '🚨 [ERROR_MAPPER] ERROR ORIGINATES FROM: explore_controller.dart',
          );
        } else if (stackString.contains('likes_controller.dart')) {
          DebugLogger.error(
            '🚨 [ERROR_MAPPER] ERROR ORIGINATES FROM: likes_controller.dart',
          );
        } else if (stackString.contains('page_state_service.dart')) {
          DebugLogger.error(
            '🚨 [ERROR_MAPPER] ERROR ORIGINATES FROM: page_state_service.dart',
          );
        } else {
          DebugLogger.error(
            '🚨 [ERROR_MAPPER] ERROR ORIGINATES FROM: Unknown location - check full stack trace above',
          );
        }

        // Extract and log the specific lines from the stack trace
        final lines = stackString.split('\n');
        DebugLogger.error('🚨 [ERROR_MAPPER] STACK TRACE ANALYSIS:');
        for (int i = 0; i < lines.length && i < 10; i++) {
          final line = lines[i].trim();
          if (line.contains('.dart')) {
            DebugLogger.error('🚨 [ERROR_MAPPER] [$i] $line');
          }
        }
      }
    }

    // Handle string error messages by wrapping them appropriately
    if (error is String) {
      // Check if it's a specific error pattern
      if (error.contains('Null check operator used on a null value')) {
        // Also ensure the one-time string trap captures the call site
        NullCheckTrap.captureStringOccurrence(
          error,
          source: 'ErrorMapper.mapApiError(String)',
        );
        return NetworkException(
          'A data processing error occurred. Please try again.',
          details: error,
        );
      }
      // Return as a generic network exception for string errors
      return NetworkException(error, details: error);
    }

    if (error is DioException) {
      return _mapDioException(error);
    }

    if (error is ApiException) {
      return _mapApiException(error);
    }

    // Supabase auth failure propagated from ApiService
    if (error is ApiAuthException) {
      return AuthenticationException(
        'Your session has expired. Please log in again.',
        code: 'UNAUTHORIZED',
        details: error.toString(),
      );
    }

    // Handle wrapped ApiException (Exception: ApiException: ...)
    if (error is Exception && error.toString().contains('ApiException:')) {
      final errorString = error.toString();
      final match = RegExp(
        r'ApiException: (.+) \(Status: (\d+)\)',
      ).firstMatch(errorString);
      if (match != null) {
        final message = match.group(1)!;
        final statusCode = int.tryParse(match.group(2)!);
        return _mapHttpStatusCode(statusCode, message);
      }
      return NetworkException(
        'API error occurred. Please try again.',
        details: error.toString(),
      );
    }

    // Handle wrapped ApiAuthException (Exception: ApiAuthException: ...)
    if (error is Exception && error.toString().contains('ApiAuthException:')) {
      return AuthenticationException(
        'Your session has expired. Please log in again.',
        code: 'UNAUTHORIZED',
        details: error.toString(),
      );
    }

    if (error is AppException) {
      return error;
    }

    // Generic error
    return NetworkException(
      'An unexpected error occurred. Please try again.',
      details: error.toString(),
    );
  }

  static AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkException(
          'Connection timeout. Please check your internet connection and try again.',
          code: 'TIMEOUT',
          details: error.message,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          'Unable to connect to server. Please check your internet connection.',
          code: 'CONNECTION_ERROR',
          details: error.message,
        );

      case DioExceptionType.badResponse:
        return _mapHttpStatusCode(
          error.response?.statusCode,
          error.response?.data,
        );

      case DioExceptionType.cancel:
        return NetworkException(
          'Request was cancelled.',
          code: 'CANCELLED',
          details: error.message,
        );

      default:
        return NetworkException(
          'Network error occurred. Please try again.',
          code: 'NETWORK_ERROR',
          details: error.message,
        );
    }
  }

  static AppException _mapApiException(ApiException error) {
    if (error.statusCode != null) {
      return _mapHttpStatusCode(error.statusCode, error.response);
    }

    return NetworkException(error.message, details: error.response);
  }

  static AppException _mapHttpStatusCode(
    int? statusCode,
    dynamic responseData,
  ) {
    switch (statusCode) {
      case 400:
        return ValidationException(
          'Invalid request. Please check your input and try again.',
          code: 'BAD_REQUEST',
          details: responseData,
          fieldErrors: _extractFieldErrors(responseData),
        );

      case 401:
        return AuthenticationException(
          'Your session has expired. Please log in again.',
          code: 'UNAUTHORIZED',
          details: responseData,
        );

      case 403:
        return AuthenticationException(
          'You don\'t have permission to access this resource.',
          code: 'FORBIDDEN',
          details: responseData,
        );

      case 404:
        return NotFoundException(
          'The requested resource was not found.',
          code: 'NOT_FOUND',
          details: responseData,
        );

      case 405:
        return ValidationException(
          'This operation is not supported. Please try a different action.',
          code: 'METHOD_NOT_ALLOWED',
          details: responseData,
        );

      case 422:
        return ValidationException(
          _extractValidationMessage(responseData) ??
              'Please check your input and try again.',
          code: 'VALIDATION_ERROR',
          details: responseData,
          fieldErrors: _extractFieldErrors(responseData),
        );

      case 429:
        return NetworkException(
          'Too many requests. Please wait a moment and try again.',
          code: 'RATE_LIMITED',
          details: responseData,
        );

      case 500:
        return ServerException(
          'Server error occurred. Our team has been notified.',
          code: 'SERVER_ERROR',
          statusCode: 500,
          details: responseData,
        );

      case 502:
      case 503:
      case 504:
        return ServerException(
          'Server is temporarily unavailable. Please try again later.',
          code: 'SERVER_UNAVAILABLE',
          statusCode: statusCode,
          details: responseData,
        );

      default:
        return ServerException(
          'An error occurred on the server. Please try again.',
          code: 'UNKNOWN_HTTP_ERROR',
          statusCode: statusCode,
          details: responseData,
        );
    }
  }

  static String? _extractValidationMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Try different message fields
      if (responseData['message'] is String) {
        return responseData['message'];
      }
      if (responseData['error'] is String) {
        return responseData['error'];
      }
      if (responseData['detail'] is String) {
        return responseData['detail'];
      }

      // Extract first error from errors object
      if (responseData['errors'] is Map) {
        final errors = responseData['errors'] as Map;
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        if (firstError is String) {
          return firstError;
        }
      }
    }
    return null;
  }

  static Map<String, List<String>>? _extractFieldErrors(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData['errors'] is Map) {
      final errors = responseData['errors'] as Map<String, dynamic>;
      final fieldErrors = <String, List<String>>{};

      errors.forEach((field, error) {
        if (error is List) {
          fieldErrors[field] = error.cast<String>();
        } else if (error is String) {
          fieldErrors[field] = [error];
        }
      });

      return fieldErrors.isNotEmpty ? fieldErrors : null;
    }
    return null;
  }

  // Show user-friendly error messages
  static void showErrorSnackbar(AppException error) {
    String title = 'Error';

    if (error is NetworkException) {
      title = 'Connection Error';
    } else if (error is AuthenticationException) {
      title = 'Authentication Error';
    } else if (error is ValidationException) {
      title = 'Validation Error';
    } else if (error is NotFoundException) {
      title = 'Not Found';
    } else if (error is ServerException) {
      title = 'Server Error';
    }

    Get.snackbar(
      title,
      error.message,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.9),
      colorText: Get.theme.colorScheme.onError,
    );

    // Log the full error for debugging
    DebugLogger.error(
      '❌ Error shown to user: title=$title, message=${error.message}',
    );
    if (error.details != null) {
      DebugLogger.error('Details: ${error.details}');
    }
  }

  // Get appropriate retry action text
  static String getRetryActionText(AppException error) {
    if (error is NetworkException) {
      if (error.code == 'CONNECTION_ERROR' || error.code == 'TIMEOUT') {
        return 'Check Connection & Retry';
      }
    }

    if (error is ServerException) {
      return 'Try Again Later';
    }

    if (error is AuthenticationException) {
      return 'Log In Again';
    }

    return 'Try Again';
  }

  // Check if error should trigger authentication flow
  static bool shouldTriggerReauth(AppException error) {
    return error is AuthenticationException && error.code == 'UNAUTHORIZED';
  }

  // Check if error is retryable
  static bool isRetryable(AppException error) {
    if (error is NetworkException) {
      return error.code != 'CANCELLED';
    }

    if (error is ServerException) {
      return error.statusCode != null && error.statusCode! >= 500;
    }

    if (error is AuthenticationException) {
      return false; // Auth errors need manual intervention
    }

    if (error is ValidationException) {
      return false; // Validation errors need input changes
    }

    return true; // Default to retryable
  }

  // Get error icon for UI
  static String getErrorIcon(AppException error) {
    if (error is NetworkException) {
      return '🌐';
    } else if (error is AuthenticationException) {
      return '🔒';
    } else if (error is ValidationException) {
      return '⚠️';
    } else if (error is NotFoundException) {
      return '🔍';
    } else if (error is ServerException) {
      return '🔧';
    }
    return '❌';
  }
}
