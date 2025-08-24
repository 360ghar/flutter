import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/debug_logger.dart';
import '../models/location_model.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static String? get _apiKey => dotenv.env['GOOGLE_PLACES_API_KEY'];

  /// Search for places using autocomplete
  static Future<List<LocationResult>> searchPlaces(String query, {
    String? country,
    LatLng? locationBias,
    double radius = 50000, // 50km
  }) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      DebugLogger.error('Google Places API key not found');
      return [];
    }

    if (query.length < 2) {
      return [];
    }

    try {
      final url = Uri.parse('$_baseUrl/autocomplete/json')
          .replace(queryParameters: {
        'input': query,
        'key': _apiKey!,
        'types': '(cities)', // Focus on cities for real estate
        'components': country != null ? 'country:$country' : 'country:in', // Default to India
        if (locationBias != null) ...{
          'location': '${locationBias.latitude},${locationBias.longitude}',
          'radius': radius.toString(),
        },
        'language': 'en',
      });

      DebugLogger.api('Searching places: $query');

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((prediction) {
            return LocationResult.fromPrediction(prediction);
          }).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          DebugLogger.info('No places found for query: $query');
          return [];
        } else {
          DebugLogger.error('Places API error: ${data['status']}');
          return [];
        }
      } else {
        DebugLogger.error('Places API HTTP error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      DebugLogger.error('Error searching places: $e');
      return [];
    }
  }

  /// Get place details including coordinates
  static Future<LocationResult?> getPlaceDetails(String placeId) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      DebugLogger.error('Google Places API key not found');
      return null;
    }

    try {
      final url = Uri.parse('$_baseUrl/details/json')
          .replace(queryParameters: {
        'place_id': placeId,
        'key': _apiKey!,
        'fields': 'place_id,formatted_address,geometry,address_components',
        'language': 'en',
      });

      DebugLogger.api('Getting place details for: $placeId');

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return LocationResult.fromPlaceDetails(data['result']);
        } else {
          DebugLogger.error('Place details API error: ${data['status']}');
          return null;
        }
      } else {
        DebugLogger.error('Place details API HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      DebugLogger.error('Error getting place details: $e');
      return null;
    }
  }

  /// Geocode an address to coordinates
  static Future<LatLng?> geocodeAddress(String address) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      DebugLogger.error('Google Places API key not found');
      return null;
    }

    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
          .replace(queryParameters: {
        'address': address,
        'key': _apiKey!,
        'region': 'in', // Bias towards India
        'language': 'en',
      });

      DebugLogger.api('Geocoding address: $address');

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            final location = results[0]['geometry']['location'];
            return LatLng(location['lat'], location['lng']);
          }
        } else {
          DebugLogger.error('Geocoding API error: ${data['status']}');
        }
      } else {
        DebugLogger.error('Geocoding API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Error geocoding address: $e');
    }

    return null;
  }

  /// Reverse geocode coordinates to address
  static Future<String?> reverseGeocode(LatLng coordinates) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      DebugLogger.error('Google Places API key not found');
      return null;
    }

    try {
      final url = Uri.parse('https://maps.googleapis.com/maps/api/geocode/json')
          .replace(queryParameters: {
        'latlng': '${coordinates.latitude},${coordinates.longitude}',
        'key': _apiKey!,
        'result_type': 'locality|administrative_area_level_1',
        'language': 'en',
      });

      DebugLogger.api('Reverse geocoding coordinates: $coordinates');

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            return results[0]['formatted_address'];
          }
        } else {
          DebugLogger.error('Reverse geocoding API error: ${data['status']}');
        }
      } else {
        DebugLogger.error('Reverse geocoding API HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      DebugLogger.error('Error reverse geocoding: $e');
    }

    return null;
  }

  /// Get current location using IP-based geocoding as fallback
  static Future<LocationResult?> getCurrentLocationByIP() async {
    try {
      // Use a free IP geolocation service
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          final lat = data['lat'];
          final lng = data['lon'];
          final city = data['city'];
          final region = data['regionName'];
          final country = data['country'];

          return LocationResult(
            placeId: 'ip_location',
            description: '$city, $region, $country',
            coordinates: LatLng(lat, lng),
            city: city,
            state: region,
            country: country,
          );
        }
      }

      DebugLogger.error('IP geolocation failed: ${response.statusCode}');
    } catch (e) {
      DebugLogger.error('Error getting IP location: $e');
    }

    return null;
  }

  /// Validate API key
  static Future<bool> validateApiKey() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return false;
    }

    try {
      final url = Uri.parse('$_baseUrl/autocomplete/json')
          .replace(queryParameters: {
        'input': 'test',
        'key': _apiKey!,
      });

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] != 'REQUEST_DENIED';
      }
    } catch (e) {
      DebugLogger.error('Error validating API key: $e');
    }

    return false;
  }

  /// Get popular cities for initial suggestions
  static List<LocationResult> getPopularCities() {
    return [
      LocationResult(
        placeId: 'popular_delhi',
        description: 'Delhi, India',
        structuredFormatting: 'Delhi',
        coordinates: const LatLng(28.6139, 77.2090),
        city: 'Delhi',
        state: 'Delhi',
        country: 'India',
      ),
      LocationResult(
        placeId: 'popular_mumbai',
        description: 'Mumbai, Maharashtra, India',
        structuredFormatting: 'Mumbai',
        coordinates: const LatLng(19.0760, 72.8777),
        city: 'Mumbai',
        state: 'Maharashtra',
        country: 'India',
      ),
      LocationResult(
        placeId: 'popular_bangalore',
        description: 'Bengaluru, Karnataka, India',
        structuredFormatting: 'Bengaluru',
        coordinates: const LatLng(12.9716, 77.5946),
        city: 'Bengaluru',
        state: 'Karnataka',
        country: 'India',
      ),
      LocationResult(
        placeId: 'popular_chennai',
        description: 'Chennai, Tamil Nadu, India',
        structuredFormatting: 'Chennai',
        coordinates: const LatLng(13.0827, 80.2707),
        city: 'Chennai',
        state: 'Tamil Nadu',
        country: 'India',
      ),
      LocationResult(
        placeId: 'popular_pune',
        description: 'Pune, Maharashtra, India',
        structuredFormatting: 'Pune',
        coordinates: const LatLng(18.5204, 73.8567),
        city: 'Pune',
        state: 'Maharashtra',
        country: 'India',
      ),
    ];
  }
}
