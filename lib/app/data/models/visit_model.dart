enum VisitStatus {
  upcoming,
  completed,
  cancelled,
}

class VisitModel {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyImage;
  final DateTime visitDateTime;
  final VisitStatus status;
  final String agentName;
  final String agentPhone;
  final String notes;
  final DateTime createdAt;

  VisitModel({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImage,
    required this.visitDateTime,
    required this.status,
    required this.agentName,
    required this.agentPhone,
    required this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  VisitModel copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? propertyImage,
    DateTime? visitDateTime,
    VisitStatus? status,
    String? agentName,
    String? agentPhone,
    String? notes,
    DateTime? createdAt,
  }) {
    return VisitModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyImage: propertyImage ?? this.propertyImage,
      visitDateTime: visitDateTime ?? this.visitDateTime,
      status: status ?? this.status,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 