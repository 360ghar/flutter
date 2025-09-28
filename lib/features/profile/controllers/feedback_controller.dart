import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/bug_report_model.dart';
import 'package:ghar360/core/data/repositories/support_repository.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FeedbackController extends GetxController {
  FeedbackController({SupportRepository? supportRepository})
    : _supportRepository = supportRepository ?? Get.find<SupportRepository>();

  final SupportRepository _supportRepository;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final stepsController = TextEditingController();
  final expectedController = TextEditingController();
  final actualController = TextEditingController();
  final tagsController = TextEditingController();

  final Rx<BugType> selectedBugType = BugType.uiBug.obs;
  final Rx<BugSeverity> selectedSeverity = BugSeverity.medium.obs;
  final RxBool isSubmitting = false.obs;

  void setBugType(BugType? type) {
    if (type != null) {
      selectedBugType.value = type;
    }
  }

  void setSeverity(BugSeverity? severity) {
    if (severity != null) {
      selectedSeverity.value = severity;
    }
  }

  Future<void> submitFeedback() async {
    if (isSubmitting.value) return;
    final currentForm = formKey.currentState;
    if (currentForm == null || !currentForm.validate()) {
      return;
    }

    isSubmitting.value = true;
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final packageInfo = await _safePackageInfo();
      final deviceInfo = _buildDeviceInfo(packageInfo);
      final tags = _parseTags(tagsController.text);

      final request = BugReportRequest(
        source: 'mobile',
        bugType: selectedBugType.value,
        severity: selectedSeverity.value,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        stepsToReproduce: _optionalValue(stepsController.text),
        expectedBehavior: _optionalValue(expectedController.text),
        actualBehavior: _optionalValue(actualController.text),
        deviceInfo: deviceInfo,
        appVersion: _formatAppVersion(packageInfo),
        tags: tags.isEmpty ? null : tags,
      );

      final response = await _supportRepository.submitBugReport(request);
      DebugLogger.success('Feedback submitted with id=${response.id}');
      Get.back(result: response);
      Future.delayed(Duration.zero, () {
        Get.snackbar(
          'Feedback sent',
          'Thanks for helping us improve 360Ghar.',
          backgroundColor: AppColors.snackbarBackground,
          colorText: AppColors.snackbarText,
          duration: const Duration(seconds: 3),
        );
      });
    } on ValidationException catch (e) {
      final message =
          e.fieldErrors?.entries
              .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
              .join('\n') ??
          e.message;
      _showError(message);
    } on AppException catch (e) {
      _showError(e.message);
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error while submitting feedback', e, stackTrace);
      _showError('Something went wrong while sending your feedback. Please try again.');
    } finally {
      isSubmitting.value = false;
    }
  }

  List<String> _parseTags(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];
    final parts = trimmed.split(RegExp(r'[\n,]'));
    return parts
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Map<String, dynamic>? _buildDeviceInfo(PackageInfo? info) {
    final os = _platformLabel();
    final deviceLabel = _deviceLabel();

    final Map<String, dynamic> data = {
      if (os != null) 'os': os,
      if (deviceLabel != null) 'model': deviceLabel,
      if (info != null && info.version.isNotEmpty) 'app_version': _formatAppVersion(info),
    };

    if (data.isEmpty) return null;
    return data;
  }

  Future<PackageInfo?> _safePackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e, stackTrace) {
      DebugLogger.warning('Unable to read package info for feedback', e, stackTrace);
      return null;
    }
  }

  String? _formatAppVersion(PackageInfo? info) {
    if (info == null) return null;
    final buffer = StringBuffer(info.version);
    if (info.buildNumber.isNotEmpty) {
      buffer.write('+');
      buffer.write(info.buildNumber);
    }
    return buffer.toString();
  }

  String? _optionalValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _showError(String message) {
    Get.snackbar(
      'Feedback failed',
      message,
      backgroundColor: AppColors.errorRed,
      colorText: AppColors.snackbarText,
      duration: const Duration(seconds: 4),
    );
  }

  String? _platformLabel() {
    if (GetPlatform.isAndroid) return 'Android';
    if (GetPlatform.isIOS) return 'iOS';
    if (GetPlatform.isMacOS) return 'macOS';
    if (GetPlatform.isWindows) return 'Windows';
    if (GetPlatform.isLinux) return 'Linux';
    if (GetPlatform.isWeb) return 'Web';
    return null;
  }

  String? _deviceLabel() {
    if (GetPlatform.isAndroid) return 'Android Device';
    if (GetPlatform.isIOS) return 'iPhone/iPad';
    if (GetPlatform.isMacOS) return 'macOS Device';
    if (GetPlatform.isWindows) return 'Windows Device';
    if (GetPlatform.isLinux) return 'Linux Device';
    if (GetPlatform.isWeb) return 'Web Browser';
    return null;
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    stepsController.dispose();
    expectedController.dispose();
    actualController.dispose();
    tagsController.dispose();
    super.onClose();
  }
}
