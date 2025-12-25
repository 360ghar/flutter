// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_image_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyImageModel _$PropertyImageModelFromJson(Map<String, dynamic> json) => PropertyImageModel(
  id: (json['id'] as num).toInt(),
  propertyId: (json['property_id'] as num).toInt(),
  imageUrl: json['image_url'] as String? ?? 'https://via.placeholder.com/400x300?text=No+Image',
  caption: json['caption'] as String?,
  displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
  isMainImage: json['is_main_image'] as bool? ?? false,
  isMain: json['is_main'] as bool? ?? false,
  category: json['category'] as String? ?? 'gallery',
);

Map<String, dynamic> _$PropertyImageModelToJson(PropertyImageModel instance) => <String, dynamic>{
  'id': instance.id,
  'property_id': instance.propertyId,
  'image_url': instance.imageUrl,
  'caption': instance.caption,
  'display_order': instance.displayOrder,
  'is_main_image': instance.isMainImage,
  'is_main': instance.isMain,
  'category': instance.category,
};
