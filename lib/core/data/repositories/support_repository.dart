import 'package:get/get.dart';

import '../../utils/app_exceptions.dart';
import '../../utils/debug_logger.dart';
import '../models/bug_report_model.dart';
import '../providers/api_service.dart';

/// Repository responsible for support and feedback related network calls.
class SupportRepository extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  Future<BugReportResponse> submitBugReport(BugReportRequest request) async {
    try {
      DebugLogger.info('📝 Submitting bug report: ${request.title} (${request.bugType.value})');
      final response = await _apiService.submitBugReport(request);
      DebugLogger.success('✅ Bug report submitted (id=${response.id})');
      return response;
    } on AppException catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to submit bug report: ${e.message}', e, stackTrace);
      rethrow;
    }
  }
}
