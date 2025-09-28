import 'package:ghar360/core/data/models/property_image_model.dart';
import 'package:json_annotation/json_annotation.dart';

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
  @JsonValue('villa')
  villa,
  @JsonValue('plot')
  plot,
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
  @JsonKey(defaultValue: -1)
  final int id;
  @JsonKey(defaultValue: 'Unknown')
  final String title;
  final String? icon;
  final String? category;

  const PropertyAmenity({required this.id, required this.title, this.icon, this.category});

  factory PropertyAmenity.fromJson(Map<String, dynamic> json) => _$PropertyAmenityFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyAmenityToJson(this);
}

@JsonSerializable(explicitToJson: true, checked: true)
class PropertyModel {
  @JsonKey(defaultValue: -1)
  final int id;
  @JsonKey(defaultValue: 'Unknown Property')
  final String title;
  final String? description;
  @JsonKey(name: 'property_type', unknownEnumValue: PropertyType.house)
  final PropertyType? propertyType;
  @JsonKey(unknownEnumValue: PropertyPurpose.buy)
  final PropertyPurpose? purpose;
  @JsonKey(name: 'base_price', defaultValue: 0.0)
  final double basePrice;
  @JsonKey(unknownEnumValue: PropertyStatus.available)
  final PropertyStatus? status;

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
  // Backend may send either is_active or is_available
  @JsonKey(name: 'is_active', defaultValue: true)
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
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  // Relationships
  final List<PropertyImageModel>? images;

  // Client-side calculated fields
  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  // Swipe-related fields
  @JsonKey(name: 'liked', defaultValue: false)
  final bool liked;

  // User visit scheduling fields (per-property, user-scoped)
  @JsonKey(name: 'user_has_scheduled_visit', defaultValue: false)
  final bool userHasScheduledVisit;
  @JsonKey(name: 'user_scheduled_visit_count', defaultValue: 0)
  final int userScheduledVisitCount;
  @JsonKey(name: 'user_next_visit_date')
  final DateTime? userNextVisitDate;

  const PropertyModel({
    required this.id,
    required this.title,
    this.description,
    this.propertyType,
    this.purpose,
    required this.basePrice,
    this.status,
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
    this.createdAt,
    this.updatedAt,
    this.images,
    this.distanceKm,
    this.liked = false,
    this.userHasScheduledVisit = false,
    this.userScheduledVisitCount = 0,
    this.userNextVisitDate,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Normalize backend variations without breaking generated parsing
    final normalized = Map<String, dynamic>.from(json);
    if (!normalized.containsKey('is_active') && normalized.containsKey('is_available')) {
      normalized['is_active'] = normalized['is_available'];
    }
    // Normalize date string for user_next_visit_date into ISO if needed
    final nextVisit = normalized['user_next_visit_date'];
    if (nextVisit is String && nextVisit.isNotEmpty) {
      // Let generated code parse ISO-8601 directly; no-op here
    }
    return _$PropertyModelFromJson(normalized);
  }

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
      default:
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
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.plot:
        return 'Plot';
      default:
        return 'Property';
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
      default:
        return 'For Sale';
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
      default:
        return 'Available';
    }
  }

  String get addressDisplay {
    if (fullAddress?.isNotEmpty == true) return fullAddress!;
    if (locality?.isNotEmpty == true && city?.isNotEmpty == true) {
      return '$locality, $city';
    }
    return city ?? 'Unknown Location';
  }

  // Short address that never exposes full_address. Prefer locality/subLocality + city.
  String get shortAddressDisplay {
    final parts = <String>[];
    if (locality != null && locality!.isNotEmpty) parts.add(locality!);
    if (subLocality != null && subLocality!.isNotEmpty) parts.add(subLocality!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (parts.isEmpty) return city ?? 'Unknown Location';
    return parts.join(', ');
  }

  String get mainImage {
    if (mainImageUrl?.isNotEmpty == true) return mainImageUrl!;
    final firstImageUrl = (images != null && images!.isNotEmpty) ? images!.first.imageUrl : null;
    return (firstImageUrl?.isNotEmpty == true)
        ? firstImageUrl!
        : 'https://via.placeholder.com/400x300?text=No+Image';
  }

  // Also make the imageUrls getter safer
  List<String> get imageUrls {
    final urls = <String>[];
    if (mainImageUrl?.isNotEmpty == true) urls.add(mainImageUrl!);
    for (final img in images ?? const <PropertyImageModel>[]) {
      if (img.imageUrl.isNotEmpty) urls.add(img.imageUrl);
    }
    return urls.toSet().toList();
  }

  // Images suitable for gallery (filter out known non-image URLs like 360 tour links)
  List<String> get galleryImageUrls {
    final candidates = <String>[];
    // Prefer sorted images by display order when available
    final sortedImages = [...(images ?? [])]
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    for (final img in sortedImages) {
      final url = img.imageUrl;
      if (_looksLikeImageUrl(url)) candidates.add(url);
    }
    // Include main image if list still empty
    if (candidates.isEmpty && mainImageUrl?.isNotEmpty == true) {
      candidates.add(mainImageUrl!);
    }
    // Final fallback: at least one placeholder handled by UI if still empty
    return candidates;
  }

  bool _looksLikeImageUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('kuula.co/share')) return false;
    final path = Uri.tryParse(lower)?.path ?? lower;
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif');
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

  // User visit helpers
  bool get hasUserScheduled => userHasScheduledVisit || userNextVisitDate != null;

  // Parsed availability date helper
  DateTime? get availableFromDate {
    final v = availableFrom;
    if (v == null || v.isEmpty) return null;
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
}
