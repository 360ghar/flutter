// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_property_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnifiedPropertyResponse _$UnifiedPropertyResponseFromJson(
        Map<String, dynamic> json) =>
    UnifiedPropertyResponse(
      properties: (json['properties'] as List<dynamic>?)
              ?.map((e) => PropertyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      filtersApplied: json['filters_applied'] as Map<String, dynamic>? ?? {},
      searchCenter: (json['search_center'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          {},
    );

Map<String, dynamic> _$UnifiedPropertyResponseToJson(
        UnifiedPropertyResponse instance) =>
    <String, dynamic>{
      'properties': instance.properties,
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
      'total_pages': instance.totalPages,
      'filters_applied': instance.filtersApplied,
      'search_center': instance.searchCenter,
    };
