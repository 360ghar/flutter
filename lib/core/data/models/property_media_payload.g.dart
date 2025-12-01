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

Map<String, dynamic> _$PropertyMediaPayloadToJson(
  PropertyMediaPayload instance,
) => <String, dynamic>{
  if (instance.mainImageUrl != null) 'main_image_url': instance.mainImageUrl,
  if (instance.images != null) 'images': instance.images!.map((e) => e.toApiJson()).toList(),
  if (instance.videoTourUrl != null) 'video_tour_url': instance.videoTourUrl,
  if (instance.videoUrls != null) 'video_urls': instance.videoUrls,
  if (instance.virtualTourUrl != null) 'virtual_tour_url': instance.virtualTourUrl,
  if (instance.googleStreetViewUrl != null) 'google_street_view_url': instance.googleStreetViewUrl,
  if (instance.floorPlanUrl != null) 'floor_plan_url': instance.floorPlanUrl,
};
