// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RelationshipManagerModel _$RelationshipManagerModelFromJson(
        Map<String, dynamic> json) =>
    RelationshipManagerModel(
      id: (json['id'] as num).toInt(),
      employeeId: json['employee_id'] as String? ?? 'EMP001',
      name: json['name'] as String? ?? 'Unknown Agent',
      email: json['email'] as String? ?? 'unknown@example.com',
      phone: json['phone'] as String? ?? '',
      whatsappNumber: json['whatsapp_number'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      bio: json['bio'] as String?,
      department: json['department'] as String? ?? 'Customer Relations',
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      workingHours: json['working_hours'] as String?,
      totalVisitsHandled: (json['total_visits_handled'] as num?)?.toInt() ?? 0,
      customerRating: json['customer_rating'] as String?,
    );

Map<String, dynamic> _$RelationshipManagerModelToJson(
        RelationshipManagerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'employee_id': instance.employeeId,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'whatsapp_number': instance.whatsappNumber,
      'profile_image_url': instance.profileImageUrl,
      'bio': instance.bio,
      'department': instance.department,
      'experience_years': instance.experienceYears,
      'is_active': instance.isActive,
      'working_hours': instance.workingHours,
      'total_visits_handled': instance.totalVisitsHandled,
      'customer_rating': instance.customerRating,
    };

VisitModel _$VisitModelFromJson(Map<String, dynamic> json) => VisitModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      propertyId: (json['property_id'] as num).toInt(),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      visitorName: json['visitor_name'] as String? ?? 'Unknown Visitor',
      visitorPhone: json['visitor_phone'] as String? ?? '',
      visitorEmail: json['visitor_email'] as String?,
      numberOfVisitors: (json['number_of_visitors'] as num?)?.toInt() ?? 1,
      preferredTimeSlot: json['preferred_time_slot'] as String?,
      specialRequirements: json['special_requirements'] as String?,
      relationshipManagerId: (json['relationship_manager_id'] as num?)?.toInt(),
      actualDate: json['actual_date'] == null
          ? null
          : DateTime.parse(json['actual_date'] as String),
      status: $enumDecode(_$VisitStatusEnumMap, json['status']),
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
      relationshipManager: json['relationship_manager'] == null
          ? null
          : RelationshipManagerModel.fromJson(
              json['relationship_manager'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VisitModelToJson(VisitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'property_id': instance.propertyId,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'visitor_name': instance.visitorName,
      'visitor_phone': instance.visitorPhone,
      'visitor_email': instance.visitorEmail,
      'number_of_visitors': instance.numberOfVisitors,
      'preferred_time_slot': instance.preferredTimeSlot,
      'special_requirements': instance.specialRequirements,
      'relationship_manager_id': instance.relationshipManagerId,
      'actual_date': instance.actualDate?.toIso8601String(),
      'status': _$VisitStatusEnumMap[instance.status]!,
      'visit_notes': instance.visitNotes,
      'visitor_feedback': instance.visitorFeedback,
      'interest_level': instance.interestLevel,
      'follow_up_required': instance.followUpRequired,
      'follow_up_date': instance.followUpDate?.toIso8601String(),
      'cancellation_reason': instance.cancellationReason,
      'rescheduled_from': instance.rescheduledFrom?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'relationship_manager': instance.relationshipManager,
    };

const _$VisitStatusEnumMap = {
  VisitStatus.scheduled: 'scheduled',
  VisitStatus.confirmed: 'confirmed',
  VisitStatus.completed: 'completed',
  VisitStatus.cancelled: 'cancelled',
  VisitStatus.rescheduled: 'rescheduled',
};
