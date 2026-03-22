import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/network/api_paths.dart';
import 'package:ghar360/core/network/response_parser.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Remote datasource for swipe operations.
class SwipesRemoteDatasource {
  final ApiClient _apiClient;

  SwipesRemoteDatasource(this._apiClient);

  /// Logs a swipe action.
  /// [propertyId] is the property ID (int for consistency with PropertyModel)
  Future<void> logSwipe({required int propertyId, required String action}) async {
    DebugLogger.debug('👆 Logging swipe: $action on property $propertyId');
    await _apiClient.post(
      ApiPaths.swipes,
      body: {'property_id': propertyId, 'action': action},
      idempotent: true,
    );
  }

  /// Records a swipe with explicit liked/passed state.
  Future<void> swipeProperty({required int propertyId, required bool isLiked}) async {
    await _apiClient.post(
      ApiPaths.swipes,
      body: {'property_id': propertyId, 'is_liked': isLiked},
      idempotent: true,
    );
  }

  /// Fetches swipe history for the current user.
  Future<List<Map<String, dynamic>>> fetchSwipeHistory({int page = 1, int limit = 100}) async {
    DebugLogger.debug('📜 Fetching swipe history: page=$page');
    final response = await _apiClient.get(
      ApiPaths.swipesHistory,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
      useCache: false,
    );

    final body = response.body;
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().toList();
    }

    final payload = ResponseParser.unwrapObject(body);
    final dynamic propertiesData = payload['properties'] ?? payload['swipes'] ?? payload['data'];
    if (propertiesData is List) {
      return propertiesData
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const <Map<String, dynamic>>[];
  }
}
