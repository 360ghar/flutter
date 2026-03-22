import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/data/models/page_state_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';

void main() {
  group('PageStateModel.copyWith', () {
    test('clears nullable fields when null is explicitly passed', () {
      final original = PageStateModel(
        pageType: PageType.explore,
        selectedLocation: const LocationData(name: 'Delhi', latitude: 28.6139, longitude: 77.2090),
        locationSource: 'gps',
        filters: UnifiedFilterModel.initial(),
        searchQuery: 'rent',
        properties: const [],
        error: NetworkException('boom'),
        lastFetched: DateTime(2026, 1, 1),
        additionalData: const {'segment': 'liked'},
      );

      final updated = original.copyWith(
        selectedLocation: null,
        locationSource: null,
        searchQuery: null,
        error: null,
        lastFetched: null,
        additionalData: null,
      );

      expect(updated.selectedLocation, isNull);
      expect(updated.locationSource, isNull);
      expect(updated.searchQuery, isNull);
      expect(updated.error, isNull);
      expect(updated.lastFetched, isNull);
      expect(updated.additionalData, isNull);
    });

    test('retains existing nullable fields when omitted', () {
      final original = PageStateModel(
        pageType: PageType.explore,
        selectedLocation: const LocationData(name: 'Delhi', latitude: 28.6139, longitude: 77.2090),
        locationSource: 'gps',
        filters: UnifiedFilterModel.initial(),
        searchQuery: 'rent',
        properties: const [],
        error: NetworkException('boom'),
        lastFetched: DateTime(2026, 1, 1),
        additionalData: const {'segment': 'liked'},
      );

      final updated = original.copyWith(isLoading: true);

      expect(updated.selectedLocation, original.selectedLocation);
      expect(updated.locationSource, original.locationSource);
      expect(updated.searchQuery, original.searchQuery);
      expect(updated.error, original.error);
      expect(updated.lastFetched, original.lastFetched);
      expect(updated.additionalData, original.additionalData);
      expect(updated.isLoading, isTrue);
    });
  });
}
