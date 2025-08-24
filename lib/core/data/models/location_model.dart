import 'package:latlong2/latlong.dart';

/// Model for location search results from Google Places API
class LocationResult {
  final String placeId;
  final String description;
  final String? structuredFormatting;
  final LatLng? coordinates;
  final String? city;
  final String? state;
  final String? country;

  LocationResult({
    required this.placeId,
    required this.description,
    this.structuredFormatting,
    this.coordinates,
    this.city,
    this.state,
    this.country,
  });

  /// Create from Google Places prediction
  factory LocationResult.fromPrediction(dynamic prediction) {
    return LocationResult(
      placeId: prediction['place_id'] ?? '',
      description: prediction['description'] ?? '',
      structuredFormatting: prediction['structured_formatting']?['main_text'],
    );
  }

  /// Create from place details
  factory LocationResult.fromPlaceDetails(dynamic details) {
    final geometry = details['geometry'];
    LatLng? coordinates;

    if (geometry != null && geometry['location'] != null) {
      final location = geometry['location'];
      coordinates = LatLng(location['lat'], location['lng']);
    }

    // Extract address components
    String? city, state, country;
    final addressComponents = details['address_components'] as List?;
    if (addressComponents != null) {
      for (final component in addressComponents) {
        final types = component['types'] as List?;
        if (types != null) {
          if (types.contains('locality') || types.contains('administrative_area_level_2')) {
            city = component['long_name'];
          } else if (types.contains('administrative_area_level_1')) {
            state = component['long_name'];
          } else if (types.contains('country')) {
            country = component['long_name'];
          }
        }
      }
    }

    return LocationResult(
      placeId: details['place_id'] ?? '',
      description: details['formatted_address'] ?? '',
      coordinates: coordinates,
      city: city,
      state: state,
      country: country,
    );
  }

  /// Get display text for the location
  String get displayText => structuredFormatting ?? description;

  /// Get full address text
  String get fullAddress => description;

  /// Check if location has valid coordinates
  bool get hasCoordinates => coordinates != null;

  @override
  String toString() {
    return 'LocationResult(description: $description, coordinates: $coordinates)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationResult &&
          runtimeType == other.runtimeType &&
          placeId == other.placeId;

  @override
  int get hashCode => placeId.hashCode;
}

/// Model for user's current location
class CurrentLocation {
  final LatLng coordinates;
  final String? address;
  final double? accuracy;
  final DateTime timestamp;

  CurrentLocation({
    required this.coordinates,
    this.address,
    this.accuracy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Check if location is recent (within last 5 minutes)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inMinutes < 5;
  }

  /// Check if location has good accuracy (within 100 meters)
  bool get hasGoodAccuracy {
    return accuracy != null && accuracy! <= 100.0;
  }

  @override
  String toString() {
    return 'CurrentLocation(coordinates: $coordinates, accuracy: $accuracy, recent: $isRecent)';
  }
}
