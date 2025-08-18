import 'package:get/get.dart';
import '../models/swipe_history_model.dart';
import '../models/property_model.dart';
import '../models/unified_filter_model.dart';
import '../models/unified_property_response.dart';
import '../providers/api_service.dart';
import '../../utils/debug_logger.dart';

// Wrapper class to hold property with swipe ID
class PropertyWithSwipeId {
  final PropertyModel property;
  final int swipeId;
  
  PropertyWithSwipeId({
    required this.property,
    required this.swipeId,
  });
}

class SwipesRepository extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // Record a swipe action
  Future<SwipeHistoryItem> recordSwipe({
    required int propertyId,
    required bool isLiked,
  }) async {
    try {
      DebugLogger.api('👆 Recording swipe: ${isLiked ? 'LIKE' : 'PASS'} property $propertyId');

      final swipeResult = await _apiService.swipeProperty(
        propertyId,
        isLiked,
      );

      DebugLogger.success('✅ Swipe recorded successfully');
      return swipeResult;
    } catch (e) {
      DebugLogger.error('❌ Failed to record swipe: $e');
      rethrow;
    }
  }

  // Get swipe history properties with full filters (server returns properties list)
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

      // Get swipe history using the new API
      final swipeHistory = await _apiService.getSwipes(
        isLiked: isLiked,
        page: page,
        limit: limit,
      );
      
      // Extract properties from swipe history items using PropertyModel.fromJson
      final properties = swipeHistory.items.map((item) {
        return PropertyModel.fromJson(item.property);
      }).toList();

      // Create a UnifiedPropertyResponse using swipe history pagination data
      final response = UnifiedPropertyResponse(
        properties: properties,
        total: swipeHistory.total,
        page: swipeHistory.page,
        totalPages: swipeHistory.totalPages,
        limit: swipeHistory.limit,
        filtersApplied: filters.toJson(),
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

  // Get liked properties with swipe IDs for unlike functionality
  Future<List<PropertyWithSwipeId>> getLikedPropertiesWithSwipeIds({
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      DebugLogger.api('❤️ Fetching liked properties with swipe IDs: page=$page, limit=$limit');
      
      final swipeHistory = await _apiService.getSwipes(
        isLiked: true,
        page: page,
        limit: limit,
      );
      
      // Create PropertyWithSwipeId objects that preserve both property and swipe ID
      final propertiesWithSwipeIds = swipeHistory.items.map((item) {
        final property = PropertyModel.fromJson(item.property);

        return PropertyWithSwipeId(
          property: property,
          swipeId: item.id, // The swipe ID from SwipeHistoryItem
        );
      }).toList();
      
      DebugLogger.success('✅ Loaded ${propertiesWithSwipeIds.length} liked properties with swipe IDs');
      return propertiesWithSwipeIds;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch liked properties with swipe IDs: $e');
      rethrow;
    }
  }

  // (Counts not required per spec; stats method removed)

  // Check if property was already swiped (best-effort check)
  Future<bool> wasPropertySwiped(int propertyId) async {
    try {
      final response = await getSwipeHistoryProperties(
        filters: UnifiedFilterModel.initial(),
        page: 1,
        limit: 100,
      );
      return response.properties.any((p) => p.id == propertyId);
    } catch (e) {
      DebugLogger.warning('⚠️ Could not check swipe status for property $propertyId: $e');
      return false; // Assume not swiped if check fails
    }
  }


  // Local search removed in favor of server-side filtering


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