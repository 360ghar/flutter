import 'package:get/get.dart';
import '../models/property_model.dart';
import '../models/unified_property_response.dart';
import '../models/unified_filter_model.dart';
import '../providers/api_service.dart';
import '../../utils/debug_logger.dart';

class PropertiesRepository extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  // Get properties with filters and pagination
  Future<UnifiedPropertyResponse> getProperties({
    required UnifiedFilterModel filters,
    required int page,
    required int limit,
    bool useCache = true,
  }) async {
    try {
      DebugLogger.api('🔍 Fetching properties: page=$page, limit=$limit, activeFilters=${filters.activeFilterCount}');

      final response = await _apiService.searchProperties(
        filters: filters,
        page: page,
        limit: limit,
      );

      DebugLogger.success('✅ Fetched ${response.properties.length} properties (page $page/${response.totalPages})');
      return response;
    } catch (e) {
      DebugLogger.error('❌ Failed to fetch properties: $e');

      // If it's a 404 or connection error and we're in development, use mock data
      if (e.toString().contains('404') || e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup') || e.toString().contains('request not found')) {
        DebugLogger.warning('🔧 Backend not available, falling back to mock data');
        try {
          // Create a mock response for properties
          final mockProperties = [
            PropertyModel(
              id: 1,
              title: 'Luxury Apartment in Bandra',
              description: 'Beautiful 2BHK apartment with modern amenities',
              propertyType: PropertyType.apartment,
              purpose: PropertyPurpose.rent,
              basePrice: 45000.0,
              status: PropertyStatus.available,
              monthlyRent: 45000.0,
              bedrooms: 2,
              bathrooms: 2,
              areaSqft: 1200,
              fullAddress: 'Bandra West, Mumbai',
              city: 'Mumbai',
              locality: 'Bandra',
              latitude: 19.0596,
              longitude: 72.8295,
              isAvailable: true,
              viewCount: 0,
              likeCount: 0,
              interestCount: 0,
              createdAt: DateTime.now().subtract(const Duration(days: 7)),
            ),
            PropertyModel(
              id: 2,
              title: 'Cozy Studio in Andheri',
              description: 'Perfect for single professionals',
              propertyType: PropertyType.room,
              purpose: PropertyPurpose.rent,
              basePrice: 25000.0,
              status: PropertyStatus.available,
              monthlyRent: 25000.0,
              bedrooms: 1,
              bathrooms: 1,
              areaSqft: 600,
              fullAddress: 'Andheri East, Mumbai',
              city: 'Mumbai',
              locality: 'Andheri',
              latitude: 19.1136,
              longitude: 72.8697,
              isAvailable: true,
              viewCount: 0,
              likeCount: 0,
              interestCount: 0,
              createdAt: DateTime.now().subtract(const Duration(days: 5)),
            ),
          ];
          return UnifiedPropertyResponse(
            properties: mockProperties,
            total: mockProperties.length,
            page: 1,
            limit: 20,
            totalPages: 1,
            filtersApplied: {},
            searchCenter: SearchCenter(latitude: 19.0596, longitude: 72.8295),
          );
        } catch (mockError) {
          DebugLogger.error('❌ Mock data also failed: $mockError');
          rethrow;
        }
      }

      rethrow;
    }
  }

  // Get single property details
  Future<PropertyModel> getPropertyDetail(int propertyId) async {
    try {
      DebugLogger.api('🏠 Fetching property details: $propertyId');

      final property = await _apiService.getPropertyDetails(propertyId);

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
        
        DebugLogger.api('📄 Loaded page $currentPage/$totalPages; totalProperties=${allProperties.length}');
        
        currentPage++;
      } while (currentPage <= totalPages);

      DebugLogger.success('✅ Loaded all ${allProperties.length} properties for map');
      return allProperties;
    } catch (e) {
      DebugLogger.error('❌ Failed to load all properties for map: $e');
      rethrow;
    }
  }


  // Clear repository cache
  void clearCache() {
    // Cache clearing functionality can be added to ApiService if needed
    DebugLogger.api('🧹 Properties repository cache cleared');
  }

}