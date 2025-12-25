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

    final queryParams = <String, dynamic>{
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'radius_km': radiusKm.toString(),
      'page': page.toString(),
      'limit': limit.toString(),
    };

    // Add filters to query params
    if (filters.purpose != null && filters.purpose!.isNotEmpty) {
      queryParams['purpose'] = filters.purpose;
    }
    if (filters.propertyType != null && filters.propertyType!.isNotEmpty) {
      queryParams['property_type'] = filters.propertyType!.join(',');
    }
    if (filters.priceMin != null) {
      queryParams['min_price'] = filters.priceMin.toString();
    }
    if (filters.priceMax != null) {
      queryParams['max_price'] = filters.priceMax.toString();
    }
    if (filters.bedroomsMin != null && filters.bedroomsMin! > 0) {
      queryParams['bedrooms_min'] = filters.bedroomsMin.toString();
    }
    if (filters.bathroomsMin != null && filters.bathroomsMin! > 0) {
      queryParams['bathrooms_min'] = filters.bathroomsMin.toString();
    }

    DebugLogger.debug('🔍 Query params: $queryParams');

    final response = await _apiClient.get(
      '/properties/search',
      queryParams: queryParams,
      useCache: true,
    );

    return _parsePropertiesResponse(response.body);
  }

  /// Fetches a single property by ID.
  Future<PropertyModel> fetchPropertyById(String propertyId) async {
    final response = await _apiClient.get('/properties/$propertyId', useCache: true);
    final json = response.body as Map<String, dynamic>;
    return PropertyModel.fromJson(json);
  }

  /// Searches properties by query.
  Future<List<PropertyModel>> searchProperties({
    required String query,
    UnifiedFilterModel? filters,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (filters != null && filters.purpose != null && filters.purpose!.isNotEmpty) {
      queryParams['purpose'] = filters.purpose;
    }

    final response = await _apiClient.get(
      '/properties/search',
      queryParams: queryParams,
      useCache: true,
    );
    return _parsePropertiesResponse(response.body);
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
