import 'dart:convert';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/debug_logger.dart';
import '../models/property_model.dart';
import '../models/unified_filter_model.dart';

/// Enhanced API service for property-related operations
class PropertyApiService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get properties with filtering and pagination
  Future<List<PropertyModel>> getProperties({
    UnifiedFilterModel? filters,
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool useCache = true,
  }) async {
    try {
      DebugLogger.api('Fetching properties - page: $page, limit: $limit');

      // Build query parameters
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      // Add filters if provided
      if (filters != null) {
        if (filters.latitude != null && filters.longitude != null) {
          queryParams['latitude'] = filters.latitude;
          queryParams['longitude'] = filters.longitude;
          queryParams['radius_km'] = filters.radiusKm ?? 5.0;
        }

        if (filters.propertyType?.isNotEmpty == true) {
          queryParams['property_types'] = filters.propertyType!.join(',');
        }

        if (filters.purpose != null) {
          queryParams['purposes'] = filters.purpose;
        }

        if (filters.priceMin != null) {
          queryParams['min_price'] = filters.priceMin;
        }

        if (filters.priceMax != null) {
          queryParams['max_price'] = filters.priceMax;
        }

        if (filters.bedroomsMin != null) {
          queryParams['min_bedrooms'] = filters.bedroomsMin;
        }

        if (filters.bedroomsMax != null) {
          queryParams['max_bedrooms'] = filters.bedroomsMax;
        }

        if (filters.areaMin != null) {
          queryParams['min_area_sqft'] = filters.areaMin;
        }

        if (filters.areaMax != null) {
          queryParams['max_area_sqft'] = filters.areaMax;
        }
      }

      // Add search query
      if (searchQuery?.isNotEmpty == true) {
        queryParams['search'] = searchQuery;
      }

      DebugLogger.api('Query params: $queryParams');

      // Make API call
      final response = await _supabase.functions.invoke(
        'properties',
        body: queryParams,
      );

      DebugLogger.info('API Response status: ${response.status}');
      DebugLogger.info('API Response data type: ${response.data?.runtimeType}');
      
      if (response.data != null) {
        // Handle different response formats
        if (response.data is List) {
          // Direct array response
          final List<dynamic> propertiesJson = response.data as List;
          DebugLogger.success('Found ${propertiesJson.length} properties (direct array)');
          return propertiesJson.map((json) => PropertyModel.fromJson(json)).toList();
        } else if (response.data is Map) {
          // Nested response with properties key
          final List<dynamic> propertiesJson = response.data['properties'] ?? response.data['data'] ?? [];
          DebugLogger.success('Found ${propertiesJson.length} properties (nested object)');
          return propertiesJson.map((json) => PropertyModel.fromJson(json)).toList();
        }
      }

      DebugLogger.warning('No properties found in response');
      return [];
    } catch (e) {
      DebugLogger.error('Error fetching properties: $e');
      rethrow;
    }
  }

  /// Get property details by ID
  Future<PropertyModel?> getPropertyById(int propertyId) async {
    try {
      DebugLogger.api('Fetching property details - ID: $propertyId');

      final response = await _supabase.functions.invoke(
        'properties/$propertyId',
        method: HttpMethod.get,
      );

      if (response.data != null) {
        return PropertyModel.fromJson(response.data);
      }

      return null;
    } catch (e) {
      DebugLogger.error('Error fetching property details: $e');
      rethrow;
    }
  }

  /// Register a swipe (like/dislike) action
  Future<bool> registerSwipe({
    required int propertyId,
    required String action, // 'like' or 'dislike'
    String? feedback,
  }) async {
    try {
      DebugLogger.api('Registering swipe - Property: $propertyId, Action: $action');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'swipes',
        body: {
          'property_id': propertyId,
          'user_id': user.id,
          'action': action,
          'feedback': feedback,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.status == 200;
    } catch (e) {
      DebugLogger.error('Error registering swipe: $e');
      return false; // Return false on error for optimistic updates
    }
  }

  /// Store user location
  Future<bool> storeUserLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? state,
    String? country,
  }) async {
    try {
      DebugLogger.api('Storing user location: $latitude, $longitude');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'location',
        body: {
          'user_id': user.id,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'city': city,
          'state': state,
          'country': country,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.status == 200;
    } catch (e) {
      DebugLogger.error('Error storing user location: $e');
      return false;
    }
  }

  /// Store user preferences
  Future<bool> storeUserPreferences({
    required String location,
    required Map<String, dynamic> filters,
  }) async {
    try {
      DebugLogger.api('Storing user preferences');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase.functions.invoke(
        'users/preferences',
        body: {
          'user_id': user.id,
          'location': location,
          'filters': filters,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      return response.status == 200;
    } catch (e) {
      DebugLogger.error('Error storing user preferences: $e');
      return false;
    }
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      DebugLogger.api('Fetching user preferences');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      final response = await _supabase.functions.invoke(
        'users/preferences',
        method: HttpMethod.get,
      );

      if (response.data != null) {
        return response.data;
      }

      return null;
    } catch (e) {
      DebugLogger.error('Error fetching user preferences: $e');
      return null;
    }
  }

  /// Get user's liked properties
  Future<List<int>> getLikedProperties() async {
    try {
      DebugLogger.api('Fetching liked properties');

      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase.functions.invoke(
        'swipes/liked',
        method: HttpMethod.get,
      );

      if (response.data != null) {
        final List<dynamic> likedIds = response.data['property_ids'] ?? [];
        return likedIds.map((id) => id as int).toList();
      }

      return [];
    } catch (e) {
      DebugLogger.error('Error fetching liked properties: $e');
      return [];
    }
  }

  /// Get properties similar to a given property
  Future<List<PropertyModel>> getSimilarProperties(int propertyId) async {
    try {
      DebugLogger.api('Fetching similar properties for ID: $propertyId');

      final response = await _supabase.functions.invoke(
        'properties/$propertyId/similar',
        method: HttpMethod.get,
      );

      if (response.data != null) {
        final List<dynamic> propertiesJson = response.data['properties'] ?? [];
        return propertiesJson.map((json) => PropertyModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      DebugLogger.error('Error fetching similar properties: $e');
      return [];
    }
  }

  /// Search properties by text query
  Future<List<PropertyModel>> searchProperties(String query, {
    UnifiedFilterModel? filters,
    int limit = 20,
  }) async {
    try {
      DebugLogger.api('Searching properties: "$query"');

      final queryParams = <String, dynamic>{
        'search': query,
        'limit': limit,
      };

      // Add location filters if provided
      if (filters?.latitude != null && filters?.longitude != null) {
        queryParams['latitude'] = filters!.latitude;
        queryParams['longitude'] = filters.longitude;
        queryParams['radius_km'] = filters.radiusKm ?? 10.0;
      }

      final response = await _supabase.functions.invoke(
        'properties/search',
        body: queryParams,
      );

      if (response.data != null) {
        final List<dynamic> propertiesJson = response.data['properties'] ?? [];
        return propertiesJson.map((json) => PropertyModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      DebugLogger.error('Error searching properties: $e');
      return [];
    }
  }

  /// Get properties by location bounds (for map view)
  Future<List<PropertyModel>> getPropertiesInBounds({
    required double northEastLat,
    required double northEastLng,
    required double southWestLat,
    required double southWestLng,
    UnifiedFilterModel? filters,
    int limit = 100,
  }) async {
    try {
      DebugLogger.api('Fetching properties in bounds');

      final queryParams = <String, dynamic>{
        'bounds': {
          'northeast': {'lat': northEastLat, 'lng': northEastLng},
          'southwest': {'lat': southWestLat, 'lng': southWestLng},
        },
        'limit': limit,
      };

      // Add additional filters
      if (filters != null) {
        if (filters.propertyType?.isNotEmpty == true) {
          queryParams['property_types'] = filters.propertyType!.join(',');
        }

        if (filters.purpose != null) {
          queryParams['purposes'] = filters.purpose;
        }

        if (filters.priceMin != null) {
          queryParams['min_price'] = filters.priceMin;
        }

        if (filters.priceMax != null) {
          queryParams['max_price'] = filters.priceMax;
        }
      }

      final response = await _supabase.functions.invoke(
        'properties/bounds',
        body: queryParams,
      );

      if (response.data != null) {
        final List<dynamic> propertiesJson = response.data['properties'] ?? [];
        return propertiesJson.map((json) => PropertyModel.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      DebugLogger.error('Error fetching properties in bounds: $e');
      return [];
    }
  }

  /// Get popular locations for suggestions
  Future<List<String>> getPopularLocations() async {
    try {
      final response = await _supabase.functions.invoke(
        'locations/popular',
        method: HttpMethod.get,
      );

      if (response.data != null) {
        final List<dynamic> locations = response.data['locations'] ?? [];
        return locations.map((location) => location.toString()).toList();
      }

      return [];
    } catch (e) {
      DebugLogger.error('Error fetching popular locations: $e');
      return [];
    }
  }

  /// Cache management methods
  Future<void> clearCache() async {
    try {
      // Clear any local cache if implemented
      DebugLogger.info('Cache cleared');
    } catch (e) {
      DebugLogger.error('Error clearing cache: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    // Return cache statistics if caching is implemented
    return {
      'cache_enabled': false,
      'cached_items': 0,
      'cache_size': 0,
    };
  }
}
