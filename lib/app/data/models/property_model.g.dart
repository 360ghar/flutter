// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyModel _$PropertyModelFromJson(Map<String, dynamic> json) =>
    PropertyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      bedrooms: (json['bedrooms'] as num).toInt(),
      bathrooms: (json['bathrooms'] as num).toInt(),
      area: (json['area'] as num).toDouble(),
      propertyType: json['propertyType'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      tour360Url: json['tour360Url'] as String?,
      youtubeVideoUrl: json['youtubeVideoUrl'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      amenities:
          (json['amenities'] as List<dynamic>).map((e) => e as String).toList(),
      isAvailable: json['isAvailable'] as bool,
      listedDate: DateTime.parse(json['listedDate'] as String),
      agentId: json['agentId'] as String,
      agentName: json['agentName'] as String,
      agentPhone: json['agentPhone'] as String,
      agentEmail: json['agentEmail'] as String,
      agentImage: json['agentImage'] as String,
    );

Map<String, dynamic> _$PropertyModelToJson(PropertyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'area': instance.area,
      'propertyType': instance.propertyType,
      'images': instance.images,
      'tour360Url': instance.tour360Url,
      'youtubeVideoUrl': instance.youtubeVideoUrl,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'amenities': instance.amenities,
      'isAvailable': instance.isAvailable,
      'listedDate': instance.listedDate.toIso8601String(),
      'agentId': instance.agentId,
      'agentName': instance.agentName,
      'agentPhone': instance.agentPhone,
      'agentEmail': instance.agentEmail,
      'agentImage': instance.agentImage,
    };
