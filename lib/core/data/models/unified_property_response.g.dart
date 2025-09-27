// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_property_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedPropertyResponse _$UnifiedPropertyResponseFromJson(Map<String, dynamic> json) =>
    UnifiedPropertyResponse(
      properties:
          (json['properties'] as List<dynamic>)
              .map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
              .toList(),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      totalPages: (json['total_pages'] as num).toInt(),
      filtersApplied: json['filters_applied'] as Map<String, dynamic>,
      searchCenter:
          json['search_center'] == null
              ? null
              : SearchCenter.fromJson(json['search_center'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UnifiedPropertyResponseToJson(UnifiedPropertyResponse instance) =>
    <String, dynamic>{
      'properties': instance.properties.map((e) => e.toJson()).toList(),
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'total_pages': instance.totalPages,
      'filters_applied': instance.filtersApplied,
      'search_center': instance.searchCenter?.toJson(),
    };

SearchCenter _$SearchCenterFromJson(Map<String, dynamic> json) => SearchCenter(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$SearchCenterToJson(SearchCenter instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
