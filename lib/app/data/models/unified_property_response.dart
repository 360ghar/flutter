import 'package:json_annotation/json_annotation.dart';
import 'property_card_model.dart';

part 'unified_property_response.g.dart';

@JsonSerializable()
class UnifiedPropertyResponse {
  @JsonKey(defaultValue: <PropertyCardModel>[])
  final List<PropertyCardModel> properties;
  @JsonKey(defaultValue: 0)
  final int total;
  @JsonKey(defaultValue: 1)
  final int page;
  @JsonKey(defaultValue: 20)
  final int limit;
  @JsonKey(name: 'total_pages', defaultValue: 1)
  final int totalPages;
  @JsonKey(name: 'filters_applied', defaultValue: <String, dynamic>{})
  final Map<String, dynamic> filtersApplied;
  @JsonKey(name: 'search_center', defaultValue: <String, double>{})
  final Map<String, double> searchCenter;

  UnifiedPropertyResponse({
    required this.properties,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.filtersApplied,
    required this.searchCenter,
  });

  factory UnifiedPropertyResponse.fromJson(Map<String, dynamic> json) => _$UnifiedPropertyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedPropertyResponseToJson(this);

  // Convenience getters
  bool get hasMore => page < totalPages;
  bool get isEmpty => properties.isEmpty;
  bool get isNotEmpty => properties.isNotEmpty;
  
  int get currentPageStart => (page - 1) * limit + 1;
  int get currentPageEnd => (page * limit).clamp(0, total);
  
  String get resultsSummary {
    if (isEmpty) return 'No properties found';
    if (total == 1) return '1 property found';
    return '$total properties found';
  }
  
  String get pageInfo {
    if (isEmpty) return '';
    return 'Page $page of $totalPages';
  }
  
  // Filter information getters
  List<String> get appliedFiltersList {
    List<String> filters = [];
    
    filtersApplied.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        switch (key) {
          case 'property_type':
            if (value is List && (value as List).isNotEmpty) {
              filters.add('Property Type: ${(value as List).join(', ')}');
            }
            break;
          case 'purpose':
            filters.add('Purpose: ${value.toString()}');
            break;
          case 'price_min':
          case 'price_max':
            // Handle price range separately
            break;
          case 'bedrooms_min':
          case 'bedrooms_max':
            // Handle bedroom range separately
            break;
          default:
            if (value is bool && value) {
              filters.add(key.replaceAll('_', ' ').toUpperCase());
            } else if (value is! bool) {
              filters.add('$key: $value');
            }
        }
      }
    });
    
    // Handle price range
    final priceMin = filtersApplied['price_min'];
    final priceMax = filtersApplied['price_max'];
    if (priceMin != null && priceMax != null) {
      filters.add('Price: ₹${_formatPrice(priceMin)} - ₹${_formatPrice(priceMax)}');
    } else if (priceMin != null) {
      filters.add('Min Price: ₹${_formatPrice(priceMin)}');
    } else if (priceMax != null) {
      filters.add('Max Price: ₹${_formatPrice(priceMax)}');
    }
    
    // Handle bedroom range
    final bedroomsMin = filtersApplied['bedrooms_min'];
    final bedroomsMax = filtersApplied['bedrooms_max'];
    if (bedroomsMin != null && bedroomsMax != null && bedroomsMin == bedroomsMax) {
      filters.add('${bedroomsMin} Bedrooms');
    } else if (bedroomsMin != null && bedroomsMax != null) {
      filters.add('${bedroomsMin}-${bedroomsMax} Bedrooms');
    } else if (bedroomsMin != null) {
      filters.add('${bedroomsMin}+ Bedrooms');
    }
    
    return filters;
  }
  
  String _formatPrice(dynamic price) {
    final priceValue = (price as num).toDouble();
    if (priceValue >= 10000000) {
      return '${(priceValue / 10000000).toStringAsFixed(1)} Cr';
    } else if (priceValue >= 100000) {
      return '${(priceValue / 100000).toStringAsFixed(1)} L';
    } else {
      return priceValue.toStringAsFixed(0);
    }
  }
  
  // Search center information
  double? get searchLatitude => searchCenter['latitude'];
  double? get searchLongitude => searchCenter['longitude'];
  
  bool get hasSearchCenter => searchLatitude != null && searchLongitude != null;
}