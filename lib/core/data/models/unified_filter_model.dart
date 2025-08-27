import 'package:json_annotation/json_annotation.dart';
import 'api_response_models.dart';

part 'unified_filter_model.g.dart';

@JsonSerializable()
class UnifiedFilterModel {
  // Location-based filters
  // REMOVED: latitude and longitude are now handled by PageStateModel.selectedLocation
  @JsonKey(name: 'radius_km')
  final double? radiusKm;

  // Core property filters
  final String? purpose; // buy, rent, short_stay
  @JsonKey(name: 'property_type')
  final List<String>? propertyType;
  @JsonKey(name: 'price_min')
  final double? priceMin;
  @JsonKey(name: 'price_max')
  final double? priceMax;
  @JsonKey(name: 'bedrooms_min')
  final int? bedroomsMin;
  @JsonKey(name: 'bedrooms_max')
  final int? bedroomsMax;
  @JsonKey(name: 'bathrooms_min')
  final int? bathroomsMin;
  @JsonKey(name: 'bathrooms_max')
  final int? bathroomsMax;
  @JsonKey(name: 'area_min')
  final double? areaMin;
  @JsonKey(name: 'area_max')
  final double? areaMax;

  // Detailed property filters
  @JsonKey(name: 'parking_spaces_min')
  final int? parkingSpacesMin;
  @JsonKey(name: 'floor_number_min')
  final int? floorNumberMin;
  @JsonKey(name: 'floor_number_max')
  final int? floorNumberMax;
  @JsonKey(name: 'age_max')
  final int? ageMax;
  final List<String>? amenities;
  final List<String>? features;

  // Availability & sorting
  @JsonKey(name: 'available_from')
  final DateTime? availableFrom;
  @JsonKey(name: 'check_in_date')
  final DateTime? checkInDate;
  @JsonKey(name: 'check_out_date')
  final DateTime? checkOutDate;
  final int? guests;
  @JsonKey(name: 'sort_by')
  final SortBy? sortBy;
  
  // Search query for text-based search
  @JsonKey(name: 'search_query')
  final String? searchQuery;
  @JsonKey(name: 'include_unavailable')
  final bool? includeUnavailable;

  // Additional filters for favorites
  @JsonKey(name: 'property_ids')
  final List<int>? propertyIds;

  UnifiedFilterModel({
    this.radiusKm,
    this.purpose,
    this.propertyType,
    this.priceMin,
    this.priceMax,
    this.bedroomsMin,
    this.bedroomsMax,
    this.bathroomsMin,
    this.bathroomsMax,
    this.areaMin,
    this.areaMax,
    this.parkingSpacesMin,
    this.floorNumberMin,
    this.floorNumberMax,
    this.ageMax,
    this.amenities,
    this.features,
    this.availableFrom,
    this.checkInDate,
    this.checkOutDate,
    this.guests,
    this.sortBy,
    this.searchQuery,
    this.includeUnavailable,
    this.propertyIds,
  });

  factory UnifiedFilterModel.initial() {
    return UnifiedFilterModel(
      radiusKm: 10.0,
      purpose: null,
      sortBy: null,
      includeUnavailable: false,
      propertyType: [],
      amenities: [],
      features: [],
    );
  }

  factory UnifiedFilterModel.fromJson(Map<String, dynamic> json) =>
      _$UnifiedFilterModelFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$UnifiedFilterModelToJson(this);
    
    // Handle DateTime serialization properly for API
    if (availableFrom != null) {
      json['available_from'] = availableFrom!.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    }
    if (checkInDate != null) {
      json['check_in_date'] = checkInDate!.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    }
    if (checkOutDate != null) {
      json['check_out_date'] = checkOutDate!.toIso8601String().split('T')[0]; // YYYY-MM-DD format
    }
    
