import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Remote datasource for visit operations.
class VisitsRemoteDatasource {
  final ApiClient _apiClient;

  VisitsRemoteDatasource(this._apiClient);

  /// Fetches all visits for the current user.
  Future<List<VisitModel>> fetchVisits({int page = 1, int limit = 50}) async {
    DebugLogger.debug('📅 Fetching visits: page=$page');
    final response = await _apiClient.get(
      '/visits',
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
      useCache: false,
    );

    return _parseVisitsResponse(response.body);
  }

  /// Schedules a new visit.
  Future<VisitModel> scheduleVisit({
    required int propertyId,
    required String scheduledDate,
    String? specialRequirements,
  }) async {
    DebugLogger.debug('📅 Scheduling visit for property $propertyId');
    final response = await _apiClient.post(
      '/visits',
      body: {
        'property_id': propertyId,
        'scheduled_date': scheduledDate,
        'special_requirements': specialRequirements ?? '',
      },
    );
    return VisitModel.fromJson(response.body as Map<String, dynamic>);
  }

  /// Cancels a visit.
  Future<bool> cancelVisit(int visitId, {required String reason}) async {
    DebugLogger.debug('❌ Cancelling visit $visitId');
    final response = await _apiClient.delete('/visits/$visitId', queryParams: {'reason': reason});
    return response.statusCode == 200;
  }

  /// Reschedules a visit.
  Future<bool> rescheduleVisit(int visitId, {required String newDate, String? reason}) async {
    DebugLogger.debug('📅 Rescheduling visit $visitId');
    final response = await _apiClient.put(
      '/visits/$visitId',
      body: {'scheduled_date': newDate, 'reason': reason ?? ''},
    );
    return response.statusCode == 200;
  }

  List<VisitModel> _parseVisitsResponse(dynamic body) {
    try {
      if (body is Map<String, dynamic>) {
        final data = body['data'] ?? body['visits'] ?? [];
        if (data is List) {
          return data.map((json) => VisitModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      } else if (body is List) {
        return body.map((json) => VisitModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to parse visits response: $e', e, stackTrace);
      rethrow;
    }
  }
}
