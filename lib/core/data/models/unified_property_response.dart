import 'package:json_annotation/json_annotation.dart';
import 'property_model.dart';

part 'unified_property_response.g.dart';

@JsonSerializable(explicitToJson: true)
class UnifiedPropertyResponse {
  final List<PropertyModel> properties;
  final int total;
  final int page;
  final int limit;
  @JsonKey(name: 'total_pages')
  final int totalPages;
  @JsonKey(name: 'filters_applied')
  final Map<String, dynamic> filtersApplied;
  @JsonKey(name: 'search_center')
  final SearchCenter? searchCenter;

  UnifiedPropertyResponse({
    required this.properties,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.filtersApplied,
    this.searchCenter,
  });

  factory UnifiedPropertyResponse.fromJson(Map<String, dynamic> json) => 
      _$UnifiedPropertyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedPropertyResponseToJson(this);

  bool get hasMore => page < totalPages;
  bool get isEmpty => properties.isEmpty;
  int get currentItemCount => (page - 1) * limit + properties.length;
}

@JsonSerializable(explicitToJson: true)
class SearchCenter {
  final double latitude;
  final double longitude;

  SearchCenter({
    required this.latitude,
    required this.longitude,
  });

  factory SearchCenter.fromJson(Map<String, dynamic> json) => 
      _$SearchCenterFromJson(json);

  Map<String, dynamic> toJson() => _$SearchCenterToJson(this);
}