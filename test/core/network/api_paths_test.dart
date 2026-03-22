import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/network/api_paths.dart';

void main() {
  group('ApiPaths.normalize', () {
    test('adds api prefix when missing', () {
      expect(ApiPaths.normalize('/properties'), '/api/v1/properties');
      expect(ApiPaths.normalize('properties'), '/api/v1/properties');
    });

    test('does not duplicate api prefix', () {
      expect(ApiPaths.normalize('/api/v1/properties'), '/api/v1/properties');
    });

    test('keeps absolute URLs unchanged', () {
      const url = 'https://example.com/properties';
      expect(ApiPaths.normalize(url), url);
    });
  });
}
