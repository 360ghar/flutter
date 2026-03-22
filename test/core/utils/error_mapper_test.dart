import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/error_mapper.dart';
import 'package:universal_io/io.dart';

void main() {
  group('ErrorMapper.mapApiError', () {
    test('maps String error to NetworkException', () {
      final result = ErrorMapper.mapApiError('Something went wrong');

      expect(result, isA<NetworkException>());
      expect(result.message, 'Something went wrong');
    });

    test('maps SocketException to NetworkException with CONNECTION_ERROR', () {
      final result = ErrorMapper.mapApiError(const SocketException('No route to host'));

      expect(result, isA<NetworkException>());
      expect(result.code, 'CONNECTION_ERROR');
    });

    test('maps TimeoutException to NetworkException with TIMEOUT', () {
      final result = ErrorMapper.mapApiError(TimeoutException('Request timed out'));

      expect(result, isA<NetworkException>());
      expect(result.code, 'TIMEOUT');
    });

    test('maps HttpException to NetworkException with HTTP_EXCEPTION', () {
      final result = ErrorMapper.mapApiError(const HttpException('Bad response'));

      expect(result, isA<NetworkException>());
      expect(result.code, 'HTTP_EXCEPTION');
    });

    test('maps ApiException with statusCode 401 to AuthenticationException', () {
      final result = ErrorMapper.mapApiError(ApiException('Unauthorized', statusCode: 401));

      expect(result, isA<AuthenticationException>());
      expect(result.code, 'UNAUTHORIZED');
    });

    test('maps ApiException with statusCode 404 to NotFoundException', () {
      final result = ErrorMapper.mapApiError(ApiException('Not found', statusCode: 404));

      expect(result, isA<NotFoundException>());
      expect(result.code, 'NOT_FOUND');
    });

    test('maps ApiException with statusCode 500 to ServerException', () {
      final result = ErrorMapper.mapApiError(ApiException('Server error', statusCode: 500));

      expect(result, isA<ServerException>());
      expect(result.code, 'SERVER_ERROR');
    });

    test('maps ApiException without statusCode to NetworkException', () {
      final result = ErrorMapper.mapApiError(ApiException('Unknown error'));

      expect(result, isA<NetworkException>());
    });

    test('returns existing AppException as-is', () {
      final original = NotFoundException('Already mapped', code: 'NOT_FOUND');
      final result = ErrorMapper.mapApiError(original);

      expect(identical(result, original), true);
    });

    test('maps unknown Object to NetworkException', () {
      final result = ErrorMapper.mapApiError(42);

      expect(result, isA<NetworkException>());
      expect(result.message, contains('unexpected error'));
    });
  });

  group('ErrorMapper HTTP status code mapping', () {
    test('400 returns ValidationException with BAD_REQUEST', () {
      final result = ErrorMapper.mapApiError(ApiException('Bad request', statusCode: 400));
      expect(result, isA<ValidationException>());
      expect(result.code, 'BAD_REQUEST');
    });

    test('403 returns AuthenticationException with FORBIDDEN', () {
      final result = ErrorMapper.mapApiError(ApiException('Forbidden', statusCode: 403));
      expect(result, isA<AuthenticationException>());
      expect(result.code, 'FORBIDDEN');
    });

    test('405 returns ValidationException with METHOD_NOT_ALLOWED', () {
      final result = ErrorMapper.mapApiError(ApiException('Method not allowed', statusCode: 405));
      expect(result, isA<ValidationException>());
      expect(result.code, 'METHOD_NOT_ALLOWED');
    });

    test('422 returns ValidationException with VALIDATION_ERROR', () {
      final result = ErrorMapper.mapApiError(
        ApiException(
          'Unprocessable',
          statusCode: 422,
          response: '{"message": "Email is required"}',
        ),
      );
      expect(result, isA<ValidationException>());
      expect(result.code, 'VALIDATION_ERROR');
    });

    test('429 returns NetworkException with RATE_LIMITED', () {
      final result = ErrorMapper.mapApiError(ApiException('Rate limited', statusCode: 429));
      expect(result, isA<NetworkException>());
      expect(result.code, 'RATE_LIMITED');
    });

    test('502/503/504 return ServerException with SERVER_UNAVAILABLE', () {
      for (final code in [502, 503, 504]) {
        final result = ErrorMapper.mapApiError(ApiException('Unavailable', statusCode: code));
        expect(result, isA<ServerException>(), reason: 'Status $code');
        expect(result.code, 'SERVER_UNAVAILABLE', reason: 'Status $code');
      }
    });

    test('unknown status returns ServerException with UNKNOWN_HTTP_ERROR', () {
      final result = ErrorMapper.mapApiError(ApiException('Teapot', statusCode: 418));
      expect(result, isA<ServerException>());
      expect(result.code, 'UNKNOWN_HTTP_ERROR');
    });
  });

  group('ErrorMapper helper methods', () {
    test('shouldTriggerReauth returns true for UNAUTHORIZED', () {
      expect(
        ErrorMapper.shouldTriggerReauth(AuthenticationException('Expired', code: 'UNAUTHORIZED')),
        true,
      );
    });

    test('shouldTriggerReauth returns false for FORBIDDEN', () {
      expect(
        ErrorMapper.shouldTriggerReauth(AuthenticationException('Forbidden', code: 'FORBIDDEN')),
        false,
      );
    });

    test('shouldTriggerReauth returns false for non-auth exceptions', () {
      expect(
        ErrorMapper.shouldTriggerReauth(NetworkException('Offline', code: 'CONNECTION_ERROR')),
        false,
      );
    });

    test('isRetryable returns true for NetworkException (non-CANCELLED)', () {
      expect(ErrorMapper.isRetryable(NetworkException('Timeout', code: 'TIMEOUT')), true);
    });

    test('isRetryable returns false for CANCELLED NetworkException', () {
      expect(ErrorMapper.isRetryable(NetworkException('Cancelled', code: 'CANCELLED')), false);
    });

    test('isRetryable returns true for 5xx ServerException', () {
      expect(ErrorMapper.isRetryable(ServerException('Error', statusCode: 500)), true);
    });

    test('isRetryable returns false for ServerException without statusCode', () {
      expect(ErrorMapper.isRetryable(ServerException('Error')), false);
    });

    test('isRetryable returns false for AuthenticationException', () {
      expect(ErrorMapper.isRetryable(AuthenticationException('Unauthorized')), false);
    });

    test('isRetryable returns false for ValidationException', () {
      expect(ErrorMapper.isRetryable(ValidationException('Bad input')), false);
    });

    test('getErrorIcon returns appropriate emoji for each exception type', () {
      expect(ErrorMapper.getErrorIcon(NetworkException('x')), '🌐');
      expect(ErrorMapper.getErrorIcon(AuthenticationException('x')), '🔒');
      expect(ErrorMapper.getErrorIcon(ValidationException('x')), '⚠️');
      expect(ErrorMapper.getErrorIcon(NotFoundException('x')), '🔍');
      expect(ErrorMapper.getErrorIcon(ServerException('x')), '🔧');
      expect(ErrorMapper.getErrorIcon(CacheException('x')), '❌');
    });
  });
}
