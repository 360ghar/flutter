import 'package:get/get.dart';

import 'package:ghar360/core/data/models/bug_report_model.dart';
import 'package:ghar360/core/data/providers/api_service.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Repository responsible for support and feedback related network calls.
class SupportRepository extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<BugReportResponse> submitBugReport(BugReportRequest request) async {
    try {
      DebugLogger.info('📝 Submitting bug report: ${request.bugType.value}');
      final response = await _apiService.submitBugReport(request);
      DebugLogger.success(
        '✅ Bug report submitted (id=${response.id.toString().substring(0, 8)}...)',
      );
      return response;
    } on AppException catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to submit bug report: ${e.message}', e, stackTrace);
      rethrow;
    } catch (e, st) {
      DebugLogger.error('❌ Unexpected error submitting bug report: $e', e, st);
      throw ServerException(
        'Unexpected error occurred while submitting bug report',
        details: 'Original error: $e',
      );
    }
  }
}
