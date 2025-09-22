// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: (json['id'] as num).toInt(),
  supabaseUserId: json['supabase_user_id'] as String? ?? '',
  email: json['email'] as String? ?? 'unknown@example.com',
  fullName: json['full_name'] as String?,
  phone: json['phone'] as String?,
  dateOfBirth: json['date_of_birth'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  isVerified: json['is_verified'] as bool? ?? false,
  profileImageUrl: json['profile_image_url'] as String?,
  preferences: json['preferences'] as Map<String, dynamic>?,
  currentLatitude: (json['current_latitude'] as num?)?.toDouble(),
  currentLongitude: (json['current_longitude'] as num?)?.toDouble(),
  preferredLocations: (json['preferred_locations'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  notificationSettings: (json['notification_settings'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as bool),
  ),
  privacySettings: json['privacy_settings'] as Map<String, dynamic>?,
  agentId: (json['agent_id'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
  fcmToken: json['fcmToken'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'supabase_user_id': instance.supabaseUserId,
  'email': instance.email,
  'full_name': instance.fullName,
  'phone': instance.phone,
  'date_of_birth': instance.dateOfBirth,
  'is_active': instance.isActive,
  'is_verified': instance.isVerified,
  'profile_image_url': instance.profileImageUrl,
  'preferences': instance.preferences,
  'current_latitude': instance.currentLatitude,
  'current_longitude': instance.currentLongitude,
  'preferred_locations': instance.preferredLocations,
  'notification_settings': instance.notificationSettings,
  'privacy_settings': instance.privacySettings,
  'agent_id': instance.agentId,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'fcmToken': instance.fcmToken,
};
