import 'package:json_annotation/json_annotation.dart';

part 'agent_model.g.dart';

enum AgentType {
  @JsonValue('general')
  general,
  @JsonValue('specialist')
  specialist,
  @JsonValue('senior')
  senior,
  @JsonValue('unknown')
  unknown,
}

enum ExperienceLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('expert')
  expert,
  @JsonValue('unknown')
  unknown,
}

@JsonSerializable()
class AgentModel {
  final int id;
  final String name;
  final String? description;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  final List<String>? languages;
  @JsonKey(name: 'agent_type', unknownEnumValue: AgentType.unknown)
  final AgentType agentType;
  @JsonKey(name: 'experience_level', unknownEnumValue: ExperienceLevel.unknown)
  final ExperienceLevel experienceLevel;
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'is_available', defaultValue: true)
  final bool isAvailable;
  @JsonKey(name: 'working_hours')
  final Map<String, dynamic>? workingHours;
  @JsonKey(name: 'total_users_assigned', defaultValue: 0)
  final int totalUsersAssigned;
  @JsonKey(name: 'user_satisfaction_rating', defaultValue: 0.0)
  final double userSatisfactionRating;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const AgentModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.languages,
    required this.agentType,
    required this.experienceLevel,
    this.isActive = true,
    this.isAvailable = true,
    this.workingHours,
    this.totalUsersAssigned = 0,
    this.userSatisfactionRating = 0.0,
    required this.createdAt,
    this.updatedAt,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) => _$AgentModelFromJson(json);

  Map<String, dynamic> toJson() => _$AgentModelToJson(this);

  AgentModel copyWith({
    int? id,
    String? name,
    String? description,
    String? avatarUrl,
    List<String>? languages,
    AgentType? agentType,
    ExperienceLevel? experienceLevel,
    bool? isActive,
    bool? isAvailable,
    Map<String, dynamic>? workingHours,
    int? totalUsersAssigned,
    double? userSatisfactionRating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      languages: languages ?? this.languages,
      agentType: agentType ?? this.agentType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      workingHours: workingHours ?? this.workingHours,
      totalUsersAssigned: totalUsersAssigned ?? this.totalUsersAssigned,
      userSatisfactionRating: userSatisfactionRating ?? this.userSatisfactionRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convenience getters
  String get agentTypeString {
    switch (agentType) {
      case AgentType.general:
        return 'General';
      case AgentType.specialist:
        return 'Specialist';
      case AgentType.senior:
        return 'Senior';
      case AgentType.unknown:
        return 'Unknown';
    }
  }

  String get experienceLevelString {
    switch (experienceLevel) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.expert:
        return 'Expert';
      case ExperienceLevel.unknown:
        return 'Unknown';
    }
  }

  String get languagesDisplay => languages?.join(', ') ?? 'Not specified';

  bool get hasWorkingHours => workingHours?.isNotEmpty == true;
}
