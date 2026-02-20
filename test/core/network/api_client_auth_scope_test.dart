import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/network/api_client.dart';

void main() {
  group('ApiClient.isSessionCriticalEndpoint', () {
    test('returns true for users profile endpoint', () {
      expect(ApiClient.isSessionCriticalEndpoint('/users/profile/'), isTrue);
      expect(
        ApiClient.isSessionCriticalEndpoint('https://api.360ghar.com/api/v1/users/profile/'),
        isTrue,
      );
    });

    test('returns false for non-session endpoints', () {
      expect(ApiClient.isSessionCriticalEndpoint('/auth/profile'), isFalse);
      expect(ApiClient.isSessionCriticalEndpoint('/auth/session'), isFalse);
      expect(ApiClient.isSessionCriticalEndpoint('/health'), isFalse);
      expect(ApiClient.isSessionCriticalEndpoint('/visits'), isFalse);
      expect(ApiClient.isSessionCriticalEndpoint('/notifications/devices/register'), isFalse);
      expect(
        ApiClient.isSessionCriticalEndpoint('https://api.360ghar.com/api/v1/properties/'),
        isFalse,
      );
      expect(
        ApiClient.isSessionCriticalEndpoint(
          'https://api.360ghar.com/api/v1/notifications/devices/register',
        ),
        isFalse,
      );
    });
  });
}
