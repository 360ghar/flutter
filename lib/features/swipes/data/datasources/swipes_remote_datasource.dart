import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Remote datasource for swipe operations.
class SwipesRemoteDatasource {
  final ApiClient _apiClient;

  SwipesRemoteDatasource(this._apiClient);

  /// Logs a swipe action.
  Future<void> logSwipe({required String propertyId, required String action}) async {
    DebugLogger.debug('👆 Logging swipe: $action on property $propertyId');
    await _apiClient.post('/swipes', body: {'property_id': propertyId, 'action': action});
  }

  /// Fetches swipe history for the current user.
  Future<List<Map<String, dynamic>>> fetchSwipeHistory({int page = 1, int limit = 100}) async {
    DebugLogger.debug('📜 Fetching swipe history: page=$page');
    final response = await _apiClient.get(
      '/swipes/history',
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
      useCache: false,
    );

    final body = response.body;
    if (body is List) {
      return body.cast<Map<String, dynamic>>();
    } else if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body['swipes'] ?? [];
      return (data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
