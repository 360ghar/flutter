// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwipeHistory _$SwipeHistoryFromJson(Map<String, dynamic> json) => SwipeHistory(
      swipes: (json['swipes'] as List<dynamic>)
          .map((e) => UserSwipe.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalLikes: (json['total_likes'] as num).toInt(),
      totalPasses: (json['total_passes'] as num).toInt(),
      totalSwipes: (json['total_swipes'] as num).toInt(),
      total: (json['total'] as num?)?.toInt(),
      page: (json['page'] as num?)?.toInt(),
      limit: (json['limit'] as num?)?.toInt(),
      totalPages: (json['total_pages'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SwipeHistoryToJson(SwipeHistory instance) =>
    <String, dynamic>{
      'swipes': instance.swipes,
      'total_likes': instance.totalLikes,
      'total_passes': instance.totalPasses,
      'total_swipes': instance.totalSwipes,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'total_pages': instance.totalPages,
    };

UserSwipe _$UserSwipeFromJson(Map<String, dynamic> json) => UserSwipe(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      propertyId: (json['property_id'] as num).toInt(),
      isLiked: json['is_liked'] as bool,
      swipeTimestamp: DateTime.parse(json['swipe_timestamp'] as String),
      userLocationLat: json['user_location_lat'] as String?,
      userLocationLng: json['user_location_lng'] as String?,
      sessionId: json['session_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserSwipeToJson(UserSwipe instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'property_id': instance.propertyId,
      'is_liked': instance.isLiked,
      'swipe_timestamp': instance.swipeTimestamp.toIso8601String(),
      'user_location_lat': instance.userLocationLat,
      'user_location_lng': instance.userLocationLng,
      'session_id': instance.sessionId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
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
