import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/data/models/unified_filter_model.dart';

void main() {
  group('UnifiedFilterModel.toApiQueryParams', () {
    test('normalizes purpose/property_type and remaps date keys', () {
      final filters = UnifiedFilterModel(
        purpose: 'shortStay',
        propertyType: ['Apartment', 'builderFloor', 'Loft', 'All'],
        checkInDate: DateTime(2026, 2, 1),
        checkOutDate: DateTime(2026, 2, 3),
        propertyIds: [7, 9],
      );

      final params = filters.toApiQueryParams();

      expect(params['purpose'], 'short_stay');
      expect(params['property_type'], ['apartment', 'builder_floor', 'loft']);
      expect(params['check_in'], '2026-02-01');
      expect(params['check_out'], '2026-02-03');
      expect(params['ids'], [7, 9]);
      expect(params.containsKey('check_in_date'), isFalse);
      expect(params.containsKey('check_out_date'), isFalse);
    });
  });
}
