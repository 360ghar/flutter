// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_card_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyCardModel _$PropertyCardModelFromJson(Map<String, dynamic> json) =>
    PropertyCardModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'Unknown Property',
      propertyType: $enumDecode(_$PropertyTypeEnumMap, json['property_type']),
      purpose: $enumDecode(_$PropertyPurposeEnumMap, json['purpose']),
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      areaSqft: (json['area_sqft'] as num?)?.toDouble(),
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      mainImageUrl: json['main_image_url'] as String?,
      virtualTourUrl: json['virtual_tour_url'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      locality: json['locality'] as String?,
      pincode: json['pincode'] as String?,
      fullAddress: json['full_address'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PropertyCardModelToJson(PropertyCardModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'property_type': _$PropertyTypeEnumMap[instance.propertyType]!,
      'purpose': _$PropertyPurposeEnumMap[instance.purpose]!,
      'base_price': instance.basePrice,
      'area_sqft': instance.areaSqft,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'main_image_url': instance.mainImageUrl,
      'virtual_tour_url': instance.virtualTourUrl,
      'city': instance.city,
      'state': instance.state,
      'locality': instance.locality,
      'pincode': instance.pincode,
      'full_address': instance.fullAddress,
      'distance_km': instance.distanceKm,
      'like_count': instance.likeCount,
    };

const _$PropertyTypeEnumMap = {
  PropertyType.house: 'house',
  PropertyType.apartment: 'apartment',
  PropertyType.builderFloor: 'builder_floor',
  PropertyType.room: 'room',
};

const _$PropertyPurposeEnumMap = {
  PropertyPurpose.buy: 'buy',
  PropertyPurpose.rent: 'rent',
  PropertyPurpose.shortStay: 'short_stay',
};
