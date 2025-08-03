import 'package:flutter_test/flutter_test.dart';
import 'package:ghar360/app/data/models/property_card_model.dart';
import 'package:ghar360/app/data/models/property_model.dart';
import 'package:ghar360/app/data/models/user_model.dart';

void main() {
  group('Model Parsing Tests', () {
    test('PropertyCardModel handles missing fields with defaults', () {
      // Test with minimal JSON - should use default values
      final minimalJson = {
        'id': 1,
        'property_type': 'apartment',
        'purpose': 'rent',
      };

      final model = PropertyCardModel.fromJson(minimalJson);

      expect(model.id, 1);
      expect(model.title, 'Unknown Property'); // Default value
      expect(model.basePrice, 0.0); // Default value
      expect(model.likeCount, 0); // Default value
      expect(model.propertyType, PropertyType.apartment);
      expect(model.purpose, PropertyPurpose.rent);
    });

    test('PropertyCardModel handles proper numeric types', () {
      final jsonWithProperTypes = {
        'id': 123,
        'property_type': 'house',
        'purpose': 'buy',
        'base_price': 150000.50,
        'like_count': 25,
      };

      final model = PropertyCardModel.fromJson(jsonWithProperTypes);

      expect(model.id, 123);
      expect(model.basePrice, 150000.50);
      expect(model.likeCount, 25);
      expect(model.propertyType, PropertyType.house);
      expect(model.purpose, PropertyPurpose.buy);
    });

    test('UserModel handles missing fields with defaults', () {
      final minimalJson = {
        'id': 1,
        'created_at': '2023-01-01T00:00:00Z',
      };

      final model = UserModel.fromJson(minimalJson);

      expect(model.id, 1);
      expect(model.email, 'unknown@example.com'); // Default value
      expect(model.supabaseUserId, ''); // Default value
      expect(model.isActive, true); // Default value
      expect(model.isVerified, false); // Default value
    });

    test('PropertyModel handles complex defaults', () {
      final minimalJson = {
        'id': 1,
        'property_type': 'apartment',
        'purpose': 'rent',
        'status': 'available',
        'created_at': '2023-01-01T00:00:00Z',
      };

      final model = PropertyModel.fromJson(minimalJson);

      expect(model.id, 1);
      expect(model.title, 'Unknown Property'); // Default value
      expect(model.basePrice, 0.0); // Default value
      expect(model.country, 'India'); // Default value
      expect(model.isAvailable, true); // Default value
      expect(model.viewCount, 0); // Default value
      expect(model.likeCount, 0); // Default value
      expect(model.interestCount, 0); // Default value
    });

    test('Models handle null and missing nested objects gracefully', () {
      final jsonWithNulls = {
        'id': 1,
        'property_type': 'apartment',
        'purpose': 'rent',
        'status': 'available',
        'created_at': '2023-01-01T00:00:00Z',
        'amenities': null,
        'features': null,
        'images': null,
      };

      expect(() => PropertyModel.fromJson(jsonWithNulls), returnsNormally);
    });
  });
}