import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'bug_report_model.g.dart';

class BugTypeConverter implements JsonConverter<BugType, String> {
  const BugTypeConverter();

  @override
  BugType fromJson(String json) => BugType.fromValue(json);

  @override
  String toJson(BugType object) => object.value;
}

class BugSeverityConverter implements JsonConverter<BugSeverity, String> {
  const BugSeverityConverter();

  @override
  BugSeverity fromJson(String json) => BugSeverity.fromValue(json);

  @override
  String toJson(BugSeverity object) => object.value;
}

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
@JsonSerializable(fieldRename: FieldRename.snake)
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

  factory BugReportRequest.fromJson(Map<String, dynamic> json) => _$BugReportRequestFromJson(json);

  final String source;
  @BugTypeConverter()
  final BugType bugType;
  @BugSeverityConverter()
  final BugSeverity severity;
  final String title;
  final String description;
  @JsonKey(includeIfNull: false)
  final String? stepsToReproduce;
  @JsonKey(includeIfNull: false)
  final String? expectedBehavior;
  @JsonKey(includeIfNull: false)
  final String? actualBehavior;
  @JsonKey(includeIfNull: false)
  final Map<String, dynamic>? deviceInfo;
  @JsonKey(includeIfNull: false)
  final String? appVersion;
  @JsonKey(includeIfNull: false)
  final List<String>? tags;

  Map<String, dynamic> toJson() => _$BugReportRequestToJson(this);
}

/// Response returned after successfully submitting a bug report.
@JsonSerializable(fieldRename: FieldRename.snake)
class BugReportResponse {
  const BugReportResponse({
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
    this.createdAt,
    this.updatedAt,
  });

  factory BugReportResponse.fromJson(Map<String, dynamic> json) {
    // Validate required id field to fail fast instead of defaulting to 0
    final idValue = json['id'];
    if (idValue is! num) {
      throw const FormatException('BugReportResponse.id is required and must be numeric');
    }

    return _$BugReportResponseFromJson(json);
  }

  final int id;
  final int? userId;
  final String source;
  @BugTypeConverter()
  final BugType bugType;
  @BugSeverityConverter()
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => _$BugReportResponseToJson(this);
}
