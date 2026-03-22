import 'package:flutter_test/flutter_test.dart';

import 'package:ghar360/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient query serialization', () {
    test('encodes list values as repeated query keys', () {
      final client = ApiClient(baseUrl: 'https://api.360ghar.com');
      final url = client.buildUrlForTesting(
        '/properties',
        queryParams: {
          'property_type': ['house', 'apartment'],
          'amenities': ['gym', 'pool'],
        },
      );

      final uri = Uri.parse(url);
      expect(uri.queryParametersAll['property_type'], ['house', 'apartment']);
      expect(uri.queryParametersAll['amenities'], ['gym', 'pool']);
    });

    test('merges existing query params and overrides by key', () {
      final client = ApiClient(baseUrl: 'https://api.360ghar.com');
      final url = client.buildUrlForTesting(
        '/properties?page=1',
        queryParams: {
          'page': 2,
          'ids': [10, 12],
        },
      );

      final uri = Uri.parse(url);
      expect(uri.queryParameters['page'], '2');
      expect(uri.queryParametersAll['ids'], ['10', '12']);
    });
  });
}
