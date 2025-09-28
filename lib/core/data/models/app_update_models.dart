// lib/core/data/models/app_update_models.dart

import 'package:json_annotation/json_annotation.dart';

part 'app_update_models.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AppVersionCheckRequest {
  const AppVersionCheckRequest({
    required this.app,
    required this.platform,
    required this.currentVersion,
    this.buildNumber,
  });

  final String app;
  final String platform;
  final String currentVersion;
  final int? buildNumber;

  factory AppVersionCheckRequest.fromJson(Map<String, dynamic> json) =>
      _$AppVersionCheckRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AppVersionCheckRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AppVersionCheckResponse {
  const AppVersionCheckResponse({
    required this.updateAvailable,
    required this.isMandatory,
    this.latestVersion,
    this.downloadUrl,
    this.releaseNotes,
    this.minSupportedVersion,
  });

  final bool updateAvailable;
  final bool isMandatory;
  final String? latestVersion;
  final String? downloadUrl;
  final String? releaseNotes;
  final String? minSupportedVersion;

  factory AppVersionCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$AppVersionCheckResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AppVersionCheckResponseToJson(this);

  bool get hasDownloadUrl => (downloadUrl ?? '').isNotEmpty;

  AppVersionCheckResponse copyWith({
    bool? updateAvailable,
    bool? isMandatory,
    String? latestVersion,
    String? downloadUrl,
    String? releaseNotes,
    String? minSupportedVersion,
  }) {
    return AppVersionCheckResponse(
      updateAvailable: updateAvailable ?? this.updateAvailable,
      isMandatory: isMandatory ?? this.isMandatory,
      latestVersion: latestVersion ?? this.latestVersion,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      minSupportedVersion: minSupportedVersion ?? this.minSupportedVersion,
    );
  }
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AppVersionInfo {
  const AppVersionInfo({required this.version, this.buildNumber});

  final String version;
  final int? buildNumber;

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) => _$AppVersionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AppVersionInfoToJson(this);
}
