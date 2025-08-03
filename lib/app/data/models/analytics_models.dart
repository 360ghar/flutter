import 'package:json_annotation/json_annotation.dart';

part 'analytics_models.g.dart';

@JsonSerializable()
class AnalyticsEventModel {
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'event_type', defaultValue: 'unknown_event')
  final String eventType;
  @JsonKey(name: 'event_data', defaultValue: <String, dynamic>{})
  final Map<String, dynamic> eventData;
  final DateTime timestamp;
  @JsonKey(name: 'session_id')
  final String? sessionId;
  @JsonKey(name: 'user_agent')
  final String? userAgent;
  @JsonKey(name: 'ip_address')
  final String? ipAddress;

  AnalyticsEventModel({
    required this.userId,
    required this.eventType,
    required this.eventData,
    required this.timestamp,
    this.sessionId,
    this.userAgent,
    this.ipAddress,
  });

  factory AnalyticsEventModel.fromJson(Map<String, dynamic> json) => _$AnalyticsEventModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsEventModelToJson(this);
}

@JsonSerializable()
class SwipeStatsModel {
  @JsonKey(name: 'total_swipes', defaultValue: 0)
  final int totalSwipes;
  @JsonKey(name: 'total_likes', defaultValue: 0)
  final int totalLikes;
  @JsonKey(name: 'total_passes', defaultValue: 0)
  final int totalPasses;
  @JsonKey(name: 'like_rate', defaultValue: 0.0)
  final double likeRate;
  @JsonKey(name: 'average_interaction_time', defaultValue: 0.0)
  final double averageInteractionTime;
  @JsonKey(name: 'most_liked_property_type')
  final String? mostLikedPropertyType;
  @JsonKey(name: 'preferred_price_range')
  final Map<String, double>? preferredPriceRange;

  SwipeStatsModel({
    required this.totalSwipes,
    required this.totalLikes,
    required this.totalPasses,
    required this.likeRate,
    required this.averageInteractionTime,
    this.mostLikedPropertyType,
    this.preferredPriceRange,
  });

  factory SwipeStatsModel.fromJson(Map<String, dynamic> json) => _$SwipeStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SwipeStatsModelToJson(this);

  // Convenience getters
  String get likeRateFormatted => '${likeRate.toStringAsFixed(1)}%';
  String get averageInteractionTimeFormatted => '${averageInteractionTime.toStringAsFixed(1)}s';
  
  bool get hasData => totalSwipes > 0;
  
  String get swipeSummary {
    if (!hasData) return 'No swipe data available';
    return '$totalSwipes swipes • $totalLikes likes • $totalPasses passes';
  }
}

@JsonSerializable()
class SearchAnalyticsModel {
  @JsonKey(name: 'total_searches', defaultValue: 0)
  final int totalSearches;
  @JsonKey(name: 'most_searched_locations', defaultValue: <String>[])
  final List<String> mostSearchedLocations;
  @JsonKey(name: 'most_searched_property_types', defaultValue: <String>[])
  final List<String> mostSearchedPropertyTypes;
  @JsonKey(name: 'average_search_filters', defaultValue: 0)
  final int averageSearchFilters;
  @JsonKey(name: 'search_to_view_rate', defaultValue: 0.0)
  final double searchToViewRate;

  SearchAnalyticsModel({
    required this.totalSearches,
    required this.mostSearchedLocations,
    required this.mostSearchedPropertyTypes,
    required this.averageSearchFilters,
    required this.searchToViewRate,
  });

  factory SearchAnalyticsModel.fromJson(Map<String, dynamic> json) => _$SearchAnalyticsModelFromJson(json);

  Map<String, dynamic> toJson() => _$SearchAnalyticsModelToJson(this);

  // Convenience getters
  String get searchToViewRateFormatted => '${searchToViewRate.toStringAsFixed(1)}%';
  
  bool get hasData => totalSearches > 0;
  
  String get topLocation => mostSearchedLocations.isNotEmpty ? mostSearchedLocations.first : 'N/A';
  String get topPropertyType => mostSearchedPropertyTypes.isNotEmpty ? mostSearchedPropertyTypes.first : 'N/A';
}

