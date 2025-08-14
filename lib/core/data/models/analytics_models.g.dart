// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsEventModel _$AnalyticsEventModelFromJson(Map<String, dynamic> json) =>
    AnalyticsEventModel(
      userId: (json['user_id'] as num).toInt(),
      eventType: json['event_type'] as String? ?? 'unknown_event',
      eventData: json['event_data'] as Map<String, dynamic>? ?? {},
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['session_id'] as String?,
      userAgent: json['user_agent'] as String?,
      ipAddress: json['ip_address'] as String?,
    );

Map<String, dynamic> _$AnalyticsEventModelToJson(
        AnalyticsEventModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'event_type': instance.eventType,
      'event_data': instance.eventData,
      'timestamp': instance.timestamp.toIso8601String(),
      'session_id': instance.sessionId,
      'user_agent': instance.userAgent,
      'ip_address': instance.ipAddress,
    };

SwipeStatsModel _$SwipeStatsModelFromJson(Map<String, dynamic> json) =>
    SwipeStatsModel(
      totalSwipes: (json['total_swipes'] as num?)?.toInt() ?? 0,
      totalLikes: (json['total_likes'] as num?)?.toInt() ?? 0,
      totalPasses: (json['total_passes'] as num?)?.toInt() ?? 0,
      likeRate: (json['like_rate'] as num?)?.toDouble() ?? 0.0,
      averageInteractionTime:
          (json['average_interaction_time'] as num?)?.toDouble() ?? 0.0,
      mostLikedPropertyType: json['most_liked_property_type'] as String?,
      preferredPriceRange:
          (json['preferred_price_range'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$SwipeStatsModelToJson(SwipeStatsModel instance) =>
    <String, dynamic>{
      'total_swipes': instance.totalSwipes,
      'total_likes': instance.totalLikes,
      'total_passes': instance.totalPasses,
      'like_rate': instance.likeRate,
      'average_interaction_time': instance.averageInteractionTime,
      'most_liked_property_type': instance.mostLikedPropertyType,
      'preferred_price_range': instance.preferredPriceRange,
    };

SearchAnalyticsModel _$SearchAnalyticsModelFromJson(
        Map<String, dynamic> json) =>
    SearchAnalyticsModel(
      totalSearches: (json['total_searches'] as num?)?.toInt() ?? 0,
      mostSearchedLocations: (json['most_searched_locations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      mostSearchedPropertyTypes:
          (json['most_searched_property_types'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
      averageSearchFilters:
          (json['average_search_filters'] as num?)?.toInt() ?? 0,
      searchToViewRate:
          (json['search_to_view_rate'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$SearchAnalyticsModelToJson(
        SearchAnalyticsModel instance) =>
    <String, dynamic>{
      'total_searches': instance.totalSearches,
      'most_searched_locations': instance.mostSearchedLocations,
      'most_searched_property_types': instance.mostSearchedPropertyTypes,
      'average_search_filters': instance.averageSearchFilters,
      'search_to_view_rate': instance.searchToViewRate,
    };

PropertyViewAnalyticsModel _$PropertyViewAnalyticsModelFromJson(
        Map<String, dynamic> json) =>
    PropertyViewAnalyticsModel(
      totalViews: (json['total_views'] as num?)?.toInt() ?? 0,
      uniquePropertiesViewed:
          (json['unique_properties_viewed'] as num?)?.toInt() ?? 0,
      averageViewDuration:
          (json['average_view_duration'] as num?)?.toDouble() ?? 0.0,
      viewToLikeRate: (json['view_to_like_rate'] as num?)?.toDouble() ?? 0.0,
      viewToVisitRate: (json['view_to_visit_rate'] as num?)?.toDouble() ?? 0.0,
      mostViewedPropertyTypes:
          (json['most_viewed_property_types'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
    );

Map<String, dynamic> _$PropertyViewAnalyticsModelToJson(
        PropertyViewAnalyticsModel instance) =>
    <String, dynamic>{
      'total_views': instance.totalViews,
      'unique_properties_viewed': instance.uniquePropertiesViewed,
      'average_view_duration': instance.averageViewDuration,
      'view_to_like_rate': instance.viewToLikeRate,
      'view_to_visit_rate': instance.viewToVisitRate,
      'most_viewed_property_types': instance.mostViewedPropertyTypes,
    };

UserPreferencesInsightsModel _$UserPreferencesInsightsModelFromJson(
        Map<String, dynamic> json) =>
    UserPreferencesInsightsModel(
      preferredPropertyTypes:
          (json['preferred_property_types'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              {},
      preferredLocations:
          (json['preferred_locations'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              {},
      priceRangeInsights:
          (json['price_range_insights'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toDouble()),
              ) ??
              {},
      bedroomPreferences:
          (json['bedroom_preferences'] as Map<String, dynamic>?)?.map(
                (k, e) => MapEntry(k, (e as num).toInt()),
              ) ??
              {},
      mostUsedFilters: (json['most_used_filters'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendationAccuracy:
          (json['recommendation_accuracy'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$UserPreferencesInsightsModelToJson(
        UserPreferencesInsightsModel instance) =>
    <String, dynamic>{
      'preferred_property_types': instance.preferredPropertyTypes,
      'preferred_locations': instance.preferredLocations,
      'price_range_insights': instance.priceRangeInsights,
      'bedroom_preferences': instance.bedroomPreferences,
      'most_used_filters': instance.mostUsedFilters,
      'recommendation_accuracy': instance.recommendationAccuracy,
    };
