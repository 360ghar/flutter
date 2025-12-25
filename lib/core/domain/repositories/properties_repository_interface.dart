import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/domain/result.dart';

/// Repository interface for property data operations.
/// Implementations should handle data fetching, caching, and error mapping.
abstract class IPropertiesRepository {
  /// Fetches properties based on location and filters.
  Future<Result<List<PropertyModel>>> getProperties({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 20,
  });

  /// Fetches a single property by ID.
  Future<Result<PropertyModel>> getPropertyById(String propertyId);

  /// Searches properties by query string.
  Future<Result<List<PropertyModel>>> searchProperties({
    required String query,
    UnifiedFilterModel? filters,
    int page = 1,
    int limit = 20,
  });

  /// Gets liked properties for the current user.
  Future<Result<List<PropertyModel>>> getLikedProperties({int page = 1, int limit = 20});

  /// Gets passed properties for the current user.
  Future<Result<List<PropertyModel>>> getPassedProperties({int page = 1, int limit = 20});

  /// Clears the local property cache.
  void clearCache();
}
