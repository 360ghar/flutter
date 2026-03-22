/// Standardized API response parsing utilities.
///
/// All backend responses may be wrapped in `{ "data": ... }` or returned
/// unwrapped. This utility normalises both formats so datasources can
/// focus on domain logic.
class ResponseParser {
  /// Unwrap a single object from an API response body.
  ///
  /// Handles both `{ "data": { ... } }` and raw `{ ... }` formats.
  /// Returns the inner map, or the body itself if no wrapper.
  /// Throws [FormatException] if body is not a Map.
  static Map<String, dynamic> unwrapObject(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    throw FormatException(
      'Expected Map<String, dynamic> in response body, but got ${body?.runtimeType ?? 'null'}',
    );
  }

  /// Unwrap a list from an API response body.
  ///
  /// Tries `body['data']`, then [fallbackKeys] in order, then `body` itself.
  /// Returns a `List` if found, otherwise throws [FormatException].
  static List unwrapList(dynamic body, {List<String> fallbackKeys = const []}) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
      for (final key in fallbackKeys) {
        final alt = body[key];
        if (alt is List) return alt;
      }
      // If body itself is a map but no list found, throw exception
      throw FormatException(
        'Expected List in response body (checked keys: data, ${fallbackKeys.join(', ')}), '
        'but found keys: ${body.keys.take(10).join(', ')}',
      );
    }
    throw FormatException(
      'Expected List or Map<String, dynamic> in response body, but got ${body?.runtimeType ?? 'null'}',
    );
  }

  /// Extract pagination total from the response envelope.
  ///
  /// Looks for `total`, then `count` keys. Falls back to [listLength].
  static int extractTotal(dynamic body, {int listLength = 0}) {
    if (body is Map<String, dynamic>) {
      if (body['total'] is num) return (body['total'] as num).toInt();
      if (body['count'] is num) return (body['count'] as num).toInt();
    }
    return listLength;
  }
}
