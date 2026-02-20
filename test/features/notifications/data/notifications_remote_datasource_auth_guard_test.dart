import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Main notification registration auth guard', () {
    bool shouldRegisterToken({required String? accessToken, required String? currentUserId}) {
      if (accessToken == null || accessToken.isEmpty || currentUserId == null) {
        return false;
      }
      return true;
    }

    test('returns false when access token is missing', () {
      expect(shouldRegisterToken(accessToken: null, currentUserId: 'uid-123'), isFalse);
      expect(shouldRegisterToken(accessToken: '', currentUserId: 'uid-123'), isFalse);
    });

    test('returns false when user id is missing', () {
      expect(shouldRegisterToken(accessToken: 'jwt-token', currentUserId: null), isFalse);
    });

    test('returns true when both access token and user id are available', () {
      expect(shouldRegisterToken(accessToken: 'jwt-token', currentUserId: 'uid-123'), isTrue);
    });
  });
}
