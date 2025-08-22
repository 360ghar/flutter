import 'package:get/get.dart';
import '../models/property_model.dart';
import '../models/unified_filter_model.dart';
import '../models/unified_property_response.dart';
import '../providers/api_service.dart';
import '../../utils/debug_logger.dart';

class SwipesRepository extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // Record a swipe action
  Future<void> recordSwipe({
    required int propertyId,
    required bool isLiked,
    double? userLocationLat,
    double? userLocationLng,
    String? sessionId,
  }) async {
    try {
      DebugLogger.api('👆 RECORDING SWIPE: ${isLiked ? 'LIKE' : 'DISLIKE'} property $propertyId');
      DebugLogger.api('🔄 Swipe will update liked status to: $isLiked');
      DebugLogger.api('📍 User location: $userLocationLat, $userLocationLng');

      await _apiService.swipeProperty(
        propertyId,
        isLiked,
        userLocationLat: userLocationLat,
        userLocationLng: userLocationLng,
        sessionId: sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      );

      DebugLogger.success('✅ Swipe recorded successfully with location data');
    } catch (e) {
      DebugLogger.error('❌ Failed to record swipe: $e');
      rethrow;
    }
  }

  // Get swipe history properties with comprehensive filtering
  Future<UnifiedPropertyResponse> getSwipeHistoryProperties({
    required UnifiedFilterModel filters,
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
        lat: filters.latitude,
        lng: filters.longitude,
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

        // Location Filters
        city: filters.city,
        locality: filters.locality,
        pincode: filters.pincode,

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

      // Parse properties from the new response format
      final List<dynamic> propertiesJson = responseJson['properties'] ?? [];
      DebugLogger.api('📦 New API format: Found ${propertiesJson.length} properties in response');
      final properties = propertiesJson.map((json) {
        final property = PropertyModel.fromJson(json);
        DebugLogger.api('🏠 Property: ${property.title} (liked: ${property.liked})');
        return property;
      }).toList();

      // Create UnifiedPropertyResponse with the new format
      final response = UnifiedPropertyResponse(
        properties: properties,
        total: responseJson['total'] ?? 0,
        page: responseJson['page'] ?? 1,
        totalPages: responseJson['total_pages'] ?? 1,
        limit: responseJson['limit'] ?? limit,
        filtersApplied: responseJson['filters_applied'] ?? filters.toJson(),
        searchCenter: responseJson['search_center'] != null
          ? SearchCenter(
              latitude: responseJson['search_center']['latitude'],
              longitude: responseJson['search_center']['longitude'],
            )
          : null,
      );

      DebugLogger.success(
        '✅ Loaded ${response.properties.length} properties from swipe history (page ${response.page}/${response.totalPages})',
      );
      return response;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch swipe history properties: $e');
      rethrow;
    }
  }

  // Get liked properties via server-side history endpoint
  Future<List<PropertyModel>> getLikedProperties({
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      DebugLogger.api('❤️ Fetching liked properties (server-side): page=$page, limit=$limit');
      final response = await getSwipeHistoryProperties(
        filters: filters,
        page: page,
        limit: limit,
        isLiked: true,
      );
      return response.properties;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch liked properties: $e');
      rethrow;
    }
  }

  // Get passed properties via server-side history endpoint
  Future<List<PropertyModel>> getPassedProperties({
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      DebugLogger.api('👎 Fetching passed properties (server-side): page=$page, limit=$limit');
      final response = await getSwipeHistoryProperties(
        filters: filters,
        page: page,
        limit: limit,
        isLiked: false,
      );
      return response.properties;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch passed properties: $e');
      rethrow;
    }
  }

  // Get liked properties (new format - no swipe IDs needed)
  Future<List<PropertyModel>> getLikedPropertiesWithSwipeIds({
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      DebugLogger.api('❤️ Fetching liked properties: page=$page, limit=$limit');

      final response = await getSwipeHistoryProperties(
        filters: filters,
        page: page,
        limit: limit,
        isLiked: true,
      );

      DebugLogger.success('✅ Loaded ${response.properties.length} liked properties');
      return response.properties;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch liked properties: $e');
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