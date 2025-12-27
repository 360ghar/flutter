import 'package:ghar360/core/domain/result.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/utils/error_mapper.dart';
import 'package:ghar360/features/swipes/data/datasources/swipes_remote_datasource.dart';

/// Use case for logging swipe actions.
class LogSwipeUseCase {
  final SwipesRemoteDatasource _datasource;

  LogSwipeUseCase(this._datasource);

  Future<Result<void>> execute({required String propertyId, required String action}) async {
    // Validate action
    const validActions = ['like', 'pass', 'super_like'];
    if (!validActions.contains(action)) {
      return Result.failure(
        ValidationException(
          'Invalid swipe action: $action. Must be one of: ${validActions.join(", ")}',
        ),
      );
    }

    try {
      await _datasource.logSwipe(propertyId: propertyId, action: action);
      return Result.success(null);
    } catch (e, stackTrace) {
      DebugLogger.error('Failed to log swipe', e, stackTrace);
      return Result.failure(ErrorMapper.mapApiError(e, stackTrace));
    }
  }
}
