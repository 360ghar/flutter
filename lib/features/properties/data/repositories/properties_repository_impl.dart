import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/domain/repositories/properties_repository_interface.dart';
import 'package:ghar360/core/domain/result.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_mapper.dart';
import 'package:ghar360/features/properties/data/datasources/properties_remote_datasource.dart';

/// Implementation of IPropertiesRepository using remote datasource.
class PropertiesRepositoryImpl implements IPropertiesRepository {
  final PropertiesRemoteDatasource _remoteDatasource;

  PropertiesRepositoryImpl(this._remoteDatasource);

  @override
  Future<Result<List<PropertyModel>>> getProperties({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final properties = await _remoteDatasource.fetchProperties(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        filters: filters,
        page: page,
        limit: limit,
      );
      return Result.success(properties);
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to get properties', e, stackTrace);
      final exception = ErrorMapper.mapApiError(e, stackTrace);
      return Result.failure(exception);
    }
  }

  @override
  Future<Result<PropertyModel>> getPropertyById(String propertyId) async {
    try {
      final property = await _remoteDatasource.fetchPropertyById(propertyId);
      return Result.success(property);
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to get property by ID', e, stackTrace);
      final exception = ErrorMapper.mapApiError(e, stackTrace);
      return Result.failure(exception);
    }
  }

  @override
  Future<Result<List<PropertyModel>>> searchProperties({
    required String query,
    double? latitude,
    double? longitude,
    double? radiusKm,
    UnifiedFilterModel? filters,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final properties = await _remoteDatasource.searchProperties(
        query: query,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        filters: filters,
        page: page,
        limit: limit,
      );
      return Result.success(properties);
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to search properties', e, stackTrace);
      final exception = ErrorMapper.mapApiError(e, stackTrace);
      return Result.failure(exception);
    }
  }

  @override
  Future<Result<List<PropertyModel>>> getLikedProperties({int page = 1, int limit = 20}) async {
    // TODO: Implement liked properties endpoint
    return Result.failure(ServerException('Not yet implemented: liked properties endpoint'));
  }

  @override
  Future<Result<List<PropertyModel>>> getPassedProperties({int page = 1, int limit = 20}) async {
    // TODO: Implement passed properties endpoint
    return Result.failure(ServerException('Not yet implemented: passed properties endpoint'));
  }

  @override
  void clearCache() {
    // Cache clearing is handled by ApiClient
    DebugLogger.info('Properties cache cleared');
  }
}
