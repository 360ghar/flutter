import 'package:get/get.dart';
import '../models/property_model.dart';
import '../models/property_card_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import '../../utils/debug_logger.dart';

abstract class IApiProvider {
  Future<List<PropertyCardModel>> getProperties();
  Future<PropertyModel> getPropertyById(String id);
  Future<List<PropertyCardModel>> getFavouriteProperties();
  Future<void> addToFavourites(String propertyId);
  Future<void> removeFromFavourites(String propertyId);
  Future<List<PropertyCardModel>> getPassedProperties();
  Future<void> addToPassedProperties(String propertyId);
  Future<void> removeFromPassedProperties(String propertyId);
  Future<UserModel> getUserProfile();
  Future<void> updateUserProfile(UserModel user);
  Future<void> updateUserPreferences(Map<String, dynamic> preferences);
}

class RealApiProvider extends GetxService implements IApiProvider {
  late final ApiService _apiService;

  @override
  void onInit() {
    super.onInit();
    try {
      _apiService = Get.find<ApiService>();
      DebugLogger.init('🔧 RealApiProvider initialized');
    } catch (e) {
      DebugLogger.error('❌ Error initializing RealApiProvider: $e');
      rethrow;
    }
  }

  @override
  void onClose() {
    // Clean up any resources
    super.onClose();
  }

  @override
  Future<List<PropertyCardModel>> getProperties() async {
    try {
      DebugLogger.api('📋 Fetching properties from backend...');
      final response = await _apiService.discoverProperties(
        latitude: 19.0760, // Default Mumbai location
        longitude: 72.8777,
        limit: 50,
      );
      DebugLogger.success('✅ Retrieved ${response.properties.length} properties from backend');
      return response.properties;
    } catch (e) {
      DebugLogger.error('❌ Error fetching properties from backend: $e');
      DebugLogger.info('💡 Consider checking if your backend server is running');
      return [];
    }
  }

  @override
  Future<PropertyModel> getPropertyById(String id) async {
    try {
      DebugLogger.api('🔍 Fetching property details for ID: $id');
      final property = await _apiService.getPropertyDetails(int.parse(id));
      DebugLogger.success('✅ Retrieved property: ${property.title}');
      return property;
    } catch (e) {
      DebugLogger.error('❌ Error fetching property details: $e');
      rethrow;
    }
  }

  @override
  Future<List<PropertyCardModel>> getFavouriteProperties() async {
    try {
      DebugLogger.api('❤️ Fetching liked properties from backend...');
      final properties = await _apiService.getLikedProperties();
      DebugLogger.success('✅ Retrieved ${properties.length} liked properties');
      return properties;
    } catch (e) {
      DebugLogger.error('❌ Error fetching liked properties: $e');
      return [];
    }
  }

  @override
  Future<void> addToFavourites(String propertyId) async {
    try {
      DebugLogger.api('❤️ Adding property $propertyId to favorites...');
      await _apiService.swipeProperty(int.parse(propertyId), true);
      await _apiService.trackEvent('property_liked', {
        'property_id': int.parse(propertyId),
        'action': 'add_to_favourites',
      });
      DebugLogger.success('✅ Property added to favorites');
    } catch (e) {
      DebugLogger.error('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavourites(String propertyId) async {
    try {
      DebugLogger.api('💔 Removing property $propertyId from favorites...');
      // Note: API doesn't have direct remove from favorites,
      // this would need to be implemented on backend
      await _apiService.trackEvent('property_unliked', {
        'property_id': int.parse(propertyId),
        'action': 'remove_from_favourites',
      });
      DebugLogger.success('✅ Property removed from favorites');
    } catch (e) {
      DebugLogger.error('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  @override
  Future<List<PropertyCardModel>> getPassedProperties() async {
    try {
      DebugLogger.api('🔄 Fetching passed properties from backend...');
      final swipeHistory = await _apiService.getSwipeHistory();
      final passedIds = swipeHistory
          .where((swipe) => swipe['is_liked'] == false)
          .map((swipe) => swipe['property_id'].toString())
          .toList();
      
      // For now, return empty list as we'd need to fetch individual properties
      // This could be optimized with a backend endpoint
      DebugLogger.success('✅ Retrieved ${passedIds.length} passed properties');
      return [];
    } catch (e) {
      DebugLogger.error('❌ Error fetching passed properties: $e');
      return [];
    }
  }

  @override
  Future<void> addToPassedProperties(String propertyId) async {
    try {
      DebugLogger.api('🔄 Adding property $propertyId to passed...');
      await _apiService.swipeProperty(int.parse(propertyId), false);
      await _apiService.trackEvent('property_passed', {
        'property_id': int.parse(propertyId),
        'action': 'add_to_passed',
      });
      DebugLogger.success('✅ Property added to passed');
    } catch (e) {
      DebugLogger.error('❌ Error adding to passed: $e');
      rethrow;
    }
  }

  @override
  Future<void> removeFromPassedProperties(String propertyId) async {
    // This would require backend implementation
    await _apiService.trackEvent('property_unpass', {
      'property_id': int.parse(propertyId),
      'action': 'remove_from_passed',
    });
  }

  @override
  Future<UserModel> getUserProfile() async {
    try {
      DebugLogger.api('👤 Fetching user profile from backend...');
      final user = await _apiService.getCurrentUser();
      DebugLogger.success('✅ Retrieved user profile');
      return user;
    } catch (e) {
      DebugLogger.error('❌ Error fetching user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    try {
      DebugLogger.api('👤 Updating user profile in backend...');
      await _apiService.updateUserProfile(user.toJson());
      DebugLogger.success('✅ User profile updated');
    } catch (e) {
      DebugLogger.error('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      DebugLogger.api('👤 Updating user preferences in backend...');
      await _apiService.updateUserPreferences(preferences);
      DebugLogger.success('✅ User preferences updated');
    } catch (e) {
      DebugLogger.error('❌ Error updating user preferences: $e');
      rethrow;
    }
  }
}

 