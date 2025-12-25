import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/domain/result.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_mapper.dart';
import 'package:ghar360/features/visits/data/datasources/visits_remote_datasource.dart';

/// Use case for fetching visits.
class GetVisitsUseCase {
  final VisitsRemoteDatasource _datasource;

  GetVisitsUseCase(this._datasource);

  Future<Result<List<VisitModel>>> execute({int page = 1, int limit = 50}) async {
    try {
      final visits = await _datasource.fetchVisits(page: page, limit: limit);
      return Result.success(visits);
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to fetch visits', e, stackTrace);
      return Result.failure(ErrorMapper.mapApiError(e, stackTrace));
    }
  }
}
