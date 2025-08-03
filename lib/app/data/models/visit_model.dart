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
class RelationshipManagerModel {
  final int id;
  @JsonKey(name: 'employee_id', defaultValue: 'EMP001')
  final String employeeId;
  @JsonKey(defaultValue: 'Unknown Agent')
  final String name;
  @JsonKey(defaultValue: 'unknown@example.com')
  final String email;
  @JsonKey(defaultValue: '')
  final String phone;
  @JsonKey(name: 'whatsapp_number')
  final String? whatsappNumber;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  final String? bio;
  @JsonKey(defaultValue: 'Customer Relations')
  final String department;
  @JsonKey(name: 'experience_years')
  final int? experienceYears;
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'working_hours')
  final String? workingHours;
  @JsonKey(name: 'total_visits_handled', defaultValue: 0)
  final int totalVisitsHandled;
  @JsonKey(name: 'customer_rating')
  final String? customerRating;

  RelationshipManagerModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    this.whatsappNumber,
    this.profileImageUrl,
    this.bio,
    required this.department,
    this.experienceYears,
    required this.isActive,
    this.workingHours,
    required this.totalVisitsHandled,
    this.customerRating,
  });

  factory RelationshipManagerModel.fromJson(Map<String, dynamic> json) => _$RelationshipManagerModelFromJson(json);

  Map<String, dynamic> toJson() => _$RelationshipManagerModelToJson(this);
}

@JsonSerializable()
class VisitModel {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;
  @JsonKey(name: 'visitor_name', defaultValue: 'Unknown Visitor')
  final String visitorName;
  @JsonKey(name: 'visitor_phone', defaultValue: '')
  final String visitorPhone;
  @JsonKey(name: 'visitor_email')
  final String? visitorEmail;
  @JsonKey(name: 'number_of_visitors', defaultValue: 1)
  final int numberOfVisitors;
  @JsonKey(name: 'preferred_time_slot')
  final String? preferredTimeSlot;
  @JsonKey(name: 'special_requirements')
  final String? specialRequirements;
  @JsonKey(name: 'relationship_manager_id')
  final int? relationshipManagerId;
  @JsonKey(name: 'actual_date')
  final DateTime? actualDate;
  final VisitStatus status;
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
  @JsonKey(name: 'relationship_manager')
  final RelationshipManagerModel? relationshipManager;

  VisitModel({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.scheduledDate,
    required this.visitorName,
    required this.visitorPhone,
    this.visitorEmail,
    this.numberOfVisitors = 1,
    this.preferredTimeSlot,
    this.specialRequirements,
    this.relationshipManagerId,
    this.actualDate,
    required this.status,
    this.visitNotes,
    this.visitorFeedback,
    this.interestLevel,
    this.followUpRequired = false,
    this.followUpDate,
    this.cancellationReason,
    this.rescheduledFrom,
    required this.createdAt,
    this.updatedAt,
    this.relationshipManager,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) => _$VisitModelFromJson(json);

  Map<String, dynamic> toJson() => _$VisitModelToJson(this);

  // Convenience getters for backward compatibility
  String get propertyTitle => 'Property #$propertyId';
  String get propertyImage => 'https://via.placeholder.com/400x300?text=Property+Image';
  DateTime get visitDateTime => scheduledDate;
  String get agentName => relationshipManager?.name ?? 'Unknown Agent';
  String get agentPhone => relationshipManager?.phone ?? '';
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
  
  // Add copyWith method for backward compatibility
  VisitModel copyWith({
    int? id,
    int? userId,
    int? propertyId,
    DateTime? scheduledDate,
    String? visitorName,
    String? visitorPhone,
    String? visitorEmail,
    int? numberOfVisitors,
    String? preferredTimeSlot,
    String? specialRequirements,
    int? relationshipManagerId,
    DateTime? actualDate,
    VisitStatus? status,
    String? visitNotes,
    String? visitorFeedback,
    String? interestLevel,
    bool? followUpRequired,
    DateTime? followUpDate,
    String? cancellationReason,
    DateTime? rescheduledFrom,
    DateTime? createdAt,
    DateTime? updatedAt,
    RelationshipManagerModel? relationshipManager,
    String? propertyTitle,
    String? propertyImage,
  }) {
    return VisitModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      propertyId: propertyId ?? this.propertyId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      visitorName: visitorName ?? this.visitorName,
      visitorPhone: visitorPhone ?? this.visitorPhone,
      visitorEmail: visitorEmail ?? this.visitorEmail,
      numberOfVisitors: numberOfVisitors ?? this.numberOfVisitors,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      relationshipManagerId: relationshipManagerId ?? this.relationshipManagerId,
      actualDate: actualDate ?? this.actualDate,
      status: status ?? this.status,
      visitNotes: visitNotes ?? this.visitNotes,
      visitorFeedback: visitorFeedback ?? this.visitorFeedback,
      interestLevel: interestLevel ?? this.interestLevel,
      followUpRequired: followUpRequired ?? this.followUpRequired,
      followUpDate: followUpDate ?? this.followUpDate,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      rescheduledFrom: rescheduledFrom ?? this.rescheduledFrom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      relationshipManager: relationshipManager ?? this.relationshipManager,
    );
  }
}