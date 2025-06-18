import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/property_model.dart';
import 'property_controller.dart';
import '../modules/filters/controllers/filters_controller.dart';

class ExploreController extends GetxController {
  final PropertyController _propertyController = Get.find<PropertyController>();
  
  // Map controller
  MapController? mapController;
  
  // Location and map state
  final Rx<LatLng> currentLocation = LatLng(28.4595, 77.0266).obs; // Default to Gurgaon
  final RxDouble currentZoom = 13.0.obs;
  final RxDouble mapRadius = 5.0.obs; // 5km radius
  final RxBool isLoadingLocation = false.obs;
  final RxBool hasLocationPermission = false.obs;
  
  // Map markers and properties
  final RxList<Marker> markers = <Marker>[].obs;
  final RxList<PropertyModel> visibleProperties = <PropertyModel>[].obs;
  final RxList<PropertyModel> filteredProperties = <PropertyModel>[].obs;
  
  // Search functionality
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  
  // Filters
  final RxBool showFilters = false.obs;
  FiltersController? filtersController;
  
  // UI state
  final RxBool showPropertyList = true.obs;
  final RxString selectedPropertyId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Initialize map controller
    mapController = MapController();
    
    // Try to get filters controller if it exists
    try {
      filtersController = Get.find<FiltersController>();
    } catch (e) {
      // FiltersController not found, will create when needed
    }
    
    _initializeLocation();
    _setupPropertyListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void _setupPropertyListener() {
    // Listen to property changes and update markers
    ever(_propertyController.properties, (_) {
      _updateMarkersAndVisibleProperties();
    });
    
    // Listen to location changes and update visible properties
    ever(currentLocation, (_) {
      _updateMarkersAndVisibleProperties();
    });
    
    // Listen to zoom changes and update radius
    ever(currentZoom, (zoom) {
      _updateMapRadius(zoom);
      _updateMarkersAndVisibleProperties();
    });
  }

  void _updateMapRadius(double zoom) {
    // Calculate radius based on zoom level
    if (zoom >= 16) {
      mapRadius.value = 1.0; // 1km
    } else if (zoom >= 14) {
      mapRadius.value = 2.5; // 2.5km
    } else if (zoom >= 12) {
      mapRadius.value = 5.0; // 5km
    } else if (zoom >= 10) {
      mapRadius.value = 10.0; // 10km
    } else {
      mapRadius.value = 20.0; // 20km
    }
  }

