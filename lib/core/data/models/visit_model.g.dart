// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VisitPropertyInfo _$VisitPropertyInfoFromJson(Map<String, dynamic> json) =>
    VisitPropertyInfo(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      propertyType: json['property_type'] as String,
      city: json['city'] as String,
      locality: json['locality'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
    );

Map<String, dynamic> _$VisitPropertyInfoToJson(VisitPropertyInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'property_type': instance.propertyType,
      'city': instance.city,
      'locality': instance.locality,
      'base_price': instance.basePrice,
    };

VisitAgentInfo _$VisitAgentInfoFromJson(Map<String, dynamic> json) =>
    VisitAgentInfo(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      agentCode: json['agent_code'] as String,
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$VisitAgentInfoToJson(VisitAgentInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'agent_code': instance.agentCode,
      'phone': instance.phone,
    };

VisitModel _$VisitModelFromJson(Map<String, dynamic> json) => VisitModel(
  id: (json['id'] as num).toInt(),
  propertyId: (json['property_id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  agentId: (json['agent_id'] as num?)?.toInt(),
  scheduledDate: DateTime.parse(json['scheduled_date'] as String),
  actualDate: json['actual_date'] == null
      ? null
      : DateTime.parse(json['actual_date'] as String),
  status: $enumDecode(_$VisitStatusEnumMap, json['status']),
  specialRequirements: json['special_requirements'] as String?,
  visitNotes: json['visit_notes'] as String?,
  visitorFeedback: json['visitor_feedback'] as String?,
  interestLevel: json['interest_level'] as String?,
  followUpRequired: json['follow_up_required'] as bool? ?? false,
  followUpDate: json['follow_up_date'] == null
      ? null
      : DateTime.parse(json['follow_up_date'] as String),
  cancellationReason: json['cancellation_reason'] as String?,
  rescheduledFrom: json['rescheduled_from'] == null
      ? null
      : DateTime.parse(json['rescheduled_from'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  properties: json['properties'] == null
      ? null
      : VisitPropertyInfo.fromJson(json['properties'] as Map<String, dynamic>),
  agents: json['agents'] == null
      ? null
      : VisitAgentInfo.fromJson(json['agents'] as Map<String, dynamic>),
);

Map<String, dynamic> _$VisitModelToJson(VisitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_id': instance.propertyId,
      'user_id': instance.userId,
      'agent_id': instance.agentId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'actual_date': instance.actualDate?.toIso8601String(),
      'status': _$VisitStatusEnumMap[instance.status]!,
      'special_requirements': instance.specialRequirements,
      'visit_notes': instance.visitNotes,
      'visitor_feedback': instance.visitorFeedback,
      'interest_level': instance.interestLevel,
      'follow_up_required': instance.followUpRequired,
      'follow_up_date': instance.followUpDate?.toIso8601String(),
      'cancellation_reason': instance.cancellationReason,
      'rescheduled_from': instance.rescheduledFrom?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'properties': instance.properties,
      'agents': instance.agents,
    };

const _$VisitStatusEnumMap = {
  VisitStatus.scheduled: 'scheduled',
  VisitStatus.confirmed: 'confirmed',
  VisitStatus.completed: 'completed',
  VisitStatus.cancelled: 'cancelled',
  VisitStatus.rescheduled: 'rescheduled',
};
