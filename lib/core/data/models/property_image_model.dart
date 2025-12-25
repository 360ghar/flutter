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
  // Backend now also sends a lightweight flag for the main asset plus a media category
  @JsonKey(name: 'is_main', defaultValue: false)
  final bool isMain;
  @JsonKey(defaultValue: 'gallery')
  final String category;

  const PropertyImageModel({
    required this.id,
    required this.propertyId,
    required this.imageUrl,
    this.caption,
    this.displayOrder = 0,
    this.isMainImage = false,
    this.isMain = false,
    this.category = 'gallery',
  });

  factory PropertyImageModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyImageModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyImageModelToJson(this);

  // Helper methods
  bool get isValid =>
      imageUrl.isNotEmpty && imageUrl != 'https://via.placeholder.com/400x300?text=No+Image';

  /// Payload-friendly map keeping both legacy and new main flags
  Map<String, dynamic> toApiJson() {
    final payload = toJson();
    payload['is_main'] = isMain || isMainImage;
    payload['is_main_image'] = isMainImage || isMain;
    payload['category'] = category.isEmpty ? 'gallery' : category;
    return payload;
  }

  bool get isPrimary => isMain || isMainImage;

  String get resolvedCategory => category.isEmpty ? 'gallery' : category;
  bool get isGallery => resolvedCategory == 'gallery' || resolvedCategory == 'photo';
  bool get isFloorPlan => resolvedCategory == 'floor_plan';

  String get thumbnailUrl {
    // If using a CDN, can append thumbnail parameters
    if (imageUrl.contains('cloudinary.com') || imageUrl.contains('imgur.com')) {
      final uri = Uri.parse(imageUrl);
      final newParams = {'w': '300', 'h': '200', 'fit': 'crop'};
      final mergedParams = {...uri.queryParameters, ...newParams};
      return uri.replace(queryParameters: mergedParams).toString();
    }
    return imageUrl;
  }

  String get fullSizeUrl {
    // If using a CDN, can append full size parameters
    if (imageUrl.contains('cloudinary.com') || imageUrl.contains('imgur.com')) {
      final uri = Uri.parse(imageUrl);
      final newParams = {'w': '1200', 'h': '800', 'fit': 'crop'};
      final mergedParams = {...uri.queryParameters, ...newParams};
      return uri.replace(queryParameters: mergedParams).toString();
    }
    return imageUrl;
  }
}
