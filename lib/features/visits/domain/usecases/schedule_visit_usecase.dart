import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/domain/result.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_mapper.dart';
import 'package:ghar360/features/visits/data/datasources/visits_remote_datasource.dart';

/// Use case for scheduling property visits.
class ScheduleVisitUseCase {
  final VisitsRemoteDatasource _datasource;

  ScheduleVisitUseCase(this._datasource);

  Future<Result<VisitModel>> execute({
    required int propertyId,
    required DateTime scheduledDate,
    String? specialRequirements,
  }) async {
    // Business logic: validate inputs
    if (propertyId <= 0) {
      return Result.failure(ValidationException('Invalid property ID'));
    }

    if (scheduledDate.isBefore(DateTime.now())) {
      return Result.failure(ValidationException('Cannot schedule visit in the past'));
    }

    try {
      final visit = await _datasource.scheduleVisit(
        propertyId: propertyId,
        scheduledDate: scheduledDate.toUtc().toIso8601String(),
        specialRequirements: specialRequirements,
      );
      return Result.success(visit);
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to schedule visit', e, stackTrace);
      return Result.failure(ErrorMapper.mapApiError(e, stackTrace));
    }
  }
}
