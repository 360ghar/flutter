import 'package:json_annotation/json_annotation.dart';
import 'property_model.dart';

part 'filters_model.g.dart';

@JsonSerializable()
class FiltersModel {
  // Location search
  final double? lat;
  final double? lng;
  final int? radius;
  
  // Text search
  final String? q;
  
  // Core property filters
  @JsonKey(name: 'property_type')
  final List<PropertyType>? propertyType;
  final PropertyPurpose? purpose;
  
  // Price
  @JsonKey(name: 'price_min')
  final double? priceMin;
  @JsonKey(name: 'price_max')
  final double? priceMax;
  
  // Rooms
  @JsonKey(name: 'bedrooms_min')
  final int? bedroomsMin;
  @JsonKey(name: 'bedrooms_max')
  final int? bedroomsMax;
  @JsonKey(name: 'bathrooms_min')
  final int? bathroomsMin;
  @JsonKey(name: 'bathrooms_max')
  final int? bathroomsMax;
  
  // Area
  @JsonKey(name: 'area_min')
  final double? areaMin;
  @JsonKey(name: 'area_max')
  final double? areaMax;
  
  // Location metadata
  final String? city;
  final String? locality;
  final String? pincode;
  
  // Additional filters
  final List<String>? amenities;
  @JsonKey(name: 'parking_spaces_min')
  final int? parkingSpacesMin;
  @JsonKey(name: 'floor_number_min')
  final int? floorNumberMin;
  @JsonKey(name: 'floor_number_max')
  final int? floorNumberMax;
  @JsonKey(name: 'age_max')
  final int? ageMax;
  
  // Short-stay filters
  @JsonKey(name: 'check_in')
  final String? checkIn;
  @JsonKey(name: 'check_out')
  final String? checkOut;
  final int? guests;
  
  // Sorting
  @JsonKey(name: 'sort_by')
  final String? sortBy;

  FiltersModel({
    this.lat,
    this.lng,
    this.radius = 5,
    this.q,
    this.propertyType,
    this.purpose,
    this.priceMin,
    this.priceMax,
    this.bedroomsMin,
    this.bedroomsMax,
    this.bathroomsMin,
    this.bathroomsMax,
    this.areaMin,
    this.areaMax,
    this.city,
    this.locality,
    this.pincode,
    this.amenities,
    this.parkingSpacesMin,
    this.floorNumberMin,
    this.floorNumberMax,
    this.ageMax,
    this.checkIn,
    this.checkOut,
    this.guests,
    this.sortBy = 'distance',
  });

  factory FiltersModel.fromJson(Map<String, dynamic> json) => 
      _$FiltersModelFromJson(json);

  Map<String, dynamic> toJson() => _$FiltersModelToJson(this);

  // Convert to query parameters for API calls
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    // Add non-null values
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    if (radius != null) params['radius'] = radius.toString();
    if (q != null && q!.isNotEmpty) params['q'] = q;
    
    // Property types as array
    if (propertyType != null && propertyType!.isNotEmpty) {
      for (final type in propertyType!) {
        if (!params.containsKey('property_type')) {
          params['property_type'] = <String>[];
        }
        (params['property_type'] as List<String>).add(_propertyTypeToString(type));
      }
    }
    
    if (purpose != null) params['purpose'] = _purposeToString(purpose!);
    
    if (priceMin != null) params['price_min'] = priceMin.toString();
    if (priceMax != null) params['price_max'] = priceMax.toString();
    if (bedroomsMin != null) params['bedrooms_min'] = bedroomsMin.toString();
    if (bedroomsMax != null) params['bedrooms_max'] = bedroomsMax.toString();
    if (bathroomsMin != null) params['bathrooms_min'] = bathroomsMin.toString();
    if (bathroomsMax != null) params['bathrooms_max'] = bathroomsMax.toString();
    if (areaMin != null) params['area_min'] = areaMin.toString();
    if (areaMax != null) params['area_max'] = areaMax.toString();
    
    if (city != null && city!.isNotEmpty) params['city'] = city;
    if (locality != null && locality!.isNotEmpty) params['locality'] = locality;
    if (pincode != null && pincode!.isNotEmpty) params['pincode'] = pincode;
    
