import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';

abstract class IApiProvider {
  Future<List<PropertyModel>> getProperties();
  Future<PropertyModel> getPropertyById(String id);
  Future<List<PropertyModel>> getFavouriteProperties();
  Future<void> addToFavourites(String propertyId);
  Future<void> removeFromFavourites(String propertyId);
  Future<List<PropertyModel>> getPassedProperties();
  Future<void> addToPassedProperties(String propertyId);
  Future<void> removeFromPassedProperties(String propertyId);
  Future<UserModel> getUserProfile();
  Future<void> updateUserProfile(UserModel user);
  Future<void> updateUserPreferences(Map<String, dynamic> preferences);
}

class MockApiProvider extends GetxService implements IApiProvider {
  List<PropertyModel> _properties = [];
  List<String> _favourites = [];
  List<String> _passed = [];
  UserModel? _currentUser;

  @override
  void onInit() {
    super.onInit();
    _loadMockData();
  }

  Future<void> _loadMockData() async {
    try {
      // Load mock properties
      final String propertiesJson = await rootBundle.loadString('assets/mock_api/properties.json');
      final List<dynamic> propertiesList = json.decode(propertiesJson);
      _properties = propertiesList.map((json) => PropertyModel.fromJson(json)).toList();

      // Load mock user
      final String userJson = await rootBundle.loadString('assets/mock_api/user.json');
      _currentUser = UserModel.fromJson(json.decode(userJson));

      // Load mock favourites
      final String favouritesJson = await rootBundle.loadString('assets/mock_api/favourites.json');
      _favourites = List<String>.from(json.decode(favouritesJson));
      print('Loaded favourites: $_favourites');

      // Initialize empty passed list (could load from storage in real app)
      _passed = [];
      print('Loaded ${_properties.length} properties and ${_favourites.length} favourites');
    } catch (e) {
      print('Error loading mock data: $e');
    }
  }

  @override
  Future<List<PropertyModel>> getProperties() async {
    if (_properties.isEmpty) {
      await _loadMockData();
    }
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
    return _properties;
  }

  @override
  Future<PropertyModel> getPropertyById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final property = _properties.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Property not found'),
    );
    return property;
  }

  @override
  Future<List<PropertyModel>> getFavouriteProperties() async {
    if (_properties.isEmpty || _favourites.isEmpty) {
      await _loadMockData();
    }
    await Future.delayed(const Duration(milliseconds: 600));
    final favouriteProps = _properties.where((p) => _favourites.contains(p.id)).toList();
    print('getFavouriteProperties: Found ${favouriteProps.length} favourite properties');
    print('Favourites IDs: $_favourites');
    print('Available property IDs: ${_properties.map((p) => p.id).toList()}');
    return favouriteProps;
  }

  @override
  Future<void> addToFavourites(String propertyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_favourites.contains(propertyId)) {
      _favourites.add(propertyId);
    }
    // Remove from passed if it was there
    _passed.remove(propertyId);
  }

  @override
  Future<void> removeFromFavourites(String propertyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _favourites.remove(propertyId);
  }

  @override
  Future<List<PropertyModel>> getPassedProperties() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _properties.where((p) => _passed.contains(p.id)).toList();
  }

  @override
  Future<void> addToPassedProperties(String propertyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_passed.contains(propertyId)) {
      _passed.add(propertyId);
    }
    // Remove from favourites if it was there
    _favourites.remove(propertyId);
  }

  @override
  Future<void> removeFromPassedProperties(String propertyId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _passed.remove(propertyId);
  }

  @override
  Future<UserModel> getUserProfile() async {
    if (_currentUser == null) {
      await _loadMockData();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (_currentUser == null) {
      throw Exception('User not found');
    }
    return _currentUser!;
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = user;
  }

  @override
  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(preferences: preferences);
    }
  }
} 