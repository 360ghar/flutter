import 'package:meta/meta.dart';

/// Represents allowed bug categories for feedback submissions.
enum BugType {
  uiBug('ui_bug'),
  functionalityBug('functionality_bug'),
  performanceIssue('performance_issue'),
  crash('crash'),
  featureRequest('feature_request'),
  other('other');

  const BugType(this.value);

  final String value;

  static BugType fromValue(String? value) {
    if (value == null) return BugType.other;
    return BugType.values.firstWhere(
      (type) => type.value.toLowerCase() == value.toLowerCase(),
      orElse: () => BugType.other,
    );
  }
}

/// Represents bug severity reported by the user.
enum BugSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const BugSeverity(this.value);

  final String value;

  static BugSeverity fromValue(String? value) {
    if (value == null) return BugSeverity.medium;
    return BugSeverity.values.firstWhere(
      (severity) => severity.value.toLowerCase() == value.toLowerCase(),
      orElse: () => BugSeverity.medium,
    );
  }
}

/// Request payload for creating a new bug report.
@immutable
class BugReportRequest {
  const BugReportRequest({
    required this.source,
    required this.bugType,
    required this.severity,
    required this.title,
    required this.description,
    this.stepsToReproduce,
    this.expectedBehavior,
    this.actualBehavior,
    this.deviceInfo,
    this.appVersion,
    this.tags,
  });

  final String source;
  final BugType bugType;
  final BugSeverity severity;
  final String title;
  final String description;
  final String? stepsToReproduce;
  final String? expectedBehavior;
  final String? actualBehavior;
  final Map<String, dynamic>? deviceInfo;
  final String? appVersion;
  final List<String>? tags;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'source': source,
      'bug_type': bugType.value,
      'severity': severity.value,
      'title': title,
      'description': description,
    };

    if (stepsToReproduce != null && stepsToReproduce!.trim().isNotEmpty) {
      json['steps_to_reproduce'] = stepsToReproduce;
    }
    if (expectedBehavior != null && expectedBehavior!.trim().isNotEmpty) {
      json['expected_behavior'] = expectedBehavior;
    }
    if (actualBehavior != null && actualBehavior!.trim().isNotEmpty) {
      json['actual_behavior'] = actualBehavior;
    }
    if (deviceInfo != null && deviceInfo!.isNotEmpty) {
      json['device_info'] = deviceInfo;
    }
    if (appVersion != null && appVersion!.trim().isNotEmpty) {
      json['app_version'] = appVersion;
    }
    if (tags != null && tags!.isNotEmpty) {
      json['tags'] = tags;
    }

    return json;
  }
}

/// Response returned after successfully submitting a bug report.
class BugReportResponse {
  BugReportResponse({
    required this.id,
    required this.source,
    required this.bugType,
    required this.severity,
    required this.status,
    required this.title,
    required this.description,
    this.stepsToReproduce,
    this.expectedBehavior,
    this.actualBehavior,
    this.deviceInfo,
    this.appVersion,
    this.mediaUrls = const [],
    this.tags = const [],
    this.userId,
    this.assignedTo,
    this.resolution,
    this.resolvedAt,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int? userId;
  final String source;
  final BugType bugType;
  final BugSeverity severity;
  final String status;
  final String title;
  final String description;
  final String? stepsToReproduce;
  final String? expectedBehavior;
  final String? actualBehavior;
  final Map<String, dynamic>? deviceInfo;
  final String? appVersion;
  final List<String> mediaUrls;
  final List<String> tags;
  final String? assignedTo;
  final String? resolution;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory BugReportResponse.fromJson(Map<String, dynamic> json) {
    final media = <String>[];
    if (json['media_urls'] is List) {
      media.addAll(
        (json['media_urls'] as List)
            .whereType<String>()
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty),
      );
    }

    final tagsList = <String>[];
    if (json['tags'] is List) {
      tagsList.addAll(
        (json['tags'] as List)
            .whereType<String>()
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty),
      );
    }

    Map<String, dynamic>? parsedDeviceInfo;
    if (json['device_info'] is Map<String, dynamic>) {
      parsedDeviceInfo = Map<String, dynamic>.from(
        json['device_info'] as Map<String, dynamic>,
      );
    }

    DateTime? _parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final createdAt = _parseDate(json['created_at']) ?? DateTime.now();

    return BugReportResponse(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      userId: json['user_id'] is num ? (json['user_id'] as num).toInt() : null,
      source: (json['source'] ?? 'mobile').toString(),
      bugType: BugType.fromValue(json['bug_type']?.toString()),
      severity: BugSeverity.fromValue(json['severity']?.toString()),
      status: (json['status'] ?? 'open').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      stepsToReproduce:
          json['steps_to_reproduce'] != null ? json['steps_to_reproduce'].toString() : null,
      expectedBehavior:
          json['expected_behavior'] != null ? json['expected_behavior'].toString() : null,
      actualBehavior:
          json['actual_behavior'] != null ? json['actual_behavior'].toString() : null,
      deviceInfo: parsedDeviceInfo,
      appVersion:
          json['app_version'] != null ? json['app_version'].toString() : null,
      mediaUrls: media,
      tags: tagsList,
      assignedTo:
          json['assigned_to'] != null ? json['assigned_to'].toString() : null,
      resolution:
          json['resolution'] != null ? json['resolution'].toString() : null,
      resolvedAt: _parseDate(json['resolved_at']),
      createdAt: createdAt,
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}
