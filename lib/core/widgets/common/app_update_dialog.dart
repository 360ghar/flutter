// lib/core/widgets/common/app_update_dialog.dart

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/app_update_models.dart';

enum AppUpdateAction { update, remindLater }

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({super.key, required this.response, required this.currentVersion});

  final AppVersionCheckResponse response;
  final String currentVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMandatory = response.isMandatory;
    final releaseNotes = response.releaseNotes;
    final latestVersionLabel = response.latestVersion;
    final minSupportedVersion = response.minSupportedVersion;

    return PopScope(
      canPop: !isMandatory,
      child: AlertDialog(
        title: Text(isMandatory ? 'mandatory_update_required'.tr : 'update_available'.tr),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${'current_version'.tr}: $currentVersion', style: theme.textTheme.bodySmall),
              if (latestVersionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${'latest_version'.tr}: $latestVersionLabel',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              if (minSupportedVersion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${'minimum_supported'.tr}: $minSupportedVersion',
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
                    isMandatory ? 'mandatory_update_desc'.tr : 'optional_update_desc'.tr,
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
          child: Text('update_now'.tr),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () => Get.back(result: AppUpdateAction.remindLater),
        child: Text('not_now'.tr),
      ),
      ElevatedButton(
        onPressed: () => Get.back(result: AppUpdateAction.update),
        child: Text('update'.tr),
      ),
    ];
  }
}
