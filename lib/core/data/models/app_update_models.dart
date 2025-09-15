// lib/core/data/models/app_update_models.dart

class AppVersionCheckRequest {
  AppVersionCheckRequest({
    required this.app,
    required this.platform,
    required this.currentVersion,
    this.buildNumber,
  });

  final String app;
  final String platform;
  final String currentVersion;
  final int? buildNumber;

  Map<String, dynamic> toJson() {
    return {
      'app': app,
      'platform': platform,
      'current_version': currentVersion,
      if (buildNumber != null) 'build_number': buildNumber,
    };
  }
}

class AppVersionCheckResponse {
  AppVersionCheckResponse({
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

  factory AppVersionCheckResponse.fromJson(Map<String, dynamic> json) {
    return AppVersionCheckResponse(
      updateAvailable: json['update_available'] == true,
      isMandatory: json['is_mandatory'] == true,
      latestVersion: _stringOrNull(json['latest_version']),
      downloadUrl: _stringOrNull(json['download_url']),
      releaseNotes: _stringOrNull(json['release_notes']),
      minSupportedVersion: _stringOrNull(json['min_supported_version']),
    );
  }

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

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

class AppVersionInfo {
  const AppVersionInfo({required this.version, this.buildNumber});

  final String version;
  final int? buildNumber;
}
