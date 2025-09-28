// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_update_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppVersionCheckRequest _$AppVersionCheckRequestFromJson(Map<String, dynamic> json) =>
    AppVersionCheckRequest(
      app: json['app'] as String,
      platform: json['platform'] as String,
      currentVersion: json['current_version'] as String,
      buildNumber: (json['build_number'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AppVersionCheckRequestToJson(AppVersionCheckRequest instance) =>
    <String, dynamic>{
      'app': instance.app,
      'platform': instance.platform,
      'current_version': instance.currentVersion,
      'build_number': instance.buildNumber,
    };

AppVersionCheckResponse _$AppVersionCheckResponseFromJson(Map<String, dynamic> json) =>
    AppVersionCheckResponse(
      updateAvailable: json['update_available'] as bool,
      isMandatory: json['is_mandatory'] as bool,
      latestVersion: json['latest_version'] as String?,
      downloadUrl: json['download_url'] as String?,
      releaseNotes: json['release_notes'] as String?,
      minSupportedVersion: json['min_supported_version'] as String?,
    );

Map<String, dynamic> _$AppVersionCheckResponseToJson(AppVersionCheckResponse instance) =>
    <String, dynamic>{
      'update_available': instance.updateAvailable,
      'is_mandatory': instance.isMandatory,
      'latest_version': instance.latestVersion,
      'download_url': instance.downloadUrl,
      'release_notes': instance.releaseNotes,
      'min_supported_version': instance.minSupportedVersion,
    };

AppVersionInfo _$AppVersionInfoFromJson(Map<String, dynamic> json) => AppVersionInfo(
  version: json['version'] as String,
  buildNumber: (json['build_number'] as num?)?.toInt(),
);

Map<String, dynamic> _$AppVersionInfoToJson(AppVersionInfo instance) => <String, dynamic>{
  'version': instance.version,
  'build_number': instance.buildNumber,
};
