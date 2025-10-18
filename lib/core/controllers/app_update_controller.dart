// lib/core/controllers/app_update_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ghar360/core/data/models/app_update_models.dart';
import 'package:ghar360/core/data/repositories/app_update_repository.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/widgets/common/app_update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateController extends GetxService with WidgetsBindingObserver {
  AppUpdateController({GetStorage? storage}) : _storage = storage ?? GetStorage();

  static const Duration _minimumCheckInterval = Duration(hours: 24);
  static const String _appIdentifier = 'user';
  static const String _lastCheckKey = 'app_update:last_check_at';
  static const String _dismissedVersionKey = 'app_update:last_dismissed_version';

  final AppUpdateRepository _repository = Get.find();
  final GetStorage _storage;

  final RxBool isChecking = false.obs;

  AppVersionCheckResponse? _lastResponse;
  DateTime? _lastCheck;
  bool _isDialogVisible = false;
  AppVersionInfo? _currentVersionInfo;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _lastCheck = _readLastCheckFromStorage();
  }

  @override
  void onReady() {
    super.onReady();
    // Restore initial app-update check on cold start so that
    // unauthenticated/onboarding sessions also receive prompts.
    scheduleCheckAfterFirstFrame(force: true);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForUpdates());
    }
  }

  Future<void> _checkForUpdates({bool force = false}) async {
    if (isChecking.value || _isDialogVisible) {
      return;
    }

    final versionInfo = await _loadCurrentVersion(force: force);
    if (versionInfo == null) {
      DebugLogger.warning('Skipping app version check: unable to read package info');
      return;
    }

    final now = DateTime.now();
    final hasMandatoryResponse =
        _lastResponse?.updateAvailable == true && _lastResponse!.isMandatory;

    if (!force && !hasMandatoryResponse) {
      final lastCheck = _lastCheck ?? _readLastCheckFromStorage();
      if (lastCheck != null && now.difference(lastCheck) < _minimumCheckInterval) {
        DebugLogger.debug('Skipping version check - last check at $lastCheck');
        return;
      }
    }

    final request = AppVersionCheckRequest(
      app: _appIdentifier,
      platform: _resolvePlatform(),
      currentVersion: versionInfo.version,
      buildNumber: versionInfo.buildNumber,
    );

    try {
      isChecking.value = true;
      final response = await _repository.checkForUpdates(request);
      _lastCheck = now;
      _saveLastCheck(now);

      if (!response.updateAvailable) {
        _lastResponse = null;
        _clearDismissedVersion();
        DebugLogger.debug('App is up to date.');
        return;
      }

      _lastResponse = response;

      if (!response.isMandatory && _shouldSkipOptionalPrompt(response.latestVersion)) {
        DebugLogger.debug('Optional update ${response.latestVersion} already dismissed.');
        return;
      }

      await _showUpdateDialog(response, versionInfo);
    } catch (e, stackTrace) {
      DebugLogger.warning('App update check failed', e, stackTrace);
    } finally {
      isChecking.value = false;
    }
  }

  /// Public method to schedule an update check after the first frame
  void scheduleCheckAfterFirstFrame({bool force = false}) {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_checkForUpdates(force: force));
      });
    } catch (_) {
      // Fallback to immediate check
      unawaited(_checkForUpdates(force: force));
    }
  }

  Future<AppVersionInfo?> _loadCurrentVersion({bool force = false}) async {
    if (!force && _currentVersionInfo != null) {
      return _currentVersionInfo;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final buildNumber = int.tryParse(packageInfo.buildNumber);
      _currentVersionInfo = AppVersionInfo(version: packageInfo.version, buildNumber: buildNumber);
      return _currentVersionInfo;
    } catch (e, stackTrace) {
      DebugLogger.warning('Failed to read package info', e, stackTrace);
      return _currentVersionInfo;
    }
  }

  Future<AppVersionInfo?> getVersionInfo({bool forceRefresh = false}) {
    return _loadCurrentVersion(force: forceRefresh);
  }

  String? get currentVersion => _currentVersionInfo?.version;

  int? get currentBuildNumber => _currentVersionInfo?.buildNumber;

  Future<void> _showUpdateDialog(
    AppVersionCheckResponse response,
    AppVersionInfo versionInfo,
  ) async {
    if (_isDialogVisible) {
      return;
    }

    _isDialogVisible = true;

    try {
      final action = await Get.dialog<AppUpdateAction?>(
        AppUpdateDialog(response: response, currentVersion: versionInfo.version),
        barrierDismissible: !response.isMandatory,
        barrierColor: Colors.black54,
      );

      if (response.isMandatory) {
        if (action == AppUpdateAction.update) {
          await _openDownloadUrl(response.downloadUrl);
          // After redirecting user, keep dialog blocked next time unless updated
          _lastResponse = response;
        } else {
          // Mandatory dialog should not be dismissible, but handle defensively
          _isDialogVisible = false;
          await _showUpdateDialog(response, versionInfo);
        }
        return;
      }

      switch (action) {
        case AppUpdateAction.update:
          await _openDownloadUrl(response.downloadUrl);
          break;
        case AppUpdateAction.remindLater:
        case null:
          _rememberDismissedVersion(response.latestVersion);
          break;
      }
    } finally {
      _isDialogVisible = false;
    }
  }

  Future<void> _openDownloadUrl(String? url) async {
    if (url == null || url.isEmpty) {
      DebugLogger.warning('No download URL provided for update');
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        DebugLogger.warning('Failed to launch update URL: $url');
      }
    } catch (e, stackTrace) {
      DebugLogger.warning('Error launching update URL: $url', e, stackTrace);
    }
  }

  String _resolvePlatform() {
    if (kIsWeb || GetPlatform.isWeb) {
      return 'web';
    }
    if (GetPlatform.isIOS) {
      return 'ios';
    }
    if (GetPlatform.isAndroid) {
      return 'android';
    }
    return 'android';
  }

  bool _shouldSkipOptionalPrompt(String? latestVersion) {
    if (latestVersion == null || latestVersion.isEmpty) {
      return false;
    }
    final dismissed = _storage.read(_dismissedVersionKey);
    if (dismissed is String && dismissed == latestVersion) {
      return true;
    }
    return false;
  }

  void _rememberDismissedVersion(String? latestVersion) {
    if (latestVersion == null || latestVersion.isEmpty) {
      return;
    }
    _storage.write(_dismissedVersionKey, latestVersion);
  }

  void _clearDismissedVersion() {
    if (_storage.hasData(_dismissedVersionKey)) {
      _storage.remove(_dismissedVersionKey);
    }
  }

  DateTime? _readLastCheckFromStorage() {
    final stored = _storage.read(_lastCheckKey);
    if (stored is String) {
      return DateTime.tryParse(stored);
    }
    return null;
  }

  void _saveLastCheck(DateTime timestamp) {
    _storage.write(_lastCheckKey, timestamp.toIso8601String());
  }
}
