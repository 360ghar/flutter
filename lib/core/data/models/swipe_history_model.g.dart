// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwipeHistory _$SwipeHistoryFromJson(Map<String, dynamic> json) => SwipeHistory(
  items: (json['items'] as List<dynamic>)
      .map((e) => SwipeHistoryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
  totalPages: (json['total_pages'] as num).toInt(),
);

Map<String, dynamic> _$SwipeHistoryToJson(SwipeHistory instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'total_pages': instance.totalPages,
    };

SwipeHistoryItem _$SwipeHistoryItemFromJson(Map<String, dynamic> json) =>
    SwipeHistoryItem(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      propertyId: (json['property_id'] as num).toInt(),
      isLiked: json['is_liked'] as bool,
      swipeTimestamp: json['swipe_timestamp'] == null
          ? null
          : DateTime.parse(json['swipe_timestamp'] as String),
      userLocationLat: (json['user_location_lat'] as num?)?.toDouble(),
      userLocationLng: (json['user_location_lng'] as num?)?.toDouble(),
      sessionId: json['session_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      property: json['property'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$SwipeHistoryItemToJson(SwipeHistoryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'property_id': instance.propertyId,
      'is_liked': instance.isLiked,
      'swipe_timestamp': instance.swipeTimestamp?.toIso8601String(),
      'user_location_lat': instance.userLocationLat,
      'user_location_lng': instance.userLocationLng,
      'session_id': instance.sessionId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'property': instance.property,
    };

SwipePropertyInfo _$SwipePropertyInfoFromJson(Map<String, dynamic> json) =>
    SwipePropertyInfo(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      propertyType: json['property_type'] as String,
      purpose: json['purpose'] as String,
      basePrice: (json['base_price'] as num).toDouble(),
      city: json['city'] as String,
      locality: json['locality'] as String,
      bedrooms: (json['bedrooms'] as num).toInt(),
      bathrooms: (json['bathrooms'] as num).toInt(),
      areaSqft: (json['area_sqft'] as num).toDouble(),
      mainImageUrl: json['main_image_url'] as String?,
    );

Map<String, dynamic> _$SwipePropertyInfoToJson(SwipePropertyInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'property_type': instance.propertyType,
      'purpose': instance.purpose,
      'base_price': instance.basePrice,
      'city': instance.city,
      'locality': instance.locality,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'area_sqft': instance.areaSqft,
      'main_image_url': instance.mainImageUrl,
    };

PropertySwipe _$PropertySwipeFromJson(Map<String, dynamic> json) =>
    PropertySwipe(
      propertyId: (json['property_id'] as num).toInt(),
      isLiked: json['is_liked'] as bool,
      userLocationLat: json['user_location_lat'] as String?,
      userLocationLng: json['user_location_lng'] as String?,
      sessionId: json['session_id'] as String?,
    );

Map<String, dynamic> _$PropertySwipeToJson(PropertySwipe instance) =>
    <String, dynamic>{
      'property_id': instance.propertyId,
      'is_liked': instance.isLiked,
      'user_location_lat': instance.userLocationLat,
      'user_location_lng': instance.userLocationLng,
      'session_id': instance.sessionId,
    };
