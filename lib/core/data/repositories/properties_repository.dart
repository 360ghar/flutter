import 'package:get/get.dart';
import '../models/property_model.dart';
import '../models/unified_property_response.dart';
import '../models/unified_filter_model.dart';
import '../providers/api_client.dart';
import '../../utils/debug_logger.dart';

class PropertiesRepository extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Get properties with filters and pagination
  Future<UnifiedPropertyResponse> getProperties({
    required UnifiedFilterModel filters,
    required int page,
    required int limit,
    bool useCache = true,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        // Convert UnifiedFilterModel to query params
        ..._convertFiltersToQueryParams(filters),
      };

      DebugLogger.api('🔍 Fetching properties: page=$page, limit=$limit, filters=${filters.activeFilterCount} active');

      final response = await _apiClient.request<UnifiedPropertyResponse>(
        '/properties',
        (json) => _parseUnifiedPropertyResponse(json),
        queryParameters: queryParams,
        useCache: useCache,
        operationName: 'Get Properties',
      );

      DebugLogger.success('✅ Fetched ${response.properties.length} properties (page $page/${response.totalPages})');
      return response;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch properties: $e');
      rethrow;
    }
  }

  // Get single property details
  Future<PropertyModel> getPropertyDetail(int propertyId) async {
    try {
      DebugLogger.api('🏠 Fetching property details: $propertyId');

      final property = await _apiClient.request<PropertyModel>(
        '/properties/$propertyId',
        (json) => PropertyModel.fromJson(json),
        useCache: true,
        operationName: 'Get Property Detail',
      );

      DebugLogger.success('✅ Property details fetched: ${property.title}');
      return property;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch property $propertyId: $e');
      rethrow;
    }
  }

  // Get multiple property details by IDs (for likes page)
  Future<List<PropertyModel>> getPropertiesByIds(List<int> propertyIds) async {
    if (propertyIds.isEmpty) return [];

    try {
      DebugLogger.api('🏠 Fetching ${propertyIds.length} properties by IDs');

      // Fetch properties concurrently but limit concurrent requests
      const batchSize = 10;
      final List<PropertyModel> allProperties = [];

      for (int i = 0; i < propertyIds.length; i += batchSize) {
        final batch = propertyIds.skip(i).take(batchSize).toList();
        final futures = batch.map((id) => getPropertyDetail(id));
        
        try {
          final batchResults = await Future.wait(futures);
          allProperties.addAll(batchResults);
        } catch (e) {
          DebugLogger.warning('⚠️ Some properties failed to load in batch: $e');
          // Continue with partial results
        }
      }

      DebugLogger.success('✅ Loaded ${allProperties.length}/${propertyIds.length} properties');
      return allProperties;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch properties by IDs: $e');
      rethrow;
    }
  }

  // Search properties (same as getProperties but for consistency)
  Future<UnifiedPropertyResponse> searchProperties({
    required UnifiedFilterModel filters,
    required int page,
    required int limit,
    bool useCache = false, // Search results shouldn't be cached as much
  }) async {
    return getProperties(
      filters: filters,
      page: page,
      limit: limit,
      useCache: useCache,
    );
  }

  // Load all pages for map view
  Future<List<PropertyModel>> loadAllPropertiesForMap({
    required UnifiedFilterModel filters,
    int limit = 100,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      DebugLogger.api('🗺️ Loading all properties for map view');
      
      final List<PropertyModel> allProperties = [];
      int currentPage = 1;
      int totalPages = 1;

      do {
        final response = await getProperties(
          filters: filters,
          page: currentPage,
          limit: limit,
          useCache: true,
        );

        allProperties.addAll(response.properties);
        totalPages = response.totalPages;
        
        onProgress?.call(currentPage, totalPages);
        
        DebugLogger.api('📄 Loaded page $currentPage/$totalPages (${allProperties.length} total properties)');
        
        currentPage++;
      } while (currentPage <= totalPages);

      DebugLogger.success('✅ Loaded all ${allProperties.length} properties for map');
      return allProperties;
    } catch (e) {
      DebugLogger.error('❌ Failed to load all properties for map: $e');
      rethrow;
    }
  }

  // Helper method to parse unified property response
  UnifiedPropertyResponse _parseUnifiedPropertyResponse(Map<String, dynamic> json) {
    try {
      // Validate and clean properties data
      if (json['properties'] is List) {
        final propertiesList = json['properties'] as List;
        // Keep as raw maps to avoid nested model instances in JSON
        final validProperties = <Map<String, dynamic>>[];
        
        for (int i = 0; i < propertiesList.length; i++) {
          final propertyData = propertiesList[i];
          if (propertyData is Map<String, dynamic>) {
            try {
              // Validate by parsing, but store the raw JSON map
              PropertyModel.fromJson(propertyData);
              validProperties.add(propertyData);
            } catch (e) {
              DebugLogger.warning('⚠️ Skipping invalid property at index $i: $e');
            }
          }
        }
        
        // Replace with validated properties
        json['properties'] = validProperties;
      }
      
      return UnifiedPropertyResponse.fromJson(json);
    } catch (e) {
      DebugLogger.error('❌ Failed to parse property response: $e');
      rethrow;
    }
  }

  // Clear repository cache
  void clearCache() {
    _apiClient.clearCache();
    DebugLogger.api('🧹 Properties repository cache cleared');
  }

  // Helper method to convert UnifiedFilterModel to query parameters
  Map<String, String> _convertFiltersToQueryParams(UnifiedFilterModel filters) {
    final params = <String, String>{};
    final json = filters.toJson();
    
    // Convert each non-null value to string
    json.forEach((key, value) {
      if (value != null) {
        if (value is List) {
          if (value.isNotEmpty) {
            params[key] = value.join(',');
          }
        } else {
          params[key] = value.toString();
        }
      }
    });
    
    return params;
  }
}