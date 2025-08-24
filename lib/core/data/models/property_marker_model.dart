import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'property_model.dart';

/// Model for property markers on Google Maps
class PropertyMarker {
  final String markerId;
  final PropertyModel property;
  final LatLng position;
  final bool isSelected;
  final bool isHighlighted;

  PropertyMarker({
    required this.markerId,
    required this.property,
    required this.position,
    this.isSelected = false,
    this.isHighlighted = false,
  });

  /// Create a marker from a property
  factory PropertyMarker.fromProperty(
    PropertyModel property, {
    bool isSelected = false,
    bool isHighlighted = false,
  }) {
    return PropertyMarker(
      markerId: property.markerId,
      property: property,
      position: property.latLng!,
      isSelected: isSelected,
      isHighlighted: isHighlighted,
    );
  }

  /// Copy with new values
  PropertyMarker copyWith({
    bool? isSelected,
    bool? isHighlighted,
  }) {
    return PropertyMarker(
      markerId: markerId,
      property: property,
      position: position,
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  /// Get the appropriate marker color based on state
  Color get markerColor {
    if (isSelected) {
      return Colors.blue; // Selected property
    } else if (isHighlighted) {
      return Colors.orange; // Highlighted property
    } else {
      return Colors.red; // Default property marker
    }
  }

  /// Get the marker icon size
  double get markerSize => isSelected ? 50.0 : 40.0;

  /// Check if this marker represents the given property
  bool representsProperty(PropertyModel property) {
    return this.property.id == property.id;
  }

  /// Check if this marker represents the given property ID
  bool representsPropertyId(int propertyId) {
    return property.id == propertyId;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyMarker &&
          runtimeType == other.runtimeType &&
          markerId == other.markerId;

  @override
  int get hashCode => markerId.hashCode;

  @override
  String toString() {
    return 'PropertyMarker(markerId: $markerId, isSelected: $isSelected, isHighlighted: $isHighlighted)';
  }
}

/// Extension methods for list of PropertyMarkers
extension PropertyMarkerListExtension on List<PropertyMarker> {
  /// Find marker by property ID
  PropertyMarker? findByPropertyId(int propertyId) {
    return firstWhereOrNull((marker) => marker.representsPropertyId(propertyId));
  }

  /// Find marker by property
  PropertyMarker? findByProperty(PropertyModel property) {
    return firstWhereOrNull((marker) => marker.representsProperty(property));
  }

  /// Update marker selection state
  List<PropertyMarker> updateSelection(int? selectedPropertyId) {
    return map((marker) {
      if (selectedPropertyId == null) {
        return marker.copyWith(isSelected: false);
      }
      return marker.copyWith(
        isSelected: marker.representsPropertyId(selectedPropertyId),
      );
    }).toList();
  }

  /// Update marker highlight state
  List<PropertyMarker> updateHighlight(int? highlightedPropertyId) {
    return map((marker) {
      if (highlightedPropertyId == null) {
        return marker.copyWith(isHighlighted: false);
      }
      return marker.copyWith(
        isHighlighted: marker.representsPropertyId(highlightedPropertyId),
      );
    }).toList();
  }

  /// Get all markers with location data
  List<PropertyMarker> get withValidLocation {
    return where((marker) => marker.property.hasLocation).toList();
  }
}
