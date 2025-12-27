import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/data/models/unified_property_response.dart';
import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Remote datasource for property data.
/// Handles API communication and response parsing.
class PropertiesRemoteDatasource {
  final ApiClient _apiClient;

  PropertiesRemoteDatasource(this._apiClient);

  /// Fetches properties from the API.
  Future<List<PropertyModel>> fetchProperties({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 20,
  }) async {
    DebugLogger.debug(
      '🔍 Fetching properties: lat=$latitude, lng=$longitude, radius=${radiusKm}km',
    );

    final queryParams = _buildQueryParams(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      filters: filters,
      page: page,
      limit: limit,
    );

    DebugLogger.debug('🔍 Query params: $queryParams');

    final response = await _apiClient.get('/properties/', queryParams: queryParams, useCache: true);

    return _parsePropertiesResponse(response.body);
  }

  /// Fetches a single property by ID.
  Future<PropertyModel> fetchPropertyById(String propertyId) async {
    final response = await _apiClient.get('/properties/$propertyId', useCache: true);
    final body = response.body;
    if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body;
      if (data is Map<String, dynamic>) {
        return PropertyModel.fromJson(Map<String, dynamic>.from(data));
      }
    }
    throw const FormatException('Unexpected property response format');
  }

  /// Searches properties by query.
  Future<List<PropertyModel>> searchProperties({
    required String query,
    double? latitude,
    double? longitude,
    double? radiusKm,
    UnifiedFilterModel? filters,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = _buildQueryParams(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      filters: filters,
      page: page,
      limit: limit,
      searchQuery: query,
    );

    final response = await _apiClient.get('/properties/', queryParams: queryParams, useCache: true);
    return _parsePropertiesResponse(response.body);
  }

  Map<String, dynamic> _buildQueryParams({
    required int page,
    required int limit,
    UnifiedFilterModel? filters,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? searchQuery,
  }) {
    final queryParams = <String, dynamic>{'page': page.toString(), 'limit': limit.toString()};

    if (latitude != null && longitude != null) {
      queryParams['lat'] = latitude.toStringAsFixed(6);
      queryParams['lng'] = longitude.toStringAsFixed(6);
      final effectiveRadius = radiusKm ?? filters?.radiusKm ?? 10.0;
      queryParams['radius'] = effectiveRadius.toInt().toString();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      queryParams['q'] = searchQuery.trim();
    }

    if (filters != null) {
      final filterMap = filters.toJson();
      filterMap.forEach((key, value) {
        if (value == null) return;

        if (key == 'search_query') {
          final q = value.toString().trim();
          if (q.isNotEmpty) {
            queryParams['q'] = q;
          }
          return;
        }

        if (value is List) {
          final cleanList = value
              .where((item) => item != null && item.toString().trim().isNotEmpty)
              .toList();
          if (cleanList.isNotEmpty) {
            queryParams[key] = cleanList.join(',');
          }
          return;
        }

        final stringValue = value.toString().trim();
        if (stringValue.isNotEmpty) {
          queryParams[key] = stringValue;
        }
      });
    }

    return queryParams;
  }

  List<PropertyModel> _parsePropertiesResponse(dynamic body) {
    try {
      DebugLogger.debug('📊 Response type: ${body?.runtimeType}');

      if (body is Map<String, dynamic>) {
        final unifiedResponse = UnifiedPropertyResponse.fromJson(body);
        DebugLogger.debug('📦 Parsed ${unifiedResponse.properties.length} properties');
        return unifiedResponse.properties;
      } else if (body is List) {
        final normalizedData = {'data': body};
        final unifiedResponse = UnifiedPropertyResponse.fromJson(normalizedData);
        return unifiedResponse.properties;
      } else {
        final normalizedData = {'data': body};
        final unifiedResponse = UnifiedPropertyResponse.fromJson(normalizedData);
        return unifiedResponse.properties;
      }
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to parse properties response: $e', e, stackTrace);
      rethrow;
    }
  }
}
