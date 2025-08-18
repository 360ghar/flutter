import 'package:json_annotation/json_annotation.dart';

part 'swipe_history_model.g.dart';

@JsonSerializable()
class SwipeHistory {
  final List<SwipeHistoryItem> items;
  final int total;
  final int page;
  final int limit;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  SwipeHistory({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory SwipeHistory.fromJson(Map<String, dynamic> json) => 
      _$SwipeHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$SwipeHistoryToJson(this);
  
  bool get hasMore => page < totalPages;
}

@JsonSerializable()
class SwipeHistoryItem {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'is_liked')
  final bool isLiked;
  @JsonKey(name: 'swipe_timestamp')
  final DateTime? swipeTimestamp;
  @JsonKey(name: 'user_location_lat')
  final double? userLocationLat;
  @JsonKey(name: 'user_location_lng')
  final double? userLocationLng;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final Map<String, dynamic> property;

  SwipeHistoryItem({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.isLiked,
    this.swipeTimestamp,
    this.userLocationLat,
    this.userLocationLng,
    this.sessionId,
    required this.createdAt,
    this.updatedAt,
    required this.property,
  });

  factory SwipeHistoryItem.fromJson(Map<String, dynamic> json) => 
      _$SwipeHistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$SwipeHistoryItemToJson(this);
}

@JsonSerializable()
class SwipePropertyInfo {
  final int id;
  final String title;
  @JsonKey(name: 'property_type')
  final String propertyType;
  final String purpose;
  @JsonKey(name: 'base_price')
  final double basePrice;
  final String city;
  final String locality;
  final int bedrooms;
  final int bathrooms;
  @JsonKey(name: 'area_sqft')
  final double areaSqft;
  @JsonKey(name: 'main_image_url')
  final String? mainImageUrl;

  SwipePropertyInfo({
    required this.id,
    required this.title,
    required this.propertyType,
    required this.purpose,
    required this.basePrice,
    required this.city,
    required this.locality,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqft,
    this.mainImageUrl,
  });

  factory SwipePropertyInfo.fromJson(Map<String, dynamic> json) => 
      _$SwipePropertyInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SwipePropertyInfoToJson(this);
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