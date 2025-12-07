// lib/core/controllers/app_update_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ghar360/core/data/models/app_update_models.dart';
import 'package:ghar360/core/data/repositories/app_update_repository.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/widgets/common/app_update_dialog.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Controller for managing app update checks and prompts.
///
/// Uses Firebase Remote Config for version checking and in_app_update for
/// Android's native Play Store update flow. Shows update popup on every app
/// open until the user updates, even if they click "Skip".
class AppUpdateController extends GetxService with WidgetsBindingObserver {
  static const String _appIdentifier = 'user';

  final AppUpdateRepository _repository = Get.find();

  final RxBool isChecking = false.obs;

  bool _isDialogVisible = false;
  AppVersionInfo? _currentVersionInfo;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    // Check for updates on cold start
    scheduleCheckAfterFirstFrame();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Triggered when app comes to foreground - check for updates every time
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for updates every time app resumes (no throttling)
      unawaited(_checkForUpdates());
    }
  }

  /// Main update check logic
  Future<void> _checkForUpdates() async {
    if (isChecking.value || _isDialogVisible) {
      return;
    }

    // Skip on web
    if (kIsWeb) {
      DebugLogger.debug('Skipping app update check on web platform');
      return;
    }

    final versionInfo = await _loadCurrentVersion();
    if (versionInfo == null) {
      DebugLogger.warning('Skipping app version check: unable to read package info');
      return;
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

      if (!response.updateAvailable) {
        DebugLogger.debug('App is up to date (${versionInfo.version})');
        return;
      }

      // Try native in-app update for Android first
      if (GetPlatform.isAndroid) {
        final usedNativeUpdate = await _tryNativeAndroidUpdate(response.isMandatory);
        if (usedNativeUpdate) {
          return; // Native update flow handled it
        }
      }

      // Fall back to custom dialog (iOS, or Android if native fails)
      await _showUpdateDialog(response, versionInfo);
    } catch (e, stackTrace) {
      DebugLogger.warning('App update check failed', e, stackTrace);
    } finally {
      isChecking.value = false;
    }
  }

  /// Try to use Android's native in-app update API
  /// Returns true if native update flow was used, false otherwise
  Future<bool> _tryNativeAndroidUpdate(bool isMandatory) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      DebugLogger.debug(
        'In-app update check: availability=${updateInfo.updateAvailability}, '
        'immediateAllowed=${updateInfo.immediateUpdateAllowed}, '
        'flexibleAllowed=${updateInfo.flexibleUpdateAllowed}',
      );

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        // No update available via Play Store yet (might be recently published)
        DebugLogger.debug('No update available via Play Store native API');
        return false;
      }

      if (isMandatory && updateInfo.immediateUpdateAllowed) {
        // Mandatory update: Use immediate flow (blocks the app)
        DebugLogger.info('Starting immediate (mandatory) update');
        await InAppUpdate.performImmediateUpdate();
        return true;
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Optional update: Use flexible flow (downloads in background)
        DebugLogger.info('Starting flexible update');
        await InAppUpdate.startFlexibleUpdate();
        // Complete the update when ready
        await InAppUpdate.completeFlexibleUpdate();
        return true;
      }

      return false;
    } on PlatformException catch (e) {
      // in_app_update not supported (e.g., not installed from Play Store)
      DebugLogger.debug('Native in-app update not available: ${e.message}');
      return false;
    } catch (e, stackTrace) {
      DebugLogger.warning('Native in-app update failed', e, stackTrace);
      return false;
    }
  }

  /// Schedule an update check after the first frame renders
  void scheduleCheckAfterFirstFrame() {
    try {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_checkForUpdates());
      });
    } catch (_) {
      // Fallback to immediate check
      unawaited(_checkForUpdates());
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

  /// Public getter for version info
  Future<AppVersionInfo?> getVersionInfo({bool forceRefresh = false}) {
    return _loadCurrentVersion(force: forceRefresh);
  }

  String? get currentVersion => _currentVersionInfo?.version;

  int? get currentBuildNumber => _currentVersionInfo?.buildNumber;

  /// Shows the update dialog
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
        } else {
          // Mandatory dialog dismissed somehow - show it again
          _isDialogVisible = false;
          await _showUpdateDialog(response, versionInfo);
        }
        return;
      }

      // Optional update handling
      switch (action) {
        case AppUpdateAction.update:
          await _openDownloadUrl(response.downloadUrl);
          break;
        case AppUpdateAction.remindLater:
        case null:
          // User clicked "Skip" or dismissed - popup will show again next time
          // (No longer storing dismissed version)
          DebugLogger.debug('User skipped optional update - will show again on next app open');
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
}
