import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';
import 'property_image_model.dart';

part 'property_model.g.dart';

// Enums matching backend schema
enum PropertyType {
  @JsonValue('house')
  house,
  @JsonValue('apartment')
  apartment,
  @JsonValue('builder_floor')
  builderFloor,
  @JsonValue('room')
  room,
}

enum PropertyPurpose {
  @JsonValue('buy')
  buy,
  @JsonValue('rent')
  rent,
  @JsonValue('short_stay')
  shortStay,
}

enum PropertyStatus {
  @JsonValue('available')
  available,
  @JsonValue('sold')
  sold,
  @JsonValue('rented')
  rented,
  @JsonValue('under_offer')
  underOffer,
  @JsonValue('maintenance')
  maintenance,
}

@JsonSerializable()
class PropertyAmenity {
  final int id;
  final String title;
  final String? icon;
  final String? category;

  PropertyAmenity({
    required this.id,
    required this.title,
    this.icon,
    this.category,
  });

  factory PropertyAmenity.fromJson(Map<String, dynamic> json) => _$PropertyAmenityFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyAmenityToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PropertyModel {
  final int id;
  @JsonKey(defaultValue: 'Unknown Property')
  final String title;
  final String? description;
  @JsonKey(name: 'property_type')
  final PropertyType propertyType;
  final PropertyPurpose purpose;
  @JsonKey(name: 'base_price', defaultValue: 0.0)
  final double basePrice;
  final PropertyStatus status;
  
  // Location fields
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  @JsonKey(defaultValue: 'India')
  final String country;
  final String? pincode;
  final String? locality;
  @JsonKey(name: 'sub_locality')
  final String? subLocality;
  final String? landmark;
  @JsonKey(name: 'full_address')
  final String? fullAddress;
  @JsonKey(name: 'area_type')
  final String? areaType;
  
  // Property details
  @JsonKey(name: 'area_sqft')
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  final int? balconies;
  @JsonKey(name: 'parking_spaces')
  final int? parkingSpaces;
  
  // Pricing
  @JsonKey(name: 'price_per_sqft')
  final double? pricePerSqft;
  @JsonKey(name: 'monthly_rent')
  final double? monthlyRent;
  @JsonKey(name: 'daily_rate')
  final double? dailyRate;
  @JsonKey(name: 'security_deposit')
  final double? securityDeposit;
  @JsonKey(name: 'maintenance_charges')
  final double? maintenanceCharges;
  
  // Building details
  @JsonKey(name: 'floor_number')
  final int? floorNumber;
  @JsonKey(name: 'total_floors')
  final int? totalFloors;
  @JsonKey(name: 'age_of_property')
  final int? ageOfProperty;
  
  // Accommodation details
  @JsonKey(name: 'max_occupancy')
  final int? maxOccupancy;
  @JsonKey(name: 'minimum_stay_days')
  final int? minimumStayDays;
  
  // Features and amenities
  final List<PropertyAmenity>? amenities;
  final List<String>? features;
  @JsonKey(name: 'main_image_url')
  final String? mainImageUrl;
  @JsonKey(name: 'virtual_tour_url')
  final String? virtualTourUrl;
  
  // Availability
  @JsonKey(name: 'is_available', defaultValue: true)
  final bool isAvailable;
  @JsonKey(name: 'available_from')
  final String? availableFrom;
  @JsonKey(name: 'calendar_data')
  final Map<String, dynamic>? calendarData;
  
  // SEO and metadata
  final List<String>? tags;
  @JsonKey(name: 'owner_name')
  final String? ownerName;
  @JsonKey(name: 'owner_contact')
  final String? ownerContact;
  @JsonKey(name: 'builder_name')
  final String? builderName;
  
  // Performance metrics
  @JsonKey(name: 'view_count', defaultValue: 0)
  final int viewCount;
  @JsonKey(name: 'like_count', defaultValue: 0)
  final int likeCount;
  @JsonKey(name: 'interest_count', defaultValue: 0)
  final int interestCount;
  
  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  
  // Relationships
  final List<PropertyImageModel>? images;
  
  // Client-side calculated fields
  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  // Swipe-related fields
  @JsonKey(name: 'liked', defaultValue: false)
  bool liked;

  PropertyModel({
    required this.id,
    required this.title,
    this.description,
    required this.propertyType,
    required this.purpose,
    required this.basePrice,
    required this.status,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country = 'India',
    this.pincode,
    this.locality,
    this.subLocality,
    this.landmark,
    this.fullAddress,
    this.areaType,
    this.areaSqft,
    this.bedrooms,
    this.bathrooms,
    this.balconies,
    this.parkingSpaces,
    this.pricePerSqft,
    this.monthlyRent,
    this.dailyRate,
    this.securityDeposit,
    this.maintenanceCharges,
    this.floorNumber,
    this.totalFloors,
    this.ageOfProperty,
    this.maxOccupancy,
    this.minimumStayDays,
    this.amenities,
    this.features,
    this.mainImageUrl,
    this.virtualTourUrl,
    required this.isAvailable,
    this.availableFrom,
    this.calendarData,
    this.tags,
    this.ownerName,
    this.ownerContact,
    this.builderName,
    required this.viewCount,
    required this.likeCount,
    required this.interestCount,
    required this.createdAt,
    this.updatedAt,
    this.images,
    this.distanceKm,
    this.liked = false,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) => _$PropertyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyModelToJson(this);

  String get formattedPrice {
    final price = getEffectivePrice();
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(1)} Cr';
    } else if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(1)} L';
    } else {
      return '₹${price.toStringAsFixed(0)}';
    }
  }

  double getEffectivePrice() {
    switch (purpose) {
      case PropertyPurpose.rent:
        return monthlyRent ?? basePrice;
      case PropertyPurpose.shortStay:
        return dailyRate ?? basePrice;
      case PropertyPurpose.buy:
        return basePrice;
    }
  }
  
  String get propertyTypeString {
    switch (propertyType) {
      case PropertyType.house:
        return 'House';
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.builderFloor:
        return 'Builder Floor';
      case PropertyType.room:
        return 'Room';
    }
  }
  
  String get purposeString {
    switch (purpose) {
      case PropertyPurpose.buy:
        return 'Buy';
      case PropertyPurpose.rent:
        return 'Rent';
      case PropertyPurpose.shortStay:
        return 'Short Stay';
    }
  }
  
  String get statusString {
    switch (status) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.sold:
        return 'Sold';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.underOffer:
        return 'Under Offer';
      case PropertyStatus.maintenance:
        return 'Maintenance';
    }
  }

  String get addressDisplay {
    if (fullAddress?.isNotEmpty == true) return fullAddress!;
    if (locality?.isNotEmpty == true && city?.isNotEmpty == true) return '$locality, $city';
    return city ?? 'Unknown Location';
  }

  String get mainImage {
    if (mainImageUrl?.isNotEmpty == true) {
      return mainImageUrl!;
    }
    if (images?.isNotEmpty == true) {
      return images!.first.imageUrl;
    }
    return 'https://via.placeholder.com/400x300?text=No+Image';
  }

  List<String> get imageUrls {
    if (images?.isNotEmpty == true) {
      return images!.map((e) => e.imageUrl).toList();
    }
    return mainImageUrl != null ? [mainImageUrl!] : [];
  }

  // Location convenience methods
  bool get hasLocation => latitude != null && longitude != null;
  
  // Amenities convenience methods
  bool get hasAmenities => amenities?.isNotEmpty == true;
  List<String> get amenitiesList => amenities?.map((a) => a.title).toList() ?? [];
  List<PropertyAmenity> get amenitiesData => amenities ?? [];
  
  // Virtual tour convenience methods
  bool get hasVirtualTour => virtualTourUrl?.isNotEmpty == true;
  
  // Agent/Owner convenience methods
  bool get hasOwner => ownerName?.isNotEmpty == true;
  String get ownerDisplayName => ownerName ?? 'Property Owner';
  bool get hasOwnerContact => ownerContact?.isNotEmpty == true;
  
  // Property details convenience methods
  String get bedroomBathroomText {
    if (bedrooms != null && bathrooms != null) {
      return '${bedrooms}BHK, $bathrooms Bath';
    } else if (bedrooms != null) {
      return '${bedrooms}BHK';
    } else if (bathrooms != null) {
      return '$bathrooms Bath';
    }
    return '';
  }

  String get areaText {
    if (areaSqft != null) {
      return '${areaSqft!.toStringAsFixed(0)} sq ft';
    }
    return '';
  }

  String get distanceText {
    if (distanceKm != null) {
      if (distanceKm! < 1) {
        return '${(distanceKm! * 1000).toStringAsFixed(0)}m away';
      } else {
        return '${distanceKm!.toStringAsFixed(1)}km away';
      }
    }
    return '';
  }

  // Get a fallback description for error widgets
  String get imageDescription {
    return '$propertyTypeString in ${city ?? 'Unknown Location'}';
  }

  // Get initials for fallback display
  String get titleInitials {
    final words = title.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      final String first = words[0];
      return first.isNotEmpty ? first.substring(0, 1).toUpperCase() : 'P';
    }
    return 'P';
  }

  // Floor information
  String get floorText {
    if (floorNumber != null && totalFloors != null) {
      return 'Floor $floorNumber/$totalFloors';
    } else if (floorNumber != null) {
      return 'Floor $floorNumber';
    }
    return '';
  }

  // Age information
  String get ageText {
    if (ageOfProperty != null) {
      if (ageOfProperty! == 0) {
        return 'New Construction';
      } else if (ageOfProperty! == 1) {
        return '1 year old';
      } else {
        return '$ageOfProperty years old';
      }
    }
    return '';
  }

  // Google Maps marker ID for this property
  String get markerId => 'property_${id}';

  // LatLng for this property
  LatLng? get latLng {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }
}