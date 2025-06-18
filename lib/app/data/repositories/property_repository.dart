import 'package:get/get.dart';
import '../providers/api_provider.dart';
import '../models/property_model.dart';

class PropertyRepository extends GetxService {
  final IApiProvider _apiProvider;

  PropertyRepository(this._apiProvider);

  Future<List<PropertyModel>> getProperties() async {
    try {
      return await _apiProvider.getProperties();
    } catch (e) {
      throw Exception('Failed to fetch properties: $e');
    }
  }

  Future<PropertyModel> getPropertyById(String id) async {
    try {
      return await _apiProvider.getPropertyById(id);
    } catch (e) {
      throw Exception('Failed to fetch property: $e');
    }
  }

  Future<List<PropertyModel>> getFavouriteProperties() async {
    try {
      return await _apiProvider.getFavouriteProperties();
    } catch (e) {
      throw Exception('Failed to fetch favourite properties: $e');
    }
  }

  Future<void> addToFavourites(String propertyId) async {
    try {
      await _apiProvider.addToFavourites(propertyId);
    } catch (e) {
      throw Exception('Failed to add property to favourites: $e');
    }
  }

  Future<void> removeFromFavourites(String propertyId) async {
    try {
      await _apiProvider.removeFromFavourites(propertyId);
    } catch (e) {
      throw Exception('Failed to remove property from favourites: $e');
    }
  }

  Future<List<PropertyModel>> getPassedProperties() async {
    try {
      return await _apiProvider.getPassedProperties();
    } catch (e) {
      throw Exception('Failed to fetch passed properties: $e');
    }
  }

  Future<void> addToPassedProperties(String propertyId) async {
    try {
      await _apiProvider.addToPassedProperties(propertyId);
    } catch (e) {
      throw Exception('Failed to add property to passed list: $e');
    }
  }

  Future<void> removeFromPassedProperties(String propertyId) async {
    try {
      await _apiProvider.removeFromPassedProperties(propertyId);
    } catch (e) {
      throw Exception('Failed to remove property from passed list: $e');
    }
  }
} 