@JsonSerializable()
class PropertyViewAnalyticsModel {
  @JsonKey(name: 'total_views', defaultValue: 0)
  final int totalViews;
  @JsonKey(name: 'unique_properties_viewed', defaultValue: 0)
  final int uniquePropertiesViewed;
  @JsonKey(name: 'average_view_duration', defaultValue: 0.0)
  final double averageViewDuration;
  @JsonKey(name: 'view_to_like_rate', defaultValue: 0.0)
  final double viewToLikeRate;
  @JsonKey(name: 'view_to_visit_rate', defaultValue: 0.0)
  final double viewToVisitRate;
  @JsonKey(name: 'most_viewed_property_types', defaultValue: <String>[])
  final List<String> mostViewedPropertyTypes;

  PropertyViewAnalyticsModel({
    required this.totalViews,
    required this.uniquePropertiesViewed,
    required this.averageViewDuration,
    required this.viewToLikeRate,
    required this.viewToVisitRate,
    required this.mostViewedPropertyTypes,
  });

  factory PropertyViewAnalyticsModel.fromJson(Map<String, dynamic> json) => _$PropertyViewAnalyticsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyViewAnalyticsModelToJson(this);

  // Convenience getters
  String get averageViewDurationFormatted => '${averageViewDuration.toStringAsFixed(1)}s';
  String get viewToLikeRateFormatted => '${viewToLikeRate.toStringAsFixed(1)}%';
  String get viewToVisitRateFormatted => '${viewToVisitRate.toStringAsFixed(1)}%';
  
  bool get hasData => totalViews > 0;
  
  String get topViewedPropertyType => mostViewedPropertyTypes.isNotEmpty ? mostViewedPropertyTypes.first : 'N/A';
  
  double get repeatViewRate {
    if (uniquePropertiesViewed == 0) return 0.0;
    return ((totalViews - uniquePropertiesViewed) / totalViews) * 100;
  }
  
  String get repeatViewRateFormatted => '${repeatViewRate.toStringAsFixed(1)}%';
}

@JsonSerializable()
class UserPreferencesInsightsModel {
  @JsonKey(name: 'preferred_property_types', defaultValue: <String, int>{})
  final Map<String, int> preferredPropertyTypes;
  @JsonKey(name: 'preferred_locations', defaultValue: <String, int>{})
  final Map<String, int> preferredLocations;
  @JsonKey(name: 'price_range_insights', defaultValue: <String, double>{})
  final Map<String, double> priceRangeInsights;
  @JsonKey(name: 'bedroom_preferences', defaultValue: <String, int>{})
  final Map<String, int> bedroomPreferences;
  @JsonKey(name: 'most_used_filters', defaultValue: <String>[])
  final List<String> mostUsedFilters;
  @JsonKey(name: 'recommendation_accuracy', defaultValue: 0.0)
  final double recommendationAccuracy;

  UserPreferencesInsightsModel({
    required this.preferredPropertyTypes,
    required this.preferredLocations,
    required this.priceRangeInsights,
    required this.bedroomPreferences,
    required this.mostUsedFilters,
    required this.recommendationAccuracy,
  });

  factory UserPreferencesInsightsModel.fromJson(Map<String, dynamic> json) => _$UserPreferencesInsightsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserPreferencesInsightsModelToJson(this);

  // Convenience getters
  String get recommendationAccuracyFormatted => '${recommendationAccuracy.toStringAsFixed(1)}%';
  
  String? get topPreferredPropertyType {
    if (preferredPropertyTypes.isEmpty) return null;
    return preferredPropertyTypes.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  String? get topPreferredLocation {
    if (preferredLocations.isEmpty) return null;
    return preferredLocations.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  String? get mostPreferredBedrooms {
    if (bedroomPreferences.isEmpty) return null;
    return bedroomPreferences.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
  
  bool get hasPreferences => 
      preferredPropertyTypes.isNotEmpty || 
      preferredLocations.isNotEmpty || 
      bedroomPreferences.isNotEmpty;
}