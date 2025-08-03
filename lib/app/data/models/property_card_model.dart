import 'package:json_annotation/json_annotation.dart';
import 'property_model.dart';

part 'property_card_model.g.dart';

@JsonSerializable()
class PropertyCardModel {
  final int id;
  @JsonKey(defaultValue: 'Unknown Property')
  final String title;
  @JsonKey(name: 'property_type')
  final PropertyType propertyType;
  final PropertyPurpose purpose;
  @JsonKey(name: 'base_price', defaultValue: 0.0)
  final double basePrice;
  @JsonKey(name: 'area_sqft')
  final double? areaSqft;
  final int? bedrooms;
  final int? bathrooms;
  @JsonKey(name: 'main_image_url')
  final String? mainImageUrl;
  @JsonKey(name: 'virtual_tour_url')
  final String? virtualTourUrl;
  final String? city;
  final String? state;
  final String? locality;
  final String? pincode;
  @JsonKey(name: 'full_address')
  final String? fullAddress;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'like_count', defaultValue: 0)
  final int likeCount;

  PropertyCardModel({
    required this.id,
    required this.title,
    required this.propertyType,
    required this.purpose,
    required this.basePrice,
    this.areaSqft,
    this.bedrooms,
    this.bathrooms,
    this.mainImageUrl,
    this.virtualTourUrl,
    this.city,
    this.state,
    this.locality,
    this.pincode,
    this.fullAddress,
    this.distanceKm,
    required this.likeCount,
  });

  factory PropertyCardModel.fromJson(Map<String, dynamic> json) => _$PropertyCardModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyCardModelToJson(this);

  // Convenience getters
  String get formattedPrice {
    if (basePrice >= 10000000) {
      return '₹${(basePrice / 10000000).toStringAsFixed(1)} Cr';
    } else if (basePrice >= 100000) {
      return '₹${(basePrice / 100000).toStringAsFixed(1)} L';
    } else {
      return '₹${basePrice.toStringAsFixed(0)}';
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

  String get addressDisplay {
    if (fullAddress?.isNotEmpty == true) return fullAddress!;
    if (locality?.isNotEmpty == true && city?.isNotEmpty == true) return '$locality, $city';
    return city ?? 'Unknown Location';
  }

  String get mainImage {
    if (mainImageUrl?.isNotEmpty == true) {
      // Validate URL format
      try {
        final uri = Uri.parse(mainImageUrl!);
        if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority) {
          return mainImageUrl!;
        }
      } catch (e) {
        print('⚠️ Invalid image URL for property $id: $mainImageUrl');
      }
    }
    // Return empty string to trigger error widget
    return '';
  }
  
  // Get a fallback description for error widgets
  String get imageDescription {
    return '${propertyTypeString} in ${city ?? 'Unknown Location'}';
  }
  
  // Get initials for fallback display
  String get titleInitials {
    final words = title.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return 'P';
  }

  String get bedroomBathroomText {
    if (bedrooms != null && bathrooms != null) {
      return '${bedrooms}BHK, ${bathrooms} Bath';
    } else if (bedrooms != null) {
      return '${bedrooms}BHK';
    } else if (bathrooms != null) {
      return '${bathrooms} Bath';
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

  bool get hasVirtualTour => virtualTourUrl?.isNotEmpty == true;
}