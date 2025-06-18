import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profileImage;
  final List<String> savedProperties;
  final List<String> viewedProperties;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isVerified;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profileImage,
    required this.savedProperties,
    required this.viewedProperties,
    required this.preferences,
    required this.createdAt,
    required this.lastLogin,
    required this.isVerified,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    List<String>? savedProperties,
    List<String>? viewedProperties,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isVerified,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      savedProperties: savedProperties ?? this.savedProperties,
      viewedProperties: viewedProperties ?? this.viewedProperties,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isVerified: isVerified ?? this.isVerified,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
} 