  Future<void> _initializeLocation() async {
    print('_initializeLocation started');
    try {
      isLoadingLocation.value = true;
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        print('Location services not enabled, showing dialog');
        hasLocationPermission.value = false;
        _showLocationDialog();
        _setDefaultLocation();
        return;
      }
      
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        hasLocationPermission.value = false;
        _showLocationDialog();
        _setDefaultLocation();
        return;
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        hasLocationPermission.value = true;
        
        try {
          // Get current position with timeout
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          
          currentLocation.value = LatLng(position.latitude, position.longitude);
          
          // Move camera to current location
          if (mapController != null) {
            mapController!.move(currentLocation.value, currentZoom.value);
          }
        } catch (e) {
          print('Error getting current position: $e');
          _setDefaultLocation();
        }
      } else {
        hasLocationPermission.value = false;
        _setDefaultLocation();
      }
    } catch (e) {
      print('Error initializing location: $e');
      hasLocationPermission.value = false;
      _setDefaultLocation();
    } finally {
      isLoadingLocation.value = false;
      _updateMarkersAndVisibleProperties();
    }
  }

  void _setDefaultLocation() {
    // Set to center of Gurgaon
    currentLocation.value = LatLng(28.4595, 77.0266);
    if (mapController != null) {
      mapController!.move(currentLocation.value, currentZoom.value);
    }
  }

  void _showLocationDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Location Access'),
        content: const Text(
          'Location access is disabled. To see nearby properties, please enable location services in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Geolocator.openLocationSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _updateMarkersAndVisibleProperties() {
    final allProperties = _propertyController.properties;
    final center = currentLocation.value;
    final radius = mapRadius.value;
    
    // Filter properties within radius
    final propertiesInRadius = allProperties.where((property) {
      final distance = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        property.latitude,
        property.longitude,
      ) / 1000; // Convert to kilometers
      
      return distance <= radius;
    }).toList();
    
    // Apply additional filters if available
    List<PropertyModel> finalProperties = propertiesInRadius;
    if (filtersController != null) {
      finalProperties = _applyFilters(propertiesInRadius);
    }
    
    visibleProperties.value = finalProperties;
    filteredProperties.value = finalProperties;
    
    // Update markers
    _updateMarkers(finalProperties);
  }

  List<PropertyModel> _applyFilters(List<PropertyModel> properties) {
    return properties.where((property) {
      // Purpose filter
      if (!_matchesPurpose(property)) {
        return false;
      }

      // Price filter (adjusted based on purpose)
      final adjustedPrice = _getAdjustedPrice(property);
      if (adjustedPrice < _propertyController.minPrice.value || 
          adjustedPrice > _propertyController.maxPrice.value) {
        return false;
      }

      // Bedrooms filter (skip for Stay mode)
      if (_propertyController.selectedPurpose.value != 'Stay') {
        if (property.bedrooms < _propertyController.minBedrooms.value || 
            property.bedrooms > _propertyController.maxBedrooms.value) {
          return false;
        }
      }

      // Property type filter
      if (_propertyController.propertyType.value != 'All' && 
          !_matchesPropertyType(property)) {
        return false;
      }

      // Amenities filter
      if (_propertyController.selectedAmenities.isNotEmpty) {
        final hasAllAmenities = _propertyController.selectedAmenities
            .every((amenity) => property.amenities.contains(amenity));
        if (!hasAllAmenities) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _matchesPurpose(PropertyModel property) {
    switch (_propertyController.selectedPurpose.value) {
      case 'Stay':
        return property.propertyType.toLowerCase().contains('apartment') ||
               property.propertyType.toLowerCase().contains('studio') ||
               property.price < 5000000;
      case 'Rent':
        return true;
      case 'Buy':
      default:
        return true;
    }
  }

  double _getAdjustedPrice(PropertyModel property) {
    switch (_propertyController.selectedPurpose.value) {
      case 'Stay':
        return (property.price / 365 / 100).clamp(500.0, 50000.0);
      case 'Rent':
        return (property.price * 0.001).clamp(5000.0, 500000.0);
      case 'Buy':
      default:
        return property.price;
    }
  }

  bool _matchesPropertyType(PropertyModel property) {
    final selectedType = _propertyController.propertyType.value;
    
    if (_propertyController.selectedPurpose.value == 'Stay') {
      switch (selectedType) {
        case 'Hotel':
          return property.propertyType.toLowerCase().contains('apartment') ||
                 property.propertyType.toLowerCase().contains('studio');
        case 'Resort':
          return property.propertyType.toLowerCase().contains('villa') ||
                 property.propertyType.toLowerCase().contains('penthouse');
        default:
          return property.propertyType == selectedType;
      }
    }
    
    return property.propertyType == selectedType;
  }

  void _updateMarkers(List<PropertyModel> properties) {
    final newMarkers = <Marker>[];
    
    for (final property in properties) {
      final marker = Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(property.latitude, property.longitude),
        child: GestureDetector(
          onTap: () => selectProperty(property.id),
          child: Container(
            decoration: BoxDecoration(
              color: selectedPropertyId.value == property.id 
                  ? const Color(0xFFFFBC05) // Yellow for selected
                  : const Color(0xFFFF6B35), // Orange for unselected
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.home,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
      newMarkers.add(marker);
    }
    
    markers.value = newMarkers;
  }

  void onMapReady() {
    print('Map ready');
    
    // Move to current location if available
    if (hasLocationPermission.value) {
      mapController?.move(currentLocation.value, currentZoom.value);
    } else {
      // Move to default location (Gurgaon)
      mapController?.move(currentLocation.value, currentZoom.value);
    }
  }

  void onPositionChanged(MapPosition position, bool hasGesture) {
    if (hasGesture) {
      currentLocation.value = position.center!;
      currentZoom.value = position.zoom!;
    }
  }

  void onMapEvent(MapEvent mapEvent) {
    if (mapEvent is MapEventMoveEnd) {
      _updateMarkersAndVisibleProperties();
    }
  }

  void selectProperty(String propertyId) {
    selectedPropertyId.value = propertyId;
    _updateMarkers(filteredProperties);
    
    // Scroll to property in list if needed
    // This would be handled by the UI layer
  }

  void viewPropertyDetails(PropertyModel property) {
    Get.toNamed('/property-details', arguments: property);
  }

  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      isSearching.value = true;
      searchQuery.value = query;
      
      // In a real app, you would use a geocoding service
      // For now, we'll simulate a search by checking if query matches any city
      final properties = _propertyController.properties;
      final matchingProperty = properties.firstWhereOrNull(
        (p) => p.city.toLowerCase().contains(query.toLowerCase()) ||
               p.address.toLowerCase().contains(query.toLowerCase()),
      );
      
      if (matchingProperty != null) {
        final newLocation = LatLng(matchingProperty.latitude, matchingProperty.longitude);
        currentLocation.value = newLocation;
        
        if (mapController != null) {
          mapController!.move(newLocation, 14.0);
          currentZoom.value = 14.0;
        }
        
        Get.snackbar(
          'Location Found',
          'Showing properties near ${matchingProperty.city}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          'Location Not Found',
          'No properties found for "$query"',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Search Error',
        'Unable to search location',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  Future<void> goToCurrentLocation() async {
    if (!hasLocationPermission.value) {
      await _initializeLocation();
      return;
    }
    
    try {
      isLoadingLocation.value = true;
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final newLocation = LatLng(position.latitude, position.longitude);
      currentLocation.value = newLocation;
      
      if (mapController != null) {
        mapController!.move(newLocation, 14.0);
        currentZoom.value = 14.0;
      }
    } catch (e) {
      Get.snackbar(
        'Location Error',
        'Unable to get current location',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoadingLocation.value = false;
    }
  }

  void toggleFilters() {
    showFilters.value = !showFilters.value;
  }

  void openFilters() {
    Get.toNamed('/filters');
  }

  void refreshFilteredProperties() {
    // Update the markers on the map with applied filters
    _updateMarkersAndVisibleProperties();
    
    // Show success message
    Get.snackbar(
      'Filters Applied',
      'Map updated with filtered properties',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFFBC05),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void togglePropertyList() {
    showPropertyList.value = !showPropertyList.value;
  }

  // Getters
  CircleMarker get radiusCircle => CircleMarker(
    point: currentLocation.value,
    radius: mapRadius.value * 1000, // Convert km to meters
    color: const Color(0xFFFFBC05).withOpacity(0.1),
    borderColor: const Color(0xFFFFBC05),
    borderStrokeWidth: 2.0,
    useRadiusInMeter: true,
  );

  String get radiusText => '${mapRadius.value.toStringAsFixed(1)} km radius';
  
  int get visiblePropertyCount => visibleProperties.length;
} 