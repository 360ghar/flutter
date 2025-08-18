import 'package:json_annotation/json_annotation.dart';

part 'visit_model.g.dart';

enum VisitStatus {
  @JsonValue('scheduled')
  scheduled,
  @JsonValue('confirmed')
  confirmed,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('rescheduled')
  rescheduled,
}


@JsonSerializable()
class VisitPropertyInfo {
  final int id;
  final String title;
  @JsonKey(name: 'property_type')
  final String propertyType;
  final String city;
  final String locality;
  @JsonKey(name: 'base_price')
  final double basePrice;

  VisitPropertyInfo({
    required this.id,
    required this.title,
    required this.propertyType,
    required this.city,
    required this.locality,
    required this.basePrice,
  });

  factory VisitPropertyInfo.fromJson(Map<String, dynamic> json) => _$VisitPropertyInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VisitPropertyInfoToJson(this);
}

@JsonSerializable()
class VisitAgentInfo {
  final int id;
  final String name;
  @JsonKey(name: 'agent_code')
  final String agentCode;
  final String phone;

  VisitAgentInfo({
    required this.id,
    required this.name,
    required this.agentCode,
    required this.phone,
  });

  factory VisitAgentInfo.fromJson(Map<String, dynamic> json) => _$VisitAgentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$VisitAgentInfoToJson(this);
}

@JsonSerializable()
class VisitModel {
  final int id;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'agent_id')
  final int? agentId;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  @JsonKey(name: 'actual_date')
  final DateTime? actualDate;
  final VisitStatus status;
  @JsonKey(name: 'special_requirements')
  final String? specialRequirements;
  @JsonKey(name: 'visit_notes')
  final String? visitNotes;
  @JsonKey(name: 'visitor_feedback')
  final String? visitorFeedback;
  @JsonKey(name: 'interest_level')
  final String? interestLevel;
  @JsonKey(name: 'follow_up_required', defaultValue: false)
  final bool followUpRequired;
  @JsonKey(name: 'follow_up_date')
  final DateTime? followUpDate;
  @JsonKey(name: 'cancellation_reason')
  final String? cancellationReason;
  @JsonKey(name: 'rescheduled_from')
  final DateTime? rescheduledFrom;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final VisitPropertyInfo? properties;
  final VisitAgentInfo? agents;

  VisitModel({
    required this.id,
    required this.propertyId,
    required this.userId,
    this.agentId,
    required this.scheduledDate,
    this.actualDate,
    required this.status,
    this.specialRequirements,
    this.visitNotes,
    this.visitorFeedback,
    this.interestLevel,
    this.followUpRequired = false,
    this.followUpDate,
    this.cancellationReason,
    this.rescheduledFrom,
    required this.createdAt,
    this.updatedAt,
    this.properties,
    this.agents,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) => _$VisitModelFromJson(json);

  Map<String, dynamic> toJson() => _$VisitModelToJson(this);

  // Convenience getters  
  String get propertyTitle => properties?.title ?? 'Property #$propertyId';
  String get agentName => agents?.name ?? 'Unknown Agent';
  String get agentPhone => agents?.phone ?? '';
  String get notes => visitNotes ?? '';
  
  bool get isUpcoming => DateTime.now().isBefore(scheduledDate) && (status == VisitStatus.scheduled || status == VisitStatus.confirmed);
  bool get isCompleted => status == VisitStatus.completed;
  bool get isCancelled => status == VisitStatus.cancelled;
  
  // Helper methods for status
  String get statusString {
    switch (status) {
      case VisitStatus.scheduled:
        return 'Scheduled';
      case VisitStatus.confirmed:
        return 'Confirmed';
      case VisitStatus.completed:
        return 'Completed';
      case VisitStatus.cancelled:
        return 'Cancelled';
      case VisitStatus.rescheduled:
        return 'Rescheduled';
    }
  }
  
  bool get canReschedule => status == VisitStatus.scheduled || status == VisitStatus.confirmed;
  bool get canCancel => status == VisitStatus.scheduled || status == VisitStatus.confirmed;
  
  VisitModel copyWith({
    int? id,
    int? propertyId,
    int? userId,
    int? agentId,
    DateTime? scheduledDate,
    DateTime? actualDate,
    VisitStatus? status,
    String? specialRequirements,
    String? visitNotes,
    String? visitorFeedback,
    String? interestLevel,
    bool? followUpRequired,
    DateTime? followUpDate,
    String? cancellationReason,
    DateTime? rescheduledFrom,
    DateTime? createdAt,
    DateTime? updatedAt,
    VisitPropertyInfo? properties,
    VisitAgentInfo? agents,
  }) {
    return VisitModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      userId: userId ?? this.userId,
      agentId: agentId ?? this.agentId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      actualDate: actualDate ?? this.actualDate,
      status: status ?? this.status,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      visitNotes: visitNotes ?? this.visitNotes,
      visitorFeedback: visitorFeedback ?? this.visitorFeedback,
      interestLevel: interestLevel ?? this.interestLevel,
      followUpRequired: followUpRequired ?? this.followUpRequired,
      followUpDate: followUpDate ?? this.followUpDate,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rescheduledFrom: rescheduledFrom ?? this.rescheduledFrom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      properties: properties ?? this.properties,
      agents: agents ?? this.agents,
    );
  }
}