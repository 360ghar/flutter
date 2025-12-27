import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_image_model.dart';
import 'package:ghar360/core/data/models/property_media_payload.dart';
import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/data/models/unified_property_response.dart';
import 'package:ghar360/core/data/repositories/properties_repository.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/properties/data/repositories/properties_repository_impl.dart';

/// Adapter that wraps the new PropertiesRepositoryImpl to provide
/// backward compatibility with the old PropertiesRepository interface.
class PropertiesRepositoryAdapter extends PropertiesRepository {
  final PropertiesRepositoryImpl _newRepo;

  PropertiesRepositoryAdapter() : _newRepo = Get.find<PropertiesRepositoryImpl>(), super();

  @override
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
    DebugLogger.debug('📦 Using new architecture via adapter');

    final result = await _newRepo.getProperties(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm ?? filters.radiusKm ?? 10.0,
      filters: filters,
      page: page,
      limit: limit,
    );

    return result.when(
      success: (properties) => UnifiedPropertyResponse(
        properties: properties,
        total: properties.length,
        page: page,
        limit: limit,
        totalPages: properties.length >= limit ? page + 1 : page,
        filtersApplied: filters.toJson(),
      ),
      failure: (exception) => throw exception,
    );
  }

  @override
  Future<PropertyModel> getPropertyDetail(int propertyId) async {
    final result = await _newRepo.getPropertyById(propertyId.toString());

    return result.when(success: (property) => property, failure: (exception) => throw exception);
  }

  @override
  Future<List<PropertyModel>> getPropertiesByIds(List<int> propertyIds) async {
    if (propertyIds.isEmpty) return [];

    final List<PropertyModel> allProperties = [];
    for (final id in propertyIds) {
      try {
        final property = await getPropertyDetail(id);
        allProperties.add(property);
      } catch (e) {
        DebugLogger.warning('Failed to load property $id: $e');
      }
    }
    return allProperties;
  }

  @override
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

  @override
  Future<List<PropertyModel>> loadAllPropertiesForMap({
    required UnifiedFilterModel filters,
    required double latitude,
    required double longitude,
    double? radiusKm,
    int limit = 100,
    Function(int current, int total)? onProgress,
  }) async {
    // Use new architecture
    final result = await _newRepo.getProperties(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm ?? filters.radiusKm ?? 10.0,
      filters: filters,
      page: 1,
      limit: limit,
    );

    return result.when(
      success: (properties) => properties,
      failure: (exception) => throw exception,
    );
  }

  @override
  Future<PropertyModel> createProperty({
    required Map<String, dynamic> propertyData,
    PropertyMediaPayload? mediaPayload,
  }) async {
    throw UnimplementedError('Create property not yet migrated to new architecture');
  }

  @override
  Future<PropertyModel> updateProperty({
    required int propertyId,
    Map<String, dynamic>? fields,
    PropertyMediaPayload? mediaPayload,
  }) async {
    throw UnimplementedError('Update property not yet migrated to new architecture');
  }

  @override
  Future<PropertyModel> updatePropertyMedia({
    required int propertyId,
    String? mainImageUrl,
    List<PropertyImageModel>? images,
    String? virtualTourUrl,
    String? videoTourUrl,
    List<String>? videoUrls,
    String? floorPlanUrl,
    String? googleStreetViewUrl,
  }) async {
    throw UnimplementedError('Update property media not yet migrated to new architecture');
  }

  @override
  void clearCache() {
    _newRepo.clearCache();
  }
}
