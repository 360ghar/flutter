import 'package:latlong2/latlong.dart';

class LocationData {
  final String name;
  final String? city;
  final String? locality;
  final double latitude;
  final double longitude;

  LocationData({
    required this.name,
    this.city,
    this.locality,
    required this.latitude,
    required this.longitude,
  });
}

class LocationResult {
  final String placeId;
  final String description;
  final String? displayText;
  final String? structuredFormatting;
  final LatLng? coordinates;

  LocationResult({
    required this.placeId,
    required this.description,
    this.displayText,
    this.structuredFormatting,
    this.coordinates,
  });

  bool get hasCoordinates => coordinates != null;
}
