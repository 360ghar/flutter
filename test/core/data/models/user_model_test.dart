import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/data/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('parses full JSON correctly', () {
      final json = <String, dynamic>{
        'id': 1,
        'supabase_user_id': 'abc-123',
        'email': 'test@example.com',
        'full_name': 'John Doe',
        'phone': '+91-9876543210',
        'date_of_birth': '1990-06-15',
        'is_active': true,
        'is_verified': true,
        'profile_image_url': 'http://example.com/photo.jpg',
        'current_latitude': 28.6139,
        'current_longitude': 77.2090,
        'created_at': '2025-01-01T00:00:00.000Z',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 1);
      expect(model.supabaseUserId, 'abc-123');
      expect(model.email, 'test@example.com');
      expect(model.fullName, 'John Doe');
      expect(model.phone, '+91-9876543210');
      expect(model.dateOfBirth, '1990-06-15');
      expect(model.isActive, true);
      expect(model.isVerified, true);
      expect(model.profileImageUrl, 'http://example.com/photo.jpg');
      expect(model.currentLatitude, 28.6139);
      expect(model.currentLongitude, 77.2090);
    });

    test('applies defaults for missing fields', () {
      final json = <String, dynamic>{'id': 1, 'created_at': '2025-01-01T00:00:00.000Z'};

      final model = UserModel.fromJson(json);

      expect(model.supabaseUserId, '');
      expect(model.email, 'unknown@example.com');
      expect(model.isActive, true);
      expect(model.isVerified, false);
      expect(model.fullName, isNull);
      expect(model.phone, isNull);
    });
  });

  group('UserModel helper getters', () {
    UserModel make({
      String email = 'test@example.com',
      String? fullName,
      String? phone,
      String? dateOfBirth,
      String? profileImageUrl,
      double? currentLatitude,
      double? currentLongitude,
    }) {
      return UserModel(
        id: 1,
        supabaseUserId: 'abc',
        email: email,
        fullName: fullName,
        phone: phone,
        dateOfBirth: dateOfBirth,
        profileImageUrl: profileImageUrl,
        currentLatitude: currentLatitude,
        currentLongitude: currentLongitude,
        isActive: true,
        isVerified: false,
        createdAt: DateTime(2025, 1, 1),
      );
    }

    test('name falls back to Unknown User', () {
      expect(make(fullName: 'Alice').name, 'Alice');
      expect(make().name, 'Unknown User');
    });

    test('hasLocation requires both coordinates', () {
      expect(make(currentLatitude: 28.0, currentLongitude: 77.0).hasLocation, true);
      expect(make(currentLatitude: 28.0).hasLocation, false);
      expect(make().hasLocation, false);
    });

    test('dateOfBirthAsDate parses valid date string', () {
      final model = make(dateOfBirth: '1990-06-15');
      expect(model.dateOfBirthAsDate, DateTime(1990, 6, 15));
    });

    test('dateOfBirthAsDate returns null for invalid string', () {
      expect(make(dateOfBirth: 'not-a-date').dateOfBirthAsDate, isNull);
      expect(make().dateOfBirthAsDate, isNull);
    });

    test('age returns null when dateOfBirth is null', () {
      expect(make().age, isNull);
    });

    test('age calculates correctly for known birthdate', () {
      // Use a fixed date far in the past for deterministic testing
      final age = make(dateOfBirth: '2000-01-01').age;
      expect(age, isNotNull);
      expect(age!, greaterThanOrEqualTo(25));
    });

    test('profileCompletionPercentage counts filled fields', () {
      // 0 of 5 (email is 'unknown@example.com' default but still non-empty)
      // Actually: email defaults to 'unknown@example.com' which is non-empty → 20%
      expect(make(email: '').profileCompletionPercentage, 0);
      expect(make().profileCompletionPercentage, 20); // email only

      // 3 of 5: email + fullName + phone
      expect(make(fullName: 'Alice', phone: '123').profileCompletionPercentage, 60);

      // 5 of 5: all fields
      expect(
        make(
          fullName: 'Alice',
          phone: '123',
          dateOfBirth: '1990-01-01',
          profileImageUrl: 'http://img.png',
        ).profileCompletionPercentage,
        100,
      );
    });

    test('isProfileComplete requires email, fullName, dateOfBirth', () {
      expect(make(fullName: 'Alice', dateOfBirth: '1990-01-01').isProfileComplete, true);
      expect(make(fullName: 'Alice').isProfileComplete, false, reason: 'Missing dateOfBirth');
      expect(make(dateOfBirth: '1990-01-01').isProfileComplete, false, reason: 'Missing fullName');
      expect(
        make(email: '', fullName: 'Alice', dateOfBirth: '1990-01-01').isProfileComplete,
        false,
        reason: 'Empty email',
      );
    });

    test('lastLogin returns updatedAt if present, else createdAt', () {
      final base = make();
      expect(base.lastLogin, DateTime(2025, 1, 1));

      final withUpdate = base.copyWith(updatedAt: DateTime(2025, 6, 1));
      expect(withUpdate.lastLogin, DateTime(2025, 6, 1));
    });
  });

  group('UserModel.copyWith', () {
    test('overrides specified fields and preserves others', () {
      final original = UserModel(
        id: 1,
        supabaseUserId: 'abc',
        email: 'test@example.com',
        fullName: 'John',
        isActive: true,
        isVerified: false,
        createdAt: DateTime(2025, 1, 1),
      );

      final updated = original.copyWith(fullName: 'Jane', isVerified: true);

      expect(updated.fullName, 'Jane');
      expect(updated.isVerified, true);
      expect(updated.id, 1, reason: 'Unchanged fields preserved');
      expect(updated.email, 'test@example.com');
    });
  });
}
