import 'package:get/get.dart';
import '../providers/api_provider.dart';
import '../models/property_model.dart';
import '../../utils/debug_logger.dart';

class PropertyRepository extends GetxService {
  final IApiProvider _apiProvider;

  PropertyRepository(this._apiProvider);

  Future<List<PropertyModel>> getProperties() async {
    try {
      DebugLogger.info('🔍 Fetching properties from API provider');
      final properties = await _apiProvider.getProperties();
      DebugLogger.success('✅ Successfully fetched ${properties.length} properties from API');
      return properties;
    } catch (e) {
      DebugLogger.error('❌ API failed for getProperties: $e');
      throw Exception('Failed to fetch properties from API: $e');
    }
  }

  Future<PropertyModel> getPropertyById(String id) async {
    try {
      DebugLogger.info('🔍 Fetching property by ID: $id');
      final property = await _apiProvider.getPropertyById(id);
      DebugLogger.success('✅ Successfully fetched property: ${property.title}');
      return property;
    } catch (e) {
      DebugLogger.error('❌ API failed for getPropertyById($id): $e');
      throw Exception('Failed to fetch property $id from API: $e');
    }
  }

  Future<List<PropertyModel>> getFavouriteProperties() async {
    try {
      DebugLogger.info('🔍 Fetching favourite properties');
      final favourites = await _apiProvider.getFavouriteProperties();
      DebugLogger.success('✅ Successfully fetched ${favourites.length} favourite properties');
      return favourites;
    } catch (e) {
      DebugLogger.error('❌ API failed for getFavouriteProperties: $e');
      throw Exception('Failed to fetch favourite properties from API: $e');
    }
  }

  Future<void> addToFavourites(String propertyId) async {
    try {
      DebugLogger.info('💖 Adding property to favourites: $propertyId');
      await _apiProvider.addToFavourites(propertyId);
      DebugLogger.success('✅ Successfully added property to favourites');
    } catch (e) {
      DebugLogger.error('❌ API failed for addToFavourites($propertyId): $e');
      throw Exception('Failed to add property to favourites in API: $e');
    }
  }

  Future<void> removeFromFavourites(String propertyId) async {
    try {
      DebugLogger.info('💔 Removing property from favourites: $propertyId');
      await _apiProvider.removeFromFavourites(propertyId);
      DebugLogger.success('✅ Successfully removed property from favourites');
    } catch (e) {
      DebugLogger.error('❌ API failed for removeFromFavourites($propertyId): $e');
      throw Exception('Failed to remove property from favourites in API: $e');
    }
  }

  Future<List<PropertyModel>> getPassedProperties() async {
    try {
      DebugLogger.info('🔍 Fetching passed properties');
      final passed = await _apiProvider.getPassedProperties();
      DebugLogger.success('✅ Successfully fetched ${passed.length} passed properties');
      return passed;
    } catch (e) {
      DebugLogger.error('❌ API failed for getPassedProperties: $e');
      throw Exception('Failed to fetch passed properties from API: $e');
    }
  }

  Future<void> addToPassedProperties(String propertyId) async {
    try {
      DebugLogger.info('👎 Adding property to passed list: $propertyId');
      await _apiProvider.addToPassedProperties(propertyId);
      DebugLogger.success('✅ Successfully added property to passed list');
    } catch (e) {
      DebugLogger.error('❌ API failed for addToPassedProperties($propertyId): $e');
      throw Exception('Failed to add property to passed list in API: $e');
    }
  }

  Future<void> removeFromPassedProperties(String propertyId) async {
    try {
      DebugLogger.info('↩️ Removing property from passed list: $propertyId');
      await _apiProvider.removeFromPassedProperties(propertyId);
      DebugLogger.success('✅ Successfully removed property from passed list');
    } catch (e) {
      DebugLogger.error('❌ API failed for removeFromPassedProperties($propertyId): $e');
      throw Exception('Failed to remove property from passed list in API: $e');
    }
  }
} 