    // Amenities as array
    if (amenities != null && amenities!.isNotEmpty) {
      params['amenities'] = amenities;
    }
    
    if (parkingSpacesMin != null) params['parking_spaces_min'] = parkingSpacesMin.toString();
    if (floorNumberMin != null) params['floor_number_min'] = floorNumberMin.toString();
    if (floorNumberMax != null) params['floor_number_max'] = floorNumberMax.toString();
    if (ageMax != null) params['age_max'] = ageMax.toString();
    
    if (checkIn != null && checkIn!.isNotEmpty) params['check_in'] = checkIn;
    if (checkOut != null && checkOut!.isNotEmpty) params['check_out'] = checkOut;
    if (guests != null) params['guests'] = guests.toString();
    
    if (sortBy != null) params['sort_by'] = sortBy;
    
    return params;
  }

  String _propertyTypeToString(PropertyType type) {
    switch (type) {
      case PropertyType.house:
        return 'house';
      case PropertyType.apartment:
        return 'apartment';
      case PropertyType.builderFloor:
        return 'builder_floor';
      case PropertyType.room:
        return 'room';
    }
  }

  String _purposeToString(PropertyPurpose purpose) {
    switch (purpose) {
      case PropertyPurpose.buy:
        return 'buy';
      case PropertyPurpose.rent:
        return 'rent';
      case PropertyPurpose.shortStay:
        return 'short_stay';
    }
  }

  // Create copy with updated values
  FiltersModel copyWith({
    double? lat,
    double? lng,
    int? radius,
    String? q,
    List<PropertyType>? propertyType,
    PropertyPurpose? purpose,
    double? priceMin,
    double? priceMax,
    int? bedroomsMin,
    int? bedroomsMax,
    int? bathroomsMin,
    int? bathroomsMax,
    double? areaMin,
    double? areaMax,
    String? city,
    String? locality,
    String? pincode,
    List<String>? amenities,
    int? parkingSpacesMin,
    int? floorNumberMin,
    int? floorNumberMax,
    int? ageMax,
    String? checkIn,
    String? checkOut,
    int? guests,
    String? sortBy,
  }) {
    return FiltersModel(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radius: radius ?? this.radius,
      q: q ?? this.q,
      propertyType: propertyType ?? this.propertyType,
      purpose: purpose ?? this.purpose,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      bedroomsMin: bedroomsMin ?? this.bedroomsMin,
      bedroomsMax: bedroomsMax ?? this.bedroomsMax,
      bathroomsMin: bathroomsMin ?? this.bathroomsMin,
      bathroomsMax: bathroomsMax ?? this.bathroomsMax,
      areaMin: areaMin ?? this.areaMin,
      areaMax: areaMax ?? this.areaMax,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      pincode: pincode ?? this.pincode,
      amenities: amenities ?? this.amenities,
      parkingSpacesMin: parkingSpacesMin ?? this.parkingSpacesMin,
      floorNumberMin: floorNumberMin ?? this.floorNumberMin,
      floorNumberMax: floorNumberMax ?? this.floorNumberMax,
      ageMax: ageMax ?? this.ageMax,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      guests: guests ?? this.guests,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  // Reset all filters
  FiltersModel reset() {
    return FiltersModel();
  }

  // Check if filters are applied
  bool get hasActiveFilters {
    return q != null ||
           propertyType != null ||
           purpose != null ||
           priceMin != null ||
           priceMax != null ||
           bedroomsMin != null ||
           bedroomsMax != null ||
           bathroomsMin != null ||
           bathroomsMax != null ||
           areaMin != null ||
           areaMax != null ||
           city != null ||
           locality != null ||
           pincode != null ||
           amenities != null ||
           parkingSpacesMin != null ||
           floorNumberMin != null ||
           floorNumberMax != null ||
           ageMax != null ||
           checkIn != null ||
           checkOut != null ||
           guests != null;
  }

  // Generate cache key for this filter combination
  String get cacheKey {
    final params = toQueryParams();
    final list = params.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${e.value}')
        .toList()
      ..sort();
    return list.join('&');
  }
}