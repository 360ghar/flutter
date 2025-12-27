import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/data/models/unified_filter_model.dart';
import 'package:ghar360/core/domain/repositories/properties_repository_interface.dart';
import 'package:ghar360/core/domain/result.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';

/// Use case for fetching properties based on location and filters.
class GetPropertiesUseCase {
  final IPropertiesRepository _repository;

  GetPropertiesUseCase(this._repository);

  /// Executes the use case to fetch properties.
  Future<Result<List<PropertyModel>>> execute({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required UnifiedFilterModel filters,
    int page = 1,
    int limit = 20,
  }) async {
    // Business logic: validate inputs
    if (latitude < -90 || latitude > 90) {
      return Result.failure(ValidationException('Invalid latitude: $latitude'));
    }

    if (longitude < -180 || longitude > 180) {
      return Result.failure(ValidationException('Invalid longitude: $longitude'));
    }

    if (radiusKm <= 0 || radiusKm > 500) {
      return Result.failure(
        ValidationException('Invalid radius: $radiusKm (must be between 0 and 500 km)'),
      );
    }

    // Delegate to repository
    return _repository.getProperties(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      filters: filters,
      page: page,
      limit: limit,
    );
  }
}
