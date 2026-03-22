// lib/core/controllers/app_update_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ghar360/core/data/models/app_update_models.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/widgets/common/app_update_dialog.dart';
import 'package:ghar360/features/splash/data/app_update_repository.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Result of attempting the native Android in-app update flow.
enum _NativeUpdateResult {
  /// Native update flow was successfully initiated (immediate or flexible).
  handled,

  /// Play Store confirmed no update is available (version not yet published).
  notOnStore,

  /// Native in-app update API is not supported (sideloaded, debug build, etc.).
  unsupported,
}

/// Controller for managing app update checks and prompts.
///
/// Uses Firebase Remote Config for version checking and in_app_update for
/// Android's native Play Store update flow. Mandatory updates always show;
/// optional updates are suppressed once the user skips a given version.
class AppUpdateController extends GetxService with WidgetsBindingObserver {
  static const String _appIdentifier = 'user';
  static const String _skippedVersionKey = 'skipped_app_version';
  static const Duration _checkThrottle = Duration(minutes: 5);
  static const Duration _postActionCooldown = Duration(minutes: 30);

  final AppUpdateRepository _repository = Get.find();

  final RxBool isChecking = false.obs;

  bool _isDialogVisible = false;
  AppVersionInfo? _currentVersionInfo;
  DateTime? _lastCheckAt;
  DateTime? _lastUpdateActionAt;

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

  /// Triggered when app comes to foreground - throttled check
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_lastCheckAt != null && now.difference(_lastCheckAt!) < _checkThrottle) {
        return;
      }
      // Enforce a longer cooldown after the user already acted on an update
      // prompt to prevent the dialog re-appearing immediately when returning
      // from the Play Store (where the version may not yet be live).
      if (_lastUpdateActionAt != null &&
          now.difference(_lastUpdateActionAt!) < _postActionCooldown) {
        DebugLogger.debug(
          'Skipping update check: user acted on update prompt '
          '${now.difference(_lastUpdateActionAt!).inMinutes}m ago',
        );
        return;
      }
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

      _lastCheckAt = DateTime.now();

      if (!response.updateAvailable) {
        DebugLogger.debug('App is up to date (${versionInfo.version})');
        return;
      }

      // Clear skipped version when a mandatory update is detected
      if (response.isMandatory) {
        GetStorage().remove(_skippedVersionKey);
      }

      // Skip dialog for non-mandatory updates the user already dismissed
      if (!response.isMandatory) {
        final skippedVersion = GetStorage().read<String>(_skippedVersionKey);
        if (skippedVersion == response.latestVersion) {
          DebugLogger.debug(
            'Skipping update dialog - user previously '
            'dismissed v${response.latestVersion}',
          );
          return;
        }
      }

      // Try native in-app update for Android first
      if (GetPlatform.isAndroid) {
        final nativeResult = await _tryNativeAndroidUpdate(response.isMandatory);
        switch (nativeResult) {
          case _NativeUpdateResult.handled:
            return; // Native update flow handled it
          case _NativeUpdateResult.notOnStore:
            // Play Store authoritatively says no update exists — Remote Config
            // is ahead of what's been published. Do not show a custom dialog.
            DebugLogger.info(
              'Remote Config reports v${response.latestVersion} but '
              'Play Store has no update available. Skipping dialog.',
            );
            return;
          case _NativeUpdateResult.unsupported:
            break; // Fall through to custom dialog (sideloaded / debug build)
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

  /// Try to use Android's native in-app update API.
  /// Returns a [_NativeUpdateResult] distinguishing between:
  /// - [_NativeUpdateResult.handled]: native flow used successfully
  /// - [_NativeUpdateResult.notOnStore]: Play Store confirmed no update exists
  /// - [_NativeUpdateResult.unsupported]: native API unavailable (sideloaded/debug)
  Future<_NativeUpdateResult> _tryNativeAndroidUpdate(bool isMandatory) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      DebugLogger.debug(
        'In-app update check: availability=${updateInfo.updateAvailability}, '
        'immediateAllowed=${updateInfo.immediateUpdateAllowed}, '
        'flexibleAllowed=${updateInfo.flexibleUpdateAllowed}',
      );

      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        // Play Store explicitly says no update is available.
        // This means Remote Config may be ahead of what's been published.
        DebugLogger.debug('No update available via Play Store native API');
        return _NativeUpdateResult.notOnStore;
      }

      if (isMandatory && updateInfo.immediateUpdateAllowed) {
        // Mandatory update: Use immediate flow (blocks the app)
        DebugLogger.info('Starting immediate (mandatory) update');
        await InAppUpdate.performImmediateUpdate();
        return _NativeUpdateResult.handled;
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Optional update: Use flexible flow (downloads in background)
        DebugLogger.info('Starting flexible update');
        await InAppUpdate.startFlexibleUpdate();
        // Complete the update when ready
        await InAppUpdate.completeFlexibleUpdate();
        return _NativeUpdateResult.handled;
      }

      return _NativeUpdateResult.unsupported;
    } on PlatformException catch (e) {
      // in_app_update not supported (e.g., not installed from Play Store)
      DebugLogger.debug('Native in-app update not available: ${e.message}');
      return _NativeUpdateResult.unsupported;
    } catch (e, stackTrace) {
      DebugLogger.warning('Native in-app update failed', e, stackTrace);
      return _NativeUpdateResult.unsupported;
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
        barrierColor: AppDesignTokens.neutral900.withValues(alpha: 0.54),
      );

      if (response.isMandatory) {
        if (action == AppUpdateAction.update) {
          _lastUpdateActionAt = DateTime.now();
          await _openDownloadUrl(response.downloadUrl);
        }
        // Do not recursively re-show. The lifecycle observer
        // (didChangeAppLifecycleState) will re-trigger the check when the
        // user returns from the store, subject to _postActionCooldown.
        return;
      }

      // Optional update handling
      switch (action) {
        case AppUpdateAction.update:
          _lastUpdateActionAt = DateTime.now();
          await _openDownloadUrl(response.downloadUrl);
          break;
        case AppUpdateAction.remindLater:
        case null:
          // Store skipped version so we don't prompt again
          if (response.latestVersion != null) {
            GetStorage().write(_skippedVersionKey, response.latestVersion);
          }
          DebugLogger.debug(
            'User skipped optional update '
            'v${response.latestVersion}',
          );
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
