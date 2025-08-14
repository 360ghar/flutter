// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyModel _$PropertyModelFromJson(Map<String, dynamic> json) =>
    PropertyModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'Unknown Property',
      description: json['description'] as String?,
      propertyType: $enumDecode(_$PropertyTypeEnumMap, json['property_type']),
      purpose: $enumDecode(_$PropertyPurposeEnumMap, json['purpose']),
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      status: $enumDecode(_$PropertyStatusEnumMap, json['status']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String? ?? 'India',
      pincode: json['pincode'] as String?,
      locality: json['locality'] as String?,
      subLocality: json['sub_locality'] as String?,
      landmark: json['landmark'] as String?,
      fullAddress: json['full_address'] as String?,
      areaType: json['area_type'] as String?,
      areaSqft: (json['area_sqft'] as num?)?.toDouble(),
      bedrooms: (json['bedrooms'] as num?)?.toInt(),
      bathrooms: (json['bathrooms'] as num?)?.toInt(),
      balconies: (json['balconies'] as num?)?.toInt(),
      parkingSpaces: (json['parking_spaces'] as num?)?.toInt(),
      pricePerSqft: (json['price_per_sqft'] as num?)?.toDouble(),
      monthlyRent: (json['monthly_rent'] as num?)?.toDouble(),
      dailyRate: (json['daily_rate'] as num?)?.toDouble(),
      securityDeposit: (json['security_deposit'] as num?)?.toDouble(),
      maintenanceCharges: (json['maintenance_charges'] as num?)?.toDouble(),
      floorNumber: (json['floor_number'] as num?)?.toInt(),
      totalFloors: (json['total_floors'] as num?)?.toInt(),
      ageOfProperty: (json['age_of_property'] as num?)?.toInt(),
      maxOccupancy: (json['max_occupancy'] as num?)?.toInt(),
      minimumStayDays: (json['minimum_stay_days'] as num?)?.toInt(),
      amenities: (json['amenities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      features: json['features'] as Map<String, dynamic>?,
      mainImageUrl: json['main_image_url'] as String?,
      virtualTourUrl: json['virtual_tour_url'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      availableFrom: json['available_from'] as String?,
      calendarData: json['calendar_data'] as Map<String, dynamic>?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      ownerName: json['owner_name'] as String?,
      ownerContact: json['owner_contact'] as String?,
      builderName: json['builder_name'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      interestCount: (json['interest_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => PropertyImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PropertyModelToJson(PropertyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'property_type': _$PropertyTypeEnumMap[instance.propertyType]!,
      'purpose': _$PropertyPurposeEnumMap[instance.purpose]!,
      'base_price': instance.basePrice,
      'status': _$PropertyStatusEnumMap[instance.status]!,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'city': instance.city,
      'state': instance.state,
      'country': instance.country,
      'pincode': instance.pincode,
      'locality': instance.locality,
      'sub_locality': instance.subLocality,
      'landmark': instance.landmark,
      'full_address': instance.fullAddress,
      'area_type': instance.areaType,
      'area_sqft': instance.areaSqft,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'balconies': instance.balconies,
      'parking_spaces': instance.parkingSpaces,
      'price_per_sqft': instance.pricePerSqft,
      'monthly_rent': instance.monthlyRent,
      'daily_rate': instance.dailyRate,
      'security_deposit': instance.securityDeposit,
      'maintenance_charges': instance.maintenanceCharges,
      'floor_number': instance.floorNumber,
      'total_floors': instance.totalFloors,
      'age_of_property': instance.ageOfProperty,
      'max_occupancy': instance.maxOccupancy,
      'minimum_stay_days': instance.minimumStayDays,
      'amenities': instance.amenities,
      'features': instance.features,
      'main_image_url': instance.mainImageUrl,
      'virtual_tour_url': instance.virtualTourUrl,
      'is_available': instance.isAvailable,
      'available_from': instance.availableFrom,
      'calendar_data': instance.calendarData,
      'tags': instance.tags,
      'owner_name': instance.ownerName,
      'owner_contact': instance.ownerContact,
      'builder_name': instance.builderName,
      'view_count': instance.viewCount,
      'like_count': instance.likeCount,
      'interest_count': instance.interestCount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'images': instance.images?.map((e) => e.toJson()).toList(),
      'distance_km': instance.distanceKm,
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

const _$PropertyStatusEnumMap = {
  PropertyStatus.available: 'available',
  PropertyStatus.sold: 'sold',
  PropertyStatus.rented: 'rented',
  PropertyStatus.underOffer: 'under_offer',
  PropertyStatus.maintenance: 'maintenance',
};
