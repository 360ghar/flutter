import 'package:get/get.dart';
import '../models/property_model.dart';
import '../models/unified_filter_model.dart';
import '../models/unified_property_response.dart';
import '../providers/api_service.dart';
import '../../utils/debug_logger.dart';
import '../../utils/app_exceptions.dart';

class SwipesRepository extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // Record a swipe action
  Future<void> recordSwipe({
    required int propertyId,
    required bool isLiked,
  }) async {
    try {
      DebugLogger.api(
        '👆 RECORDING SWIPE: ${isLiked ? 'LIKE' : 'DISLIKE'} property $propertyId',
      );
      DebugLogger.api('🔄 Swipe will update liked status to: $isLiked');

      await _apiService.swipeProperty(propertyId, isLiked);

      DebugLogger.success('✅ Swipe recorded successfully');
    } on AppException catch (e) {
      DebugLogger.error('❌ Failed to record swipe: ${e.message}');
      rethrow;
    }
  }

  // Get swipe history properties with comprehensive filtering
  Future<UnifiedPropertyResponse> getSwipeHistoryProperties({
    required UnifiedFilterModel filters,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 50,
    bool? isLiked,
  }) async {
    try {
      DebugLogger.api(
        '📜 Fetching swipe history properties: page=$page, limit=$limit, liked=$isLiked, filters=${filters.activeFilterCount} active',
      );

      // Get swipe history using the new API with comprehensive filtering
      DebugLogger.api('🔍 Fetching swipes with new API format');
      final responseJson = await _apiService.getSwipes(
        // Location & Search
        lat: latitude,
        lng: longitude,
        radius: filters.radiusKm?.toInt(),
        q: filters.searchQuery,

        // Property Filters
        propertyType: filters.propertyType,
        purpose: filters.purpose,
        priceMin: filters.priceMin,
        priceMax: filters.priceMax,
        bedroomsMin: filters.bedroomsMin,
        bedroomsMax: filters.bedroomsMax,
        bathroomsMin: filters.bathroomsMin,
        bathroomsMax: filters.bathroomsMax,
        areaMin: filters.areaMin,
        areaMax: filters.areaMax,

        // Additional Filters
        amenities: filters.amenities,
        parkingSpacesMin: filters.parkingSpacesMin,
        floorNumberMin: filters.floorNumberMin,
        floorNumberMax: filters.floorNumberMax,
        ageMax: filters.ageMax,

        // Short Stay Filters
        checkIn: filters.checkInDate?.toIso8601String().split('T').first,
        checkOut: filters.checkOutDate?.toIso8601String().split('T').first,
        guests: filters.guests,

        // Swipe Filters
        isLiked: isLiked,

        // Sorting & Pagination
        sortBy: filters.sortBy?.toString().split('.').last,
        page: page,
        limit: limit,
      );

      // Log raw API response for debugging
      DebugLogger.api('📊 [SWIPES_REPO] RAW API RESPONSE: $responseJson');

      // Parse properties from the new response format
      final List<dynamic> propertiesJson = responseJson['properties'] ?? [];
      DebugLogger.api(
        '📦 [SWIPES_REPO] New API format: Found ${propertiesJson.length} properties in response',
      );

      final properties = <PropertyModel>[];
      for (int i = 0; i < propertiesJson.length; i++) {
        try {
          final property = PropertyModel.fromJson(propertiesJson[i]);
          properties.add(property);
        } catch (e) {
          DebugLogger.error(
            '❌ [SWIPES_REPO] Error parsing property ${i + 1}: $e',
          );
          DebugLogger.error(
            '❌ [SWIPES_REPO] Property data: ${propertiesJson[i]}',
          );
          // Continue with other properties instead of failing entirely
        }
      }

      // Create UnifiedPropertyResponse with the new format
      final response = UnifiedPropertyResponse(
        properties: properties,
        total: responseJson['total'] ?? 0,
        page: responseJson['page'] ?? 1,
        totalPages: responseJson['total_pages'] ?? 1,
        limit: responseJson['limit'] ?? limit,
        filtersApplied: responseJson['filters_applied'] ?? filters.toJson(),
        searchCenter: () {
          try {
            final searchCenterData = responseJson['search_center'];
            if (searchCenterData != null) {
              final lat = searchCenterData['latitude'];
              final lng = searchCenterData['longitude'];
              if (lat != null && lng != null) {
                return SearchCenter(
                  latitude: lat.toDouble(),
                  longitude: lng.toDouble(),
                );
              }
            }
            return null;
          } catch (e) {
            DebugLogger.error(
              '❌ [SWIPES_REPO] Error creating SearchCenter: $e',
            );
            return null;
          }
        }(),
      );

      DebugLogger.success(
        '✅ Loaded ${response.properties.length} properties from swipe history (page ${response.page}/${response.totalPages})',
      );
      return response;
    } on AppException catch (e) {
      DebugLogger.error('❌ Failed to fetch swipe history properties: ${e.message}');
      rethrow;
    }
  }

  // Get liked properties via server-side history endpoint
  Future<List<PropertyModel>> getLikedProperties({
    required UnifiedFilterModel filters,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      DebugLogger.api(
        '❤️ Fetching liked properties (server-side): page=$page, limit=$limit',
      );
      final response = await getSwipeHistoryProperties(
        filters: filters,
        latitude: latitude,
        longitude: longitude,
        page: page,
        limit: limit,
        isLiked: true,
      );
      return response.properties;
    } on AppException catch (e) {
      DebugLogger.error('❌ Failed to fetch liked properties: ${e.message}');
      rethrow;
    }
  }

  // Get passed properties via server-side history endpoint
  Future<List<PropertyModel>> getPassedProperties({
    required UnifiedFilterModel filters,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      DebugLogger.api(
        '👎 Fetching passed properties (server-side): page=$page, limit=$limit',
      );
      final response = await getSwipeHistoryProperties(
        filters: filters,
        latitude: latitude,
        longitude: longitude,
        page: page,
        limit: limit,
        isLiked: false,
      );
      return response.properties;
    } on AppException catch (e) {
      DebugLogger.error('❌ Failed to fetch passed properties: ${e.message}');
      rethrow;
    }
  }

  // Get liked properties (new format - no swipe IDs needed)
  Future<List<PropertyModel>> getLikedPropertiesWithSwipeIds({
    required UnifiedFilterModel filters,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      DebugLogger.api('❤️ Fetching liked properties: page=$page, limit=$limit');

      final response = await getSwipeHistoryProperties(
        filters: filters,
        latitude: latitude,
        longitude: longitude,
        page: page,
        limit: limit,
        isLiked: true,
      );

      DebugLogger.success(
        '✅ Loaded ${response.properties.length} liked properties',
      );
      return response.properties;
    } on AppException catch (e) {
      DebugLogger.error('❌ Failed to fetch liked properties: ${e.message}');
      rethrow;
    }
  }

  // Get all swiped properties (both liked and disliked) with comprehensive filtering
  Future<UnifiedPropertyResponse> getAllSwipedProperties({
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 50,
  }) async {
    return await getSwipeHistoryProperties(
      filters: filters,
      page: page,
      limit: limit,
      isLiked: null, // Get both liked and disliked
    );
  }
}
