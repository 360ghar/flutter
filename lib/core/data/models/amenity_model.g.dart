// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'amenity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AmenityModel _$AmenityModelFromJson(Map<String, dynamic> json) => AmenityModel(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  icon: json['icon'] as String?,
  category: json['category'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$AmenityModelToJson(AmenityModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'icon': instance.icon,
  'category': instance.category,
  'is_active': instance.isActive,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

PropertyAmenityModel _$PropertyAmenityModelFromJson(Map<String, dynamic> json) =>
    PropertyAmenityModel(
      id: (json['id'] as num).toInt(),
      propertyId: (json['property_id'] as num).toInt(),
      amenityId: (json['amenity_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      amenity:
          json['amenity'] == null
              ? null
              : AmenityModel.fromJson(json['amenity'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyAmenityModelToJson(PropertyAmenityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_id': instance.propertyId,
      'amenity_id': instance.amenityId,
      'created_at': instance.createdAt.toIso8601String(),
      'amenity': instance.amenity,
    };

PropertyAmenityResponse _$PropertyAmenityResponseFromJson(Map<String, dynamic> json) =>
    PropertyAmenityResponse(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      icon: json['icon'] as String?,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$PropertyAmenityResponseToJson(PropertyAmenityResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'icon': instance.icon,
      'category': instance.category,
    };
