import 'package:get/get.dart';
import '../providers/api_provider.dart';
import '../models/user_model.dart';

class UserRepository extends GetxService {
  final IApiProvider _apiProvider;

  UserRepository(this._apiProvider);

  Future<UserModel> getUserProfile() async {
    try {
      return await _apiProvider.getUserProfile();
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _apiProvider.updateUserProfile(user);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      await _apiProvider.updateUserPreferences(preferences);
    } catch (e) {
      throw Exception('Failed to update user preferences: $e');
    }
  }
} 