    // Ensure numeric values are within valid ranges
    if (radiusKm != null && (radiusKm! <= 0 || radiusKm! > 1000)) {
      json.remove('radius_km'); // Remove invalid radius
    }
    if (priceMin != null && priceMin! < 0) {
      json.remove('price_min'); // Remove invalid price
    }
    if (priceMax != null && priceMax! < 0) {
      json.remove('price_max'); // Remove invalid price
    }
    if (bedroomsMin != null && bedroomsMin! < 0) {
      json.remove('bedrooms_min'); // Remove invalid bedrooms
    }
    if (bedroomsMax != null && bedroomsMax! < 0) {
      json.remove('bedrooms_max'); // Remove invalid bedrooms
    }
    if (bathroomsMin != null && bathroomsMin! < 0) {
      json.remove('bathrooms_min'); // Remove invalid bathrooms
    }
    if (bathroomsMax != null && bathroomsMax! < 0) {
      json.remove('bathrooms_max'); // Remove invalid bathrooms
    }
    if (areaMin != null && areaMin! < 0) {
      json.remove('area_min'); // Remove invalid area
    }
    if (areaMax != null && areaMax! < 0) {
      json.remove('area_max'); // Remove invalid area
    }
    if (guests != null && guests! <= 0) {
      json.remove('guests'); // Remove invalid guest count
    }
    
    // Remove null values and empty lists for cleaner API requests
    json.removeWhere((key, value) => 
        value == null || 
        (value is List && value.isEmpty) ||
        (value is String && value.trim().isEmpty));
    
    return json;
  }

  UnifiedFilterModel copyWith({
    double? radiusKm,
    String? purpose,
    List<String>? propertyType,
    double? priceMin,
    double? priceMax,
    int? bedroomsMin,
    int? bedroomsMax,
    int? bathroomsMin,
    int? bathroomsMax,
    double? areaMin,
    double? areaMax,
    int? parkingSpacesMin,
    int? floorNumberMin,
    int? floorNumberMax,
    int? ageMax,
    List<String>? amenities,
    List<String>? features,
    DateTime? availableFrom,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guests,
    SortBy? sortBy,
    String? searchQuery,
    bool? includeUnavailable,
    List<int>? propertyIds,
  }) {
    return UnifiedFilterModel(
      radiusKm: radiusKm ?? this.radiusKm,
      purpose: purpose ?? this.purpose,
      propertyType: propertyType ?? this.propertyType,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      bedroomsMin: bedroomsMin ?? this.bedroomsMin,
      bedroomsMax: bedroomsMax ?? this.bedroomsMax,
      bathroomsMin: bathroomsMin ?? this.bathroomsMin,
      bathroomsMax: bathroomsMax ?? this.bathroomsMax,
      areaMin: areaMin ?? this.areaMin,
      areaMax: areaMax ?? this.areaMax,
      parkingSpacesMin: parkingSpacesMin ?? this.parkingSpacesMin,
      floorNumberMin: floorNumberMin ?? this.floorNumberMin,
      floorNumberMax: floorNumberMax ?? this.floorNumberMax,
      ageMax: ageMax ?? this.ageMax,
      amenities: amenities ?? this.amenities,
      features: features ?? this.features,
      availableFrom: availableFrom ?? this.availableFrom,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      guests: guests ?? this.guests,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      includeUnavailable: includeUnavailable ?? this.includeUnavailable,
      propertyIds: propertyIds ?? this.propertyIds,
    );
  }

  // Helper method to count active filters
  int get activeFilterCount {
    int count = 0;
    if (priceMin != null || priceMax != null) count++;
    if (bedroomsMin != null || bedroomsMax != null) count++;
    if (bathroomsMin != null || bathroomsMax != null) count++;
    if (areaMin != null || areaMax != null) count++;
    if (propertyType != null && propertyType!.isNotEmpty) count++;
    if (amenities != null && amenities!.isNotEmpty) count++;
    if (features != null && features!.isNotEmpty) count++;
    if (parkingSpacesMin != null) count++;
    if (floorNumberMin != null || floorNumberMax != null) count++;
    if (ageMax != null) count++;
    return count;
  }
}

// Location data model for location selection
class LocationData {
  final String name;
  final double latitude;
  final double longitude;

  LocationData({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}