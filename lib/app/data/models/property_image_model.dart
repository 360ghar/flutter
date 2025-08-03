import 'package:json_annotation/json_annotation.dart';

part 'property_image_model.g.dart';

@JsonSerializable()
class PropertyImageModel {
  final int id;
  @JsonKey(name: 'property_id')
  final int propertyId;
  @JsonKey(name: 'image_url', defaultValue: 'https://via.placeholder.com/400x300?text=No+Image')
  final String imageUrl;
  final String? caption;
  @JsonKey(name: 'display_order', defaultValue: 0)
  final int displayOrder;
  @JsonKey(name: 'is_main_image', defaultValue: false)
  final bool isMainImage;

  PropertyImageModel({
    required this.id,
    required this.propertyId,
    required this.imageUrl,
    this.caption,
    this.displayOrder = 0,
    this.isMainImage = false,
  });

  factory PropertyImageModel.fromJson(Map<String, dynamic> json) => _$PropertyImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyImageModelToJson(this);
  
  // Helper methods
  bool get isValid => imageUrl.isNotEmpty && imageUrl != 'https://via.placeholder.com/400x300?text=No+Image';
  
  String get thumbnailUrl {
    // If using a CDN, can append thumbnail parameters
    if (imageUrl.contains('cloudinary.com') || imageUrl.contains('imgur.com')) {
      return '${imageUrl}?w=300&h=200&fit=crop';
    }
    return imageUrl;
  }
  
  String get fullSizeUrl {
    // If using a CDN, can append full size parameters
    if (imageUrl.contains('cloudinary.com') || imageUrl.contains('imgur.com')) {
      return '${imageUrl}?w=1200&h=800&fit=crop';
    }
    return imageUrl;
  }
}