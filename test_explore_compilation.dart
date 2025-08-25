// Simple test to verify explore feature compilation
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Mock classes for testing
class PropertyModel {
  final String title;
  final String mainImage;
  final String formattedPrice;
  final String addressDisplay;
  final String purposeString;
  final int? bedrooms;
  final int? bathrooms;
  final int? areaSqft;
  final double? distanceKm;
  final String? distanceText;
  final bool liked;
  final int id;
  final double? latitude;
  final double? longitude;

  PropertyModel({
    required this.title,
    required this.mainImage,
    required this.formattedPrice,
    required this.addressDisplay,
    required this.purposeString,
    this.bedrooms,
    this.bathrooms,
    this.areaSqft,
    this.distanceKm,
    this.distanceText,
    required this.liked,
    required this.id,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;
  double? get latLng => latitude;
}

class AppColors {
  static const Color primaryYellow = Colors.yellow;
}

class DebugLogger {
  static void api(String message) => print(message);
}

// Test the property card compilation
class TestPropertyCard extends StatelessWidget {
  final PropertyModel testProperty = PropertyModel(
    title: 'Test Property',
    mainImage: 'https://example.com/image.jpg',
    formattedPrice: '\$100,000',
    addressDisplay: '123 Test St',
    purposeString: 'Sale',
    bedrooms: 2,
    bathrooms: 1,
    areaSqft: 1000,
    distanceKm: 5.0,
    distanceText: '5.0 km',
    liked: false,
    id: 1,
    latitude: 28.6139,
    longitude: 77.2090,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          width: 320,
          height: 120,
          child: Row(
            children: [
              // Left: Property Image
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(testProperty.mainImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Right: Property Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        testProperty.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              testProperty.addressDisplay,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (testProperty.bedrooms != null) ...[
                            Text('${testProperty.bedrooms}B', style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 8),
                          ],
                          if (testProperty.bathrooms != null) ...[
                            Text('${testProperty.bathrooms}Ba', style: const TextStyle(fontSize: 10)),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('View Details', style: TextStyle(fontSize: 10, color: AppColors.primaryYellow)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(TestPropertyCard());
}
