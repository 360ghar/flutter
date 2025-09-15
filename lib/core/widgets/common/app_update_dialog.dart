// lib/core/widgets/common/app_update_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/app_update_models.dart';

enum AppUpdateAction { update, remindLater }

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.response,
    required this.currentVersion,
  });

  final AppVersionCheckResponse response;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMandatory = response.isMandatory;
    final releaseNotes = response.releaseNotes;
    final latestVersionLabel = response.latestVersion;
    final minSupportedVersion = response.minSupportedVersion;

    return WillPopScope(
      onWillPop: () async => !isMandatory,
      child: AlertDialog(
        title: Text(
          isMandatory ? 'Mandatory Update Required' : 'Update Available',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current version: $currentVersion',
                style: theme.textTheme.bodySmall,
              ),
              if (latestVersionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Latest version: $latestVersionLabel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (minSupportedVersion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Minimum supported: $minSupportedVersion',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              if ((releaseNotes ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(releaseNotes!, style: theme.textTheme.bodyMedium),
                ),
              if ((releaseNotes ?? '').isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    isMandatory
                        ? 'Please update the app to continue using all features.'
                        : 'A new update is available with the latest improvements.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
        actions: _buildActions(isMandatory),
      ),
    );
  }

  List<Widget> _buildActions(bool isMandatory) {
    if (isMandatory) {
      return [
        TextButton(
          onPressed: () => Get.back(result: AppUpdateAction.update),
          child: const Text('Update Now'),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Get.back(result: AppUpdateAction.remindLater),
        child: const Text('Not Now'),
      ),
      ElevatedButton(
        onPressed: () => Get.back(result: AppUpdateAction.update),
        child: const Text('Update'),
      ),
    ];
  }
}
