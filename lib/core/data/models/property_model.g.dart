// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyAmenity _$PropertyAmenityFromJson(Map<String, dynamic> json) => PropertyAmenity(
  id: (json['id'] as num?)?.toInt() ?? -1,
  title: json['title'] as String? ?? 'Unknown',
  icon: json['icon'] as String?,
  category: json['category'] as String?,
);

Map<String, dynamic> _$PropertyAmenityToJson(PropertyAmenity instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'icon': instance.icon,
  'category': instance.category,
};

PropertyModel _$PropertyModelFromJson(Map<String, dynamic> json) => $checkedCreate(
  'PropertyModel',
  json,
  ($checkedConvert) {
    final val = PropertyModel(
      id: $checkedConvert('id', (v) => (v as num?)?.toInt() ?? -1),
      title: $checkedConvert('title', (v) => v as String? ?? 'Unknown Property'),
      description: $checkedConvert('description', (v) => v as String?),
      propertyType: $checkedConvert(
        'property_type',
        (v) => $enumDecodeNullable(_$PropertyTypeEnumMap, v, unknownValue: PropertyType.house),
      ),
      purpose: $checkedConvert(
        'purpose',
        (v) => $enumDecodeNullable(_$PropertyPurposeEnumMap, v, unknownValue: PropertyPurpose.buy),
      ),
      basePrice: $checkedConvert('base_price', (v) => (v as num?)?.toDouble() ?? 0.0),
      status: $checkedConvert(
        'status',
        (v) =>
            $enumDecodeNullable(_$PropertyStatusEnumMap, v, unknownValue: PropertyStatus.available),
      ),
      latitude: $checkedConvert('latitude', (v) => (v as num?)?.toDouble()),
      longitude: $checkedConvert('longitude', (v) => (v as num?)?.toDouble()),
      city: $checkedConvert('city', (v) => v as String?),
      state: $checkedConvert('state', (v) => v as String?),
      country: $checkedConvert('country', (v) => v as String? ?? 'India'),
      pincode: $checkedConvert('pincode', (v) => v as String?),
      locality: $checkedConvert('locality', (v) => v as String?),
      subLocality: $checkedConvert('sub_locality', (v) => v as String?),
      landmark: $checkedConvert('landmark', (v) => v as String?),
      fullAddress: $checkedConvert('full_address', (v) => v as String?),
      areaType: $checkedConvert('area_type', (v) => v as String?),
      areaSqft: $checkedConvert('area_sqft', (v) => (v as num?)?.toDouble()),
      bedrooms: $checkedConvert('bedrooms', (v) => (v as num?)?.toInt()),
      bathrooms: $checkedConvert('bathrooms', (v) => (v as num?)?.toInt()),
      balconies: $checkedConvert('balconies', (v) => (v as num?)?.toInt()),
      parkingSpaces: $checkedConvert('parking_spaces', (v) => (v as num?)?.toInt()),
      pricePerSqft: $checkedConvert('price_per_sqft', (v) => (v as num?)?.toDouble()),
      monthlyRent: $checkedConvert('monthly_rent', (v) => (v as num?)?.toDouble()),
      dailyRate: $checkedConvert('daily_rate', (v) => (v as num?)?.toDouble()),
      securityDeposit: $checkedConvert('security_deposit', (v) => (v as num?)?.toDouble()),
      maintenanceCharges: $checkedConvert('maintenance_charges', (v) => (v as num?)?.toDouble()),
      floorNumber: $checkedConvert('floor_number', (v) => (v as num?)?.toInt()),
      totalFloors: $checkedConvert('total_floors', (v) => (v as num?)?.toInt()),
      ageOfProperty: $checkedConvert('age_of_property', (v) => (v as num?)?.toInt()),
      maxOccupancy: $checkedConvert('max_occupancy', (v) => (v as num?)?.toInt()),
      minimumStayDays: $checkedConvert('minimum_stay_days', (v) => (v as num?)?.toInt()),
      amenities: $checkedConvert(
        'amenities',
        (v) => (v as List<dynamic>?)
            ?.map((e) => PropertyAmenity.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      features: $checkedConvert(
        'features',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      mainImageUrl: $checkedConvert('main_image_url', (v) => v as String?),
      virtualTourUrl: $checkedConvert('virtual_tour_url', (v) => v as String?),
      videoUrls: $checkedConvert(
        'video_urls',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      googleStreetViewUrl: $checkedConvert('google_street_view_url', (v) => v as String?),
      isAvailable: $checkedConvert('is_active', (v) => v as bool? ?? true),
      availableFrom: $checkedConvert('available_from', (v) => v as String?),
      calendarData: $checkedConvert('calendar_data', (v) => v as Map<String, dynamic>?),
      tags: $checkedConvert('tags', (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
      ownerName: $checkedConvert('owner_name', (v) => v as String?),
      ownerContact: $checkedConvert('owner_contact', (v) => v as String?),
      builderName: $checkedConvert('builder_name', (v) => v as String?),
      viewCount: $checkedConvert('view_count', (v) => (v as num?)?.toInt() ?? 0),
      likeCount: $checkedConvert('like_count', (v) => (v as num?)?.toInt() ?? 0),
      interestCount: $checkedConvert('interest_count', (v) => (v as num?)?.toInt() ?? 0),
      createdAt: $checkedConvert(
        'created_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      images: $checkedConvert(
        'images',
        (v) => (v as List<dynamic>?)
            ?.map((e) => PropertyImageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      distanceKm: $checkedConvert('distance_km', (v) => (v as num?)?.toDouble()),
      liked: $checkedConvert('liked', (v) => v as bool? ?? false),
      userHasScheduledVisit: $checkedConvert(
        'user_has_scheduled_visit',
        (v) => v as bool? ?? false,
      ),
      userScheduledVisitCount: $checkedConvert(
        'user_scheduled_visit_count',
        (v) => (v as num?)?.toInt() ?? 0,
      ),
      userNextVisitDate: $checkedConvert(
        'user_next_visit_date',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'propertyType': 'property_type',
    'basePrice': 'base_price',
    'subLocality': 'sub_locality',
    'fullAddress': 'full_address',
    'areaType': 'area_type',
    'areaSqft': 'area_sqft',
    'parkingSpaces': 'parking_spaces',
    'pricePerSqft': 'price_per_sqft',
    'monthlyRent': 'monthly_rent',
    'dailyRate': 'daily_rate',
    'securityDeposit': 'security_deposit',
    'maintenanceCharges': 'maintenance_charges',
    'floorNumber': 'floor_number',
    'totalFloors': 'total_floors',
    'ageOfProperty': 'age_of_property',
    'maxOccupancy': 'max_occupancy',
    'minimumStayDays': 'minimum_stay_days',
    'mainImageUrl': 'main_image_url',
    'virtualTourUrl': 'virtual_tour_url',
    'videoUrls': 'video_urls',
    'googleStreetViewUrl': 'google_street_view_url',
    'isAvailable': 'is_active',
    'availableFrom': 'available_from',
    'calendarData': 'calendar_data',
    'ownerName': 'owner_name',
    'ownerContact': 'owner_contact',
    'builderName': 'builder_name',
    'viewCount': 'view_count',
    'likeCount': 'like_count',
    'interestCount': 'interest_count',
    'createdAt': 'created_at',
    'updatedAt': 'updated_at',
    'distanceKm': 'distance_km',
    'userHasScheduledVisit': 'user_has_scheduled_visit',
    'userScheduledVisitCount': 'user_scheduled_visit_count',
    'userNextVisitDate': 'user_next_visit_date',
  },
);

Map<String, dynamic> _$PropertyModelToJson(PropertyModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'property_type': _$PropertyTypeEnumMap[instance.propertyType],
  'purpose': _$PropertyPurposeEnumMap[instance.purpose],
  'base_price': instance.basePrice,
  'status': _$PropertyStatusEnumMap[instance.status],
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
  'amenities': instance.amenities?.map((e) => e.toJson()).toList(),
  'features': instance.features,
  'main_image_url': instance.mainImageUrl,
  'virtual_tour_url': instance.virtualTourUrl,
  'video_urls': instance.videoUrls,
  'google_street_view_url': instance.googleStreetViewUrl,
  'is_active': instance.isAvailable,
  'available_from': instance.availableFrom,
  'calendar_data': instance.calendarData,
  'tags': instance.tags,
  'owner_name': instance.ownerName,
  'owner_contact': instance.ownerContact,
  'builder_name': instance.builderName,
  'view_count': instance.viewCount,
  'like_count': instance.likeCount,
  'interest_count': instance.interestCount,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'images': instance.images?.map((e) => e.toJson()).toList(),
  'distance_km': instance.distanceKm,
  'liked': instance.liked,
  'user_has_scheduled_visit': instance.userHasScheduledVisit,
  'user_scheduled_visit_count': instance.userScheduledVisitCount,
  'user_next_visit_date': instance.userNextVisitDate?.toIso8601String(),
};

const _$PropertyTypeEnumMap = {
  PropertyType.house: 'house',
  PropertyType.apartment: 'apartment',
  PropertyType.builderFloor: 'builder_floor',
  PropertyType.room: 'room',
  PropertyType.villa: 'villa',
  PropertyType.plot: 'plot',
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
