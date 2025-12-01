import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_image_model.dart';
import 'package:ghar360/core/data/models/property_media_payload.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/data/models/unified_property_response.dart';
import 'package:ghar360/core/data/providers/api_service.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

class PropertiesRepository extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

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

      final response = await _apiService.searchProperties(
        filters: filters,
        latitude: latitude,
        longitude: longitude,
        radiusKm: (filters.radiusKm ?? radiusKm ?? 10.0),
        page: page,
        limit: limit,
        excludeSwiped: excludeSwiped,
        useCache: useCache,
      );

      DebugLogger.success('Fetched ${response.properties.length} properties on page $page');
      return response;
    } on AppException catch (e) {
      DebugLogger.error('Failed to fetch properties: ${e.message}');
      rethrow;
    }
  }

  Future<PropertyModel> getPropertyDetail(int propertyId) async {
    try {
      DebugLogger.api('Fetching property details: $propertyId');
      final property = await _apiService.getPropertyDetails(propertyId);
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
      const batchSize = 10;
      final List<PropertyModel> allProperties = [];

      for (int i = 0; i < propertyIds.length; i += batchSize) {
        final batch = propertyIds.skip(i).take(batchSize).toList();
        final futures = batch.map((id) => getPropertyDetail(id));

        try {
          final batchResults = await Future.wait(futures);
          allProperties.addAll(batchResults);
        } catch (e) {
          DebugLogger.warning('Some properties failed to load in batch: $e');
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
      return await _apiService.createProperty(payload);
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
        payload.addAll(mediaPayload.toJson());
      }
      DebugLogger.api('Updating property $propertyId with media=${mediaPayload != null}');
      return await _apiService.updateProperty(propertyId, payload);
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
      DebugLogger.api('Updating media for property $propertyId');
      return await _apiService.updatePropertyMedia(propertyId, payload.toJson());
    } on AppException catch (e) {
      DebugLogger.error('Failed to update property media for $propertyId: ${e.message}');
      rethrow;
    }
  }

  void clearCache() {
    DebugLogger.api('Properties repository cache cleared');
  }
}
