// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filters_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FiltersModel _$FiltersModelFromJson(Map<String, dynamic> json) => FiltersModel(
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      radius: (json['radius'] as num?)?.toInt() ?? 5,
      q: json['q'] as String?,
      propertyType: (json['property_type'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$PropertyTypeEnumMap, e))
          .toList(),
      purpose: $enumDecodeNullable(_$PropertyPurposeEnumMap, json['purpose']),
      priceMin: (json['price_min'] as num?)?.toDouble(),
      priceMax: (json['price_max'] as num?)?.toDouble(),
      bedroomsMin: (json['bedrooms_min'] as num?)?.toInt(),
      bedroomsMax: (json['bedrooms_max'] as num?)?.toInt(),
      bathroomsMin: (json['bathrooms_min'] as num?)?.toInt(),
      bathroomsMax: (json['bathrooms_max'] as num?)?.toInt(),
      areaMin: (json['area_min'] as num?)?.toDouble(),
      areaMax: (json['area_max'] as num?)?.toDouble(),
      city: json['city'] as String?,
      locality: json['locality'] as String?,
      pincode: json['pincode'] as String?,
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      parkingSpacesMin: (json['parking_spaces_min'] as num?)?.toInt(),
      floorNumberMin: (json['floor_number_min'] as num?)?.toInt(),
      floorNumberMax: (json['floor_number_max'] as num?)?.toInt(),
      ageMax: (json['age_max'] as num?)?.toInt(),
      checkIn: json['check_in'] as String?,
      checkOut: json['check_out'] as String?,
      guests: (json['guests'] as num?)?.toInt(),
      sortBy: json['sort_by'] as String? ?? 'distance',
    );

Map<String, dynamic> _$FiltersModelToJson(FiltersModel instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'radius': instance.radius,
      'q': instance.q,
      'property_type':
          instance.propertyType?.map((e) => _$PropertyTypeEnumMap[e]!).toList(),
      'purpose': _$PropertyPurposeEnumMap[instance.purpose],
      'price_min': instance.priceMin,
      'price_max': instance.priceMax,
      'bedrooms_min': instance.bedroomsMin,
      'bedrooms_max': instance.bedroomsMax,
      'bathrooms_min': instance.bathroomsMin,
      'bathrooms_max': instance.bathroomsMax,
      'area_min': instance.areaMin,
      'area_max': instance.areaMax,
      'city': instance.city,
      'locality': instance.locality,
      'pincode': instance.pincode,
      'amenities': instance.amenities,
      'parking_spaces_min': instance.parkingSpacesMin,
      'floor_number_min': instance.floorNumberMin,
      'floor_number_max': instance.floorNumberMax,
      'age_max': instance.ageMax,
      'check_in': instance.checkIn,
      'check_out': instance.checkOut,
      'guests': instance.guests,
      'sort_by': instance.sortBy,
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
