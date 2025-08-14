import 'package:get/get.dart';
import '../models/swipe_history_model.dart';
import '../models/property_model.dart';
import '../models/filters_model.dart';
import '../models/unified_property_response.dart';
import '../providers/api_client.dart';
import '../../utils/debug_logger.dart';
import '../../controllers/location_controller.dart';

class SwipesRepository extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final LocationController _locationController = Get.find<LocationController>();

  // Record a swipe action
  Future<void> recordSwipe({
    required int propertyId,
    required bool isLiked,
    String? sessionId,
  }) async {
    try {
      // Get current location if available
      final position = _locationController.currentPosition.value;
      
      final swipeData = PropertySwipe(
        propertyId: propertyId,
        isLiked: isLiked,
        userLocationLat: position?.latitude.toString(),
        userLocationLng: position?.longitude.toString(),
        sessionId: sessionId ?? _generateSessionId(),
      );

      DebugLogger.api('👆 Recording swipe: ${isLiked ? 'LIKE' : 'PASS'} property $propertyId');

      await _apiClient.request(
        '/swipes',
        (json) => json,
        method: 'POST',
        data: swipeData.toJson(),
        operationName: 'Record Swipe',
      );

      DebugLogger.success('✅ Swipe recorded successfully');
    } catch (e) {
      DebugLogger.error('❌ Failed to record swipe: $e');
      rethrow;
    }
  }

  // Get swipe history properties with full filters (server returns properties list)
  Future<UnifiedPropertyResponse> getSwipeHistoryProperties({
    required FiltersModel filters,
    int page = 1,
    int limit = 50,
    bool? isLiked,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
        ...filters.toQueryParams(),
      };

      if (isLiked != null) {
        queryParams['is_liked'] = isLiked.toString();
      }

      DebugLogger.api(
        '📜 Fetching swipe history properties: page=$page, limit=$limit, liked=$isLiked, filters=${filters.toJson()}',
      );

      final response = await _apiClient.request<UnifiedPropertyResponse>(
        '/swipes/history',
        (json) => _parseUnifiedPropertyResponse(json),
        queryParameters: queryParams,
        operationName: 'Get Swipe History Properties',
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
    required FiltersModel filters,
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
    required FiltersModel filters,
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

  // (Counts not required per spec; stats method removed)

  // Check if property was already swiped (best-effort check)
  Future<bool> wasPropertySwiped(int propertyId) async {
    try {
      final response = await getSwipeHistoryProperties(
        filters: FiltersModel(),
        page: 1,
        limit: 100,
      );
      return response.properties.any((p) => p.id == propertyId);
    } catch (e) {
      DebugLogger.warning('⚠️ Could not check swipe status for property $propertyId: $e');
      return false; // Assume not swiped if check fails
    }
  }

  // Helper to parse unified property response safely
  UnifiedPropertyResponse _parseUnifiedPropertyResponse(Map<String, dynamic> json) {
    try {
      if (json['properties'] is List) {
        final propertiesList = json['properties'] as List;
        final validProperties = <PropertyModel>[];
        for (int i = 0; i < propertiesList.length; i++) {
          final propertyData = propertiesList[i];
          if (propertyData is Map<String, dynamic>) {
            try {
              validProperties.add(PropertyModel.fromJson(propertyData));
            } catch (e) {
              DebugLogger.warning('⚠️ Skipping invalid property at index $i: $e');
            }
          }
        }
        json['properties'] = validProperties.map((p) => p.toJson()).toList();
      }
      return UnifiedPropertyResponse.fromJson(json);
    } catch (e) {
      DebugLogger.error('❌ Failed to parse unified property response (history): $e');
      rethrow;
    }
  }

  // Local search removed in favor of server-side filtering

  // Generate session ID for swipe tracking
  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Batch record multiple swipes (useful for offline support)
  Future<void> recordBatchSwipes(List<PropertySwipe> swipes) async {
    try {
      DebugLogger.api('📦 Recording batch of ${swipes.length} swipes');
      
      // Record swipes concurrently but limit concurrent requests
      const batchSize = 5;
      int successCount = 0;
      
      for (int i = 0; i < swipes.length; i += batchSize) {
        final batch = swipes.skip(i).take(batchSize).toList();
        final futures = batch.map((swipe) => recordSwipe(
          propertyId: swipe.propertyId,
          isLiked: swipe.isLiked,
          sessionId: swipe.sessionId,
        ));
        
        try {
          await Future.wait(futures);
          successCount += batch.length;
        } catch (e) {
          DebugLogger.warning('⚠️ Some swipes failed in batch: $e');
        }
      }
      
      DebugLogger.success('✅ Recorded $successCount/${swipes.length} swipes successfully');
    } catch (e) {
      DebugLogger.error('❌ Failed to record batch swipes: $e');
      rethrow;
    }
  }
}