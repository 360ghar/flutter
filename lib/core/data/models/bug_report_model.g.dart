// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bug_report_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BugReportRequest _$BugReportRequestFromJson(Map<String, dynamic> json) => BugReportRequest(
  source: json['source'] as String,
  bugType: const BugTypeConverter().fromJson(json['bug_type'] as String),
  severity: const BugSeverityConverter().fromJson(json['severity'] as String),
  title: json['title'] as String,
  description: json['description'] as String,
  stepsToReproduce: json['steps_to_reproduce'] as String?,
  expectedBehavior: json['expected_behavior'] as String?,
  actualBehavior: json['actual_behavior'] as String?,
  deviceInfo: json['device_info'] as Map<String, dynamic>?,
  appVersion: json['app_version'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$BugReportRequestToJson(BugReportRequest instance) => <String, dynamic>{
  'source': instance.source,
  'bug_type': const BugTypeConverter().toJson(instance.bugType),
  'severity': const BugSeverityConverter().toJson(instance.severity),
  'title': instance.title,
  'description': instance.description,
  'steps_to_reproduce': ?instance.stepsToReproduce,
  'expected_behavior': ?instance.expectedBehavior,
  'actual_behavior': ?instance.actualBehavior,
  'device_info': ?instance.deviceInfo,
  'app_version': ?instance.appVersion,
  'tags': ?instance.tags,
};

BugReportResponse _$BugReportResponseFromJson(Map<String, dynamic> json) => BugReportResponse(
  id: (json['id'] as num).toInt(),
  source: json['source'] as String,
  bugType: const BugTypeConverter().fromJson(json['bug_type'] as String),
  severity: const BugSeverityConverter().fromJson(json['severity'] as String),
  status: json['status'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  stepsToReproduce: json['steps_to_reproduce'] as String?,
  expectedBehavior: json['expected_behavior'] as String?,
  actualBehavior: json['actual_behavior'] as String?,
  deviceInfo: json['device_info'] as Map<String, dynamic>?,
  appVersion: json['app_version'] as String?,
  mediaUrls: (json['media_urls'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
  userId: (json['user_id'] as num?)?.toInt(),
  assignedTo: json['assigned_to'] as String?,
  resolution: json['resolution'] as String?,
  resolvedAt: json['resolved_at'] == null ? null : DateTime.parse(json['resolved_at'] as String),
  createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$BugReportResponseToJson(BugReportResponse instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'source': instance.source,
  'bug_type': const BugTypeConverter().toJson(instance.bugType),
  'severity': const BugSeverityConverter().toJson(instance.severity),
  'status': instance.status,
  'title': instance.title,
  'description': instance.description,
  'steps_to_reproduce': instance.stepsToReproduce,
  'expected_behavior': instance.expectedBehavior,
  'actual_behavior': instance.actualBehavior,
  'device_info': instance.deviceInfo,
  'app_version': instance.appVersion,
  'media_urls': instance.mediaUrls,
  'tags': instance.tags,
  'assigned_to': instance.assignedTo,
  'resolution': instance.resolution,
  'resolved_at': instance.resolvedAt?.toIso8601String(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
