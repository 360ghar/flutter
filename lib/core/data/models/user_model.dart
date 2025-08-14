import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  @JsonKey(name: 'supabase_user_id', defaultValue: '')
  final String supabaseUserId;
  @JsonKey(defaultValue: 'unknown@example.com')
  final String email;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? phone;
  @JsonKey(name: 'date_of_birth')
  final String? dateOfBirth; // Keep as string to match backend format (YYYY-MM-DD)
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'is_verified', defaultValue: false)
  final bool isVerified;
  @JsonKey(name: 'profile_image_url')
  final String? profileImageUrl;
  final Map<String, dynamic>? preferences;
  @JsonKey(name: 'current_latitude')
  final String? currentLatitude;
  @JsonKey(name: 'current_longitude')
  final String? currentLongitude;
  @JsonKey(name: 'preferred_locations')
  final List<String>? preferredLocations;
  @JsonKey(name: 'notification_settings')
  final Map<String, bool>? notificationSettings;
  @JsonKey(name: 'privacy_settings')
  final Map<String, dynamic>? privacySettings;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  // Client-side fields (not from backend)
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.supabaseUserId,
    required this.email,
    this.fullName,
    this.phone,
    this.dateOfBirth,
    required this.isActive,
    required this.isVerified,
    this.profileImageUrl,
    this.preferences,
    this.currentLatitude,
    this.currentLongitude,
    this.preferredLocations,
    this.notificationSettings,
    this.privacySettings,
    required this.createdAt,
    this.updatedAt,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? supabaseUserId,
    String? email,
    String? fullName,
    String? phone,
    String? dateOfBirth,
    bool? isActive,
    bool? isVerified,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
    String? currentLatitude,
    String? currentLongitude,
    List<String>? preferredLocations,
    Map<String, bool>? notificationSettings,
    Map<String, dynamic>? privacySettings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      supabaseUserId: supabaseUserId ?? this.supabaseUserId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      preferences: preferences ?? this.preferences,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
  
  // Helper methods for date of birth
  DateTime? get dateOfBirthAsDate {
    if (dateOfBirth == null) return null;
    try {
      return DateTime.parse(dateOfBirth!);
    } catch (e) {
      return null;
    }
  }
  
  int? get age {
    final dob = dateOfBirthAsDate;
    if (dob == null) return null;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
  
  // Helper methods for location
  double? get latitudeAsDouble {
    if (currentLatitude == null) return null;
    return double.tryParse(currentLatitude!);
  }
  
  double? get longitudeAsDouble {
    if (currentLongitude == null) return null;
    return double.tryParse(currentLongitude!);
  }
  
  bool get hasLocation => currentLatitude != null && currentLongitude != null;

  // Convenience getters for backward compatibility
  String get name => fullName ?? 'Unknown User';
  String? get profileImage => profileImageUrl;
  DateTime get lastLogin => updatedAt ?? createdAt;
  List<String> get savedProperties => []; // To be handled via API
  List<String> get viewedProperties => []; // To be handled via API
  
  // Profile completion percentage
  int get profileCompletionPercentage {
    int completedFields = 0;
    int totalFields = 5; // email, fullName, phone, dateOfBirth, profileImageUrl
    
    if (email.isNotEmpty) completedFields++;
    if (fullName != null && fullName!.isNotEmpty) completedFields++;
    if (phone != null && phone!.isNotEmpty) completedFields++;
    if (dateOfBirth != null) completedFields++;
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) completedFields++;
    
    return ((completedFields / totalFields) * 100).round();
  }
  
  // Check if profile is complete
  bool get isProfileComplete => profileCompletionPercentage >= 80;
} 