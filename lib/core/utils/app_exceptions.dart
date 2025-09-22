// Custom exception classes for better error handling
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

class AuthenticationException extends AppException {
  AuthenticationException(super.message, {super.code, super.details});
}

class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  ValidationException(super.message, {super.code, super.details, this.fieldErrors});
}

class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.details});
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException(super.message, {super.code, super.details, this.statusCode});
}

class LocationException extends AppException {
  LocationException(super.message, {super.code, super.details});
}

class CacheException extends AppException {
  CacheException(super.message, {super.code, super.details});
}

/// A wrapper class to hold an error and its associated stack trace.
class AppError {
  final Object error;
  final StackTrace stackTrace;

  AppError({required this.error, required this.stackTrace});

  @override
  String toString() {
    return 'AppError: ${error.toString()}';
  }
}
