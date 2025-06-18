// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      profileImage: json['profileImage'] as String?,
      savedProperties: (json['savedProperties'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      viewedProperties: (json['viewedProperties'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      preferences: json['preferences'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      isVerified: json['isVerified'] as bool,
      fcmToken: json['fcmToken'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'name': instance.name,
      'phone': instance.phone,
      'profileImage': instance.profileImage,
      'savedProperties': instance.savedProperties,
      'viewedProperties': instance.viewedProperties,
      'preferences': instance.preferences,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastLogin': instance.lastLogin.toIso8601String(),
      'isVerified': instance.isVerified,
      'fcmToken': instance.fcmToken,
    };
