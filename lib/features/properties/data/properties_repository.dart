import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_image_model.dart';
import 'package:ghar360/core/data/models/property_media_payload.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/data/models/unified_property_response.dart';
import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/network/api_paths.dart';
import 'package:ghar360/core/network/response_parser.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/properties/data/datasources/properties_remote_datasource.dart';

class PropertiesRepository extends GetxService {
  final PropertiesRemoteDatasource _remoteDatasource = Get.find<PropertiesRemoteDatasource>();
  final ApiClient _apiClient = Get.find<ApiClient>();

  Future<UnifiedPropertyResponse> getProperties({
    required UnifiedFilterModel filters,
    required int page,
    required int limit,
    required double latitude,
    required double longitude,
    double? radiusKm,
    bool excludeSwiped = false,
    bool useCache = true,
  }) async {
    try {
      DebugLogger.api(
        'Fetching properties page=$page limit=$limit filters=${filters.activeFilterCount}',
      );

      final properties = await _remoteDatasource.fetchProperties(
        filters: filters,
        latitude: latitude,
        longitude: longitude,
        radiusKm: (filters.radiusKm ?? radiusKm ?? 10.0),
        page: page,
        limit: limit,
        excludeSwiped: excludeSwiped,
        useCache: useCache,
      );
      // When the page is full, assume there may be more pages.
      // When it's not full, this is the last page.
      // Note: if the last page has exactly `limit` items, one extra
      // (empty) request will be made — acceptable trade-off without
      // server-provided total.
      final hasMore = properties.length >= limit;
      final response = UnifiedPropertyResponse(
        properties: properties,
        total: properties.length,
        page: page,
        limit: limit,
        totalPages: hasMore ? page + 1 : page,
        filtersApplied: filters.toJson(),
      );

      DebugLogger.success('Fetched ${response.properties.length} properties on page $page');
      return response;
    } on AppException catch (e) {
      DebugLogger.error('Failed to fetch properties: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error fetching properties: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<PropertyModel> getPropertyDetail(int propertyId) async {
    try {
      DebugLogger.api('Fetching property details: $propertyId');
      final property = await _remoteDatasource.fetchPropertyById(propertyId.toString());
      DebugLogger.success('Property details fetched: ${property.title}');
      return property;
    } on AppException catch (e) {
      DebugLogger.error('Failed to fetch property $propertyId: ${e.message}');
      rethrow;
    }
  }

  Future<List<PropertyModel>> getPropertiesByIds(List<int> propertyIds) async {
    if (propertyIds.isEmpty) return [];

    try {
      DebugLogger.api('Fetching ${propertyIds.length} properties by IDs');

      // Try batch endpoint first (single request per chunk of 50)
      const batchSize = 50;
      final List<PropertyModel> allProperties = [];

      for (int i = 0; i < propertyIds.length; i += batchSize) {
        final batch = propertyIds.skip(i).take(batchSize).toList();
        try {
          final batchResults = await _remoteDatasource.fetchPropertiesByIds(batch);
          allProperties.addAll(batchResults);
        } catch (e) {
          // Fallback: fetch individually if batch endpoint is unsupported
          DebugLogger.warning('Batch fetch failed, falling back to individual: $e');
          final futures = batch.map((id) => getPropertyDetail(id));
          try {
            final individualResults = await Future.wait(futures);
            allProperties.addAll(individualResults);
          } catch (e2) {
            DebugLogger.warning('Some properties failed to load: $e2');
          }
        }
      }

      DebugLogger.success('Loaded ${allProperties.length}/${propertyIds.length} properties');
      return allProperties;
    } on AppException catch (e) {
      DebugLogger.error('Failed to fetch properties by IDs: ${e.message}');
      rethrow;
    }
  }

  Future<UnifiedPropertyResponse> searchProperties({
    required UnifiedFilterModel filters,
    required int page,
    required int limit,
    required double latitude,
    required double longitude,
    double? radiusKm,
    bool excludeSwiped = false,
    bool useCache = false,
  }) async {
    return getProperties(
      filters: filters,
      page: page,
      limit: limit,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      excludeSwiped: excludeSwiped,
      useCache: useCache,
    );
  }

  Future<List<PropertyModel>> loadAllPropertiesForMap({
    required UnifiedFilterModel filters,
    required double latitude,
    required double longitude,
    double? radiusKm,
    int limit = 100,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      DebugLogger.api('Loading all properties for map view');

      final List<PropertyModel> allProperties = [];
      int currentPage = 1;
      int totalPages = 1;

      do {
        final response = await getProperties(
          filters: filters,
          page: currentPage,
          limit: limit,
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
          useCache: true,
        );

        allProperties.addAll(response.properties);
        totalPages = response.totalPages;
        onProgress?.call(currentPage, totalPages);
        currentPage++;
      } while (currentPage <= totalPages);

      DebugLogger.success('Loaded ${allProperties.length} properties for map');

      return allProperties;
    } on AppException catch (e, stackTrace) {
      DebugLogger.error('Failed to load properties for map: ${e.message}');
      DebugLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<PropertyModel> createProperty({
    required Map<String, dynamic> propertyData,
    PropertyMediaPayload? mediaPayload,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(propertyData);
      if (mediaPayload != null) {
        payload.addAll(mediaPayload.toJson());
      }
      DebugLogger.api('Creating property with media fields=${mediaPayload != null}');
      final response = await _apiClient.post(ApiPaths.properties, body: payload);
      return _parsePropertyResponse(response.body);
    } on AppException catch (e) {
      DebugLogger.error('Failed to create property: ${e.message}');
      rethrow;
    }
  }

  Future<PropertyModel> updateProperty({
    required int propertyId,
    Map<String, dynamic>? fields,
    PropertyMediaPayload? mediaPayload,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(fields ?? {});
      if (mediaPayload != null) {
        payload.addAll(mediaPayload.toPropertyUpdateJson());
      }
      DebugLogger.api('Updating property $propertyId with media=${mediaPayload != null}');
      final response = await _apiClient.put(
        ApiPaths.propertyById(propertyId.toString()),
        body: payload,
      );
      return _parsePropertyResponse(response.body);
    } on AppException catch (e) {
      DebugLogger.error('Failed to update property $propertyId: ${e.message}');
      rethrow;
    }
  }

  Future<PropertyModel> updatePropertyMedia({
    required int propertyId,
    String? mainImageUrl,
    List<PropertyImageModel>? images,
    String? videoTourUrl,
    List<String>? videoUrls,
    String? virtualTourUrl,
    String? googleStreetViewUrl,
    String? floorPlanUrl,
  }) async {
    final payload = PropertyMediaPayload(
      mainImageUrl: mainImageUrl,
      images: images,
      videoTourUrl: videoTourUrl,
      videoUrls: videoUrls,
      virtualTourUrl: virtualTourUrl,
      googleStreetViewUrl: googleStreetViewUrl,
      floorPlanUrl: floorPlanUrl,
    );

    try {
      if (images != null && images.isNotEmpty) {
        DebugLogger.warning(
          'Ignoring images in property update payload; backend update endpoint supports scalar media fields only.',
        );
      }
      DebugLogger.api('Updating media for property $propertyId');
      final response = await _apiClient.put(
        ApiPaths.propertyById(propertyId.toString()),
        body: payload.toPropertyUpdateJson(),
      );
      return _parsePropertyResponse(response.body);
    } on AppException catch (e) {
      DebugLogger.error('Failed to update property media for $propertyId: ${e.message}');
      rethrow;
    }
  }

  PropertyModel _parsePropertyResponse(dynamic body) {
    final payload = ResponseParser.unwrapObject(body);
    if (payload.isEmpty) {
      throw const FormatException('Unexpected property payload');
    }
    return PropertyModel.fromJson(Map<String, dynamic>.from(payload));
  }

  void clearCache() {
    DebugLogger.api('Properties repository cache cleared');
  }
}
