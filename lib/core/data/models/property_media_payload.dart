import 'package:ghar360/core/data/models/property_image_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'property_media_payload.g.dart';

/// Minimal DTO for sending media updates/creates to the backend.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class PropertyMediaPayload {
  @JsonKey(name: 'main_image_url')
  final String? mainImageUrl;
  final List<PropertyImageModel>? images;
  @JsonKey(name: 'video_tour_url')
  final String? videoTourUrl;
  @JsonKey(name: 'video_urls')
  final List<String>? videoUrls;
  @JsonKey(name: 'virtual_tour_url')
  final String? virtualTourUrl;
  @JsonKey(name: 'google_street_view_url')
  final String? googleStreetViewUrl;
  @JsonKey(name: 'floor_plan_url')
  final String? floorPlanUrl;

  const PropertyMediaPayload({
    this.mainImageUrl,
    this.images,
    this.videoTourUrl,
    this.videoUrls,
    this.virtualTourUrl,
    this.googleStreetViewUrl,
    this.floorPlanUrl,
  });

  factory PropertyMediaPayload.fromJson(Map<String, dynamic> json) =>
      _$PropertyMediaPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyMediaPayloadToJson(this);

  PropertyMediaPayload copyWith({
    String? mainImageUrl,
    List<PropertyImageModel>? images,
    String? videoTourUrl,
    List<String>? videoUrls,
    String? virtualTourUrl,
    String? googleStreetViewUrl,
    String? floorPlanUrl,
  }) {
    return PropertyMediaPayload(
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      images: images ?? this.images,
      videoTourUrl: videoTourUrl ?? this.videoTourUrl,
      videoUrls: videoUrls ?? this.videoUrls,
      virtualTourUrl: virtualTourUrl ?? this.virtualTourUrl,
      googleStreetViewUrl: googleStreetViewUrl ?? this.googleStreetViewUrl,
      floorPlanUrl: floorPlanUrl ?? this.floorPlanUrl,
    );
  }
}
