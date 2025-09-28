// lib/core/data/repositories/app_update_repository.dart

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/app_update_models.dart';
import 'package:ghar360/core/data/providers/api_service.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

class AppUpdateRepository extends GetxService {
  final ApiService _apiService = Get.find();

  Future<AppVersionCheckResponse> checkForUpdates(AppVersionCheckRequest request) async {
    try {
      final response = await _apiService.checkAppVersion(request: request);
      DebugLogger.info('App update check completed. Update available: ${response.updateAvailable}');
      return response;
    } on NotFoundException catch (e, stackTrace) {
      DebugLogger.warning('App update endpoint unavailable, skipping check', e, stackTrace);
      return const AppVersionCheckResponse(updateAvailable: false, isMandatory: false);
    } catch (e, stackTrace) {
      DebugLogger.warning('Failed to check for app updates', e, stackTrace);
      rethrow;
    }
  }
}
