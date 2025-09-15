// lib/core/data/repositories/app_update_repository.dart

import 'package:get/get.dart';

import '../../utils/debug_logger.dart';
import '../models/app_update_models.dart';
import '../providers/api_service.dart';

class AppUpdateRepository extends GetxService {
  final ApiService _apiService = Get.find();

  Future<AppVersionCheckResponse> checkForUpdates(
    AppVersionCheckRequest request,
  ) async {
    try {
      final response = await _apiService.checkAppVersion(request: request);
      DebugLogger.info(
        'App update check completed. Update available: ${response.updateAvailable}',
      );
      return response;
    } catch (e, stackTrace) {
      DebugLogger.warning('Failed to check for app updates', e, stackTrace);
      rethrow;
    }
  }
}
