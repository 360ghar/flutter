import 'package:json_annotation/json_annotation.dart';

part 'property_model.g.dart';

@JsonSerializable()
class PropertyModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final String propertyType;
  final List<String> images;
  final String? tour360Url;
  final double latitude;
  final double longitude;
  final List<String> amenities;
  final bool isAvailable;
  final DateTime listedDate;
  final String agentId;
  final String agentName;
  final String agentPhone;
  final String agentEmail;
  final String agentImage;

  PropertyModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.propertyType,
    required this.images,
    this.tour360Url,
    required this.latitude,
    required this.longitude,
    required this.amenities,
    required this.isAvailable,
    required this.listedDate,
    required this.agentId,
    required this.agentName,
    required this.agentPhone,
    required this.agentEmail,
    required this.agentImage,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyModelToJson(this);

  String get formattedPrice {
    if (price >= 10000000) {
      return '₹${(price / 10000000).toStringAsFixed(1)} Cr';
    } else if (price >= 100000) {
      return '₹${(price / 100000).toStringAsFixed(1)} L';
    } else {
      return '₹${price.toStringAsFixed(0)}';
    }
  }

  String get fullAddress {
    return '$address, $city, $state $zipCode';
  }

  String get mainImage {
    return images.isNotEmpty ? images.first : '';
  }
} 