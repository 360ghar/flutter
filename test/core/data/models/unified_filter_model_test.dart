import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/data/models/unified_filter_model.dart';

void main() {
  group('UnifiedFilterModel.toApiQueryParams', () {
    test('normalizes purpose/property_type and remaps date keys', () {
      final filters = UnifiedFilterModel(
        purpose: 'shortStay',
        propertyType: ['Apartment', 'builderFloor', 'Loft', 'flatmate', 'All'],
        checkInDate: DateTime(2026, 2, 1),
        checkOutDate: DateTime(2026, 2, 3),
        propertyIds: [7, 9],
        genderPreference: 'Female',
        sharingType: 'shared room',
      );

      final params = filters.toApiQueryParams();

      expect(params['purpose'], 'short_stay');
      expect(params['property_type'], ['apartment', 'builder_floor', 'loft', 'flatmate']);
      expect(params['check_in'], '2026-02-01');
      expect(params['check_out'], '2026-02-03');
      expect(params['ids'], [7, 9]);
      expect(params['gender_preference'], 'female');
      expect(params['sharing_type'], 'shared_room');
      expect(params.containsKey('check_in_date'), isFalse);
      expect(params.containsKey('check_out_date'), isFalse);
    });

    test('normalizes legacy property type aliases', () {
      final filters = const UnifiedFilterModel(
        purpose: 'pg',
        propertyType: ['flat', 'independent-house', 'plots', 'office-space', 'roommate'],
      );

      final params = filters.toApiQueryParams();

      expect(params['purpose'], 'rent');
      expect(params['property_type'], ['apartment', 'house', 'plot', 'office', 'flatmate']);
    });
  });
}
