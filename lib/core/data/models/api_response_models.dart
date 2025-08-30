import 'package:json_annotation/json_annotation.dart';

part 'api_response_models.g.dart';

// Sort options for property searches
enum SortBy {
  @JsonValue('distance')
  distance,
  @JsonValue('price_low')
  priceLow,
  @JsonValue('price_high')
  priceHigh,
  @JsonValue('newest')
  newest,
  @JsonValue('popular')
  popular,
  @JsonValue('relevance')
  relevance,
}

@JsonSerializable()
class PaginationParams {
  final int page;
  final int limit;

  PaginationParams({this.page = 1, this.limit = 20});

  factory PaginationParams.fromJson(Map<String, dynamic> json) =>
      _$PaginationParamsFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationParamsToJson(this);

  int getOffset() => (page - 1) * limit;
}

// Note: Using manual fromJson/toJson for generic type support
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int limit;
  @JsonKey(name: 'total_pages')
  final int totalPages;
  @JsonKey(name: 'has_next')
  final bool hasNext;
  @JsonKey(name: 'has_prev')
  final bool hasPrev;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List<dynamic>).map((e) => fromJsonT(e)).toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['total_pages'] as int,
      hasNext: json['has_next'] as bool,
      hasPrev: json['has_prev'] as bool,
    );
  }

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) => {
    'items': items.map((e) => toJsonT(e)).toList(),
    'total': total,
    'page': page,
    'limit': limit,
    'total_pages': totalPages,
    'has_next': hasNext,
    'has_prev': hasPrev,
  };
}

@JsonSerializable()
class MessageResponse {
  final String message;
  final bool success;

  MessageResponse({required this.message, this.success = true});

  factory MessageResponse.fromJson(Map<String, dynamic> json) =>
      _$MessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MessageResponseToJson(this);
}

@JsonSerializable()
class ErrorResponse {
  final String message;
  @JsonKey(name: 'error_code')
  final String? errorCode;
  final Map<String, dynamic>? details;

  ErrorResponse({required this.message, this.errorCode, this.details});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);
}

@JsonSerializable()
class SearchParams {
  final String? query;
  final double? latitude;
  final double? longitude;
  @JsonKey(name: 'radius_km')
  final int radiusKm;
  final int page;
  final int limit;

  SearchParams({
    this.query,
    this.latitude,
    this.longitude,
    this.radiusKm = 10,
    this.page = 1,
    this.limit = 20,
  });

  factory SearchParams.fromJson(Map<String, dynamic> json) =>
      _$SearchParamsFromJson(json);

  Map<String, dynamic> toJson() => _$SearchParamsToJson(this);
}

@JsonSerializable()
class NotificationSettings {
  @JsonKey(name: 'email_notifications')
  final bool emailNotifications;
  @JsonKey(name: 'push_notifications')
  final bool pushNotifications;
  @JsonKey(name: 'sms_notifications')
  final bool smsNotifications;
  @JsonKey(name: 'visit_reminders')
  final bool visitReminders;
  @JsonKey(name: 'property_updates')
  final bool propertyUpdates;
  @JsonKey(name: 'promotional_emails')
  final bool promotionalEmails;

  NotificationSettings({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.smsNotifications = false,
    this.visitReminders = true,
    this.propertyUpdates = true,
    this.promotionalEmails = false,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  NotificationSettings copyWith({
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    bool? visitReminders,
    bool? propertyUpdates,
    bool? promotionalEmails,
  }) {
    return NotificationSettings(
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      visitReminders: visitReminders ?? this.visitReminders,
      propertyUpdates: propertyUpdates ?? this.propertyUpdates,
      promotionalEmails: promotionalEmails ?? this.promotionalEmails,
    );
  }
}

@JsonSerializable()
class PrivacySettings {
  @JsonKey(name: 'profile_visibility')
  final String profileVisibility; // "public", "private"
  @JsonKey(name: 'location_sharing')
  final bool locationSharing;
  @JsonKey(name: 'contact_sharing')
  final bool contactSharing;
  @JsonKey(name: 'search_history_tracking')
  final bool searchHistoryTracking;

  PrivacySettings({
    this.profileVisibility = 'public',
    this.locationSharing = true,
    this.contactSharing = true,
    this.searchHistoryTracking = true,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) =>
      _$PrivacySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);

  PrivacySettings copyWith({
    String? profileVisibility,
    bool? locationSharing,
    bool? contactSharing,
    bool? searchHistoryTracking,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      locationSharing: locationSharing ?? this.locationSharing,
      contactSharing: contactSharing ?? this.contactSharing,
      searchHistoryTracking:
          searchHistoryTracking ?? this.searchHistoryTracking,
    );
  }

  bool get isProfilePublic => profileVisibility == 'public';
  bool get isProfilePrivate => profileVisibility == 'private';
}

// Location update model
@JsonSerializable()
class LocationUpdate {
  final double latitude;
  final double longitude;

  LocationUpdate({required this.latitude, required this.longitude});

  factory LocationUpdate.fromJson(Map<String, dynamic> json) =>
      _$LocationUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$LocationUpdateToJson(this);
}
