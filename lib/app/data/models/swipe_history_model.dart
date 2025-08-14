import 'package:json_annotation/json_annotation.dart';

part 'swipe_history_model.g.dart';

@JsonSerializable()
class SwipeHistory {
  final List<UserSwipe> swipes;
  @JsonKey(name: 'total_likes')
  final int totalLikes;
  @JsonKey(name: 'total_passes')
  final int totalPasses;
  @JsonKey(name: 'total_swipes')
  final int totalSwipes;
  
  // Pagination fields (not in API spec but needed for our implementation)
  final int? total;
  final int? page;
  final int? limit;
  @JsonKey(name: 'total_pages')
  final int? totalPages;

  SwipeHistory({
    required this.swipes,
    required this.totalLikes,
    required this.totalPasses,
    required this.totalSwipes,
    this.total,
    this.page,
    this.limit,
    this.totalPages,
  });

  factory SwipeHistory.fromJson(Map<String, dynamic> json) => 
      _$SwipeHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$SwipeHistoryToJson(this);
  
  bool get hasMore => totalPages != null && page != null && page! < totalPages!;
}

@JsonSerializable()
class UserSwipe {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'is_liked')
  final bool isLiked;
  @JsonKey(name: 'swipe_timestamp')
  final DateTime swipeTimestamp;
  @JsonKey(name: 'user_location_lat')
  final String? userLocationLat;
  @JsonKey(name: 'user_location_lng')
  final String? userLocationLng;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  UserSwipe({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.isLiked,
    required this.swipeTimestamp,
    this.userLocationLat,
    this.userLocationLng,
    this.sessionId,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserSwipe.fromJson(Map<String, dynamic> json) => 
      _$UserSwipeFromJson(json);

  Map<String, dynamic> toJson() => _$UserSwipeToJson(this);
}

@JsonSerializable()
class PropertySwipe {
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'is_liked')
  final bool isLiked;
  @JsonKey(name: 'user_location_lat')
  final String? userLocationLat;
  @JsonKey(name: 'user_location_lng')
  final String? userLocationLng;
  @JsonKey(name: 'session_id')
  final String? sessionId;

  PropertySwipe({
    required this.propertyId,
    required this.isLiked,
    this.userLocationLat,
    this.userLocationLng,
    this.sessionId,
  });

  factory PropertySwipe.fromJson(Map<String, dynamic> json) => 
      _$PropertySwipeFromJson(json);

  Map<String, dynamic> toJson() => _$PropertySwipeToJson(this);
}