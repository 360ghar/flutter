// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_media_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyMediaPayload _$PropertyMediaPayloadFromJson(Map<String, dynamic> json) =>
    PropertyMediaPayload(
      mainImageUrl: json['main_image_url'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => PropertyImageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      videoTourUrl: json['video_tour_url'] as String?,
      videoUrls: (json['video_urls'] as List<dynamic>?)?.map((e) => e as String).toList(),
      virtualTourUrl: json['virtual_tour_url'] as String?,
      googleStreetViewUrl: json['google_street_view_url'] as String?,
      floorPlanUrl: json['floor_plan_url'] as String?,
    );

Map<String, dynamic> _$PropertyMediaPayloadToJson(PropertyMediaPayload instance) =>
    <String, dynamic>{
      'main_image_url': ?instance.mainImageUrl,
      'images': ?instance.images?.map((e) => e.toJson()).toList(),
      'video_tour_url': ?instance.videoTourUrl,
      'video_urls': ?instance.videoUrls,
      'virtual_tour_url': ?instance.virtualTourUrl,
      'google_street_view_url': ?instance.googleStreetViewUrl,
      'floor_plan_url': ?instance.floorPlanUrl,
    };
