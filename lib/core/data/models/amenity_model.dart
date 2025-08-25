import 'package:json_annotation/json_annotation.dart';

part 'amenity_model.g.dart';

@JsonSerializable()
class AmenityModel {
  final int id;
  final String title;
  final String? icon;
  final String? category; // e.g., "safety", "recreation", "convenience"
  @JsonKey(name: 'is_active', defaultValue: true)
  final bool isActive;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  AmenityModel({
    required this.id,
    required this.title,
    this.icon,
    this.category,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) => _$AmenityModelFromJson(json);

  Map<String, dynamic> toJson() => _$AmenityModelToJson(this);

  AmenityModel copyWith({
    int? id,
    String? title,
    String? icon,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AmenityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convenience getters
  String get displayTitle => title;
  bool get hasIcon => icon?.isNotEmpty == true;
  bool get hasCategory => category?.isNotEmpty == true;
  String get categoryDisplay => category ?? 'General';
}

@JsonSerializable()
class PropertyAmenityModel {
  final int id;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'amenity_id')
  final int amenityId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  // Relationship data
  final AmenityModel? amenity;

  PropertyAmenityModel({
    required this.id,
    required this.propertyId,
    required this.amenityId,
    required this.createdAt,
    this.amenity,
  });

  factory PropertyAmenityModel.fromJson(Map<String, dynamic> json) => _$PropertyAmenityModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyAmenityModelToJson(this);

  // Convenience getters
  String get amenityTitle => amenity?.title ?? 'Unknown Amenity';
  String? get amenityIcon => amenity?.icon;
  String? get amenityCategory => amenity?.category;
}

// Response model for API that returns property amenities
@JsonSerializable()
class PropertyAmenityResponse {
  final int id;
  final String title;
  final String? icon;
  final String? category;

  PropertyAmenityResponse({
    required this.id,
    required this.title,
    this.icon,
    this.category,
  });

  factory PropertyAmenityResponse.fromJson(Map<String, dynamic> json) => _$PropertyAmenityResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyAmenityResponseToJson(this);

  // Convert to AmenityModel
  AmenityModel toAmenityModel() {
    return AmenityModel(
      id: id,
      title: title,
      icon: icon,
      category: category,
      isActive: true,
      createdAt: DateTime.now(), // Default since this is from API response
      updatedAt: null,
    );
  }
}