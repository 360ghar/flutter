import 'package:get/get.dart';

import 'package:ghar360/core/data/models/user_model.dart';
import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/network/api_paths.dart';
import 'package:ghar360/core/network/response_parser.dart';
import 'package:ghar360/core/utils/app_exceptions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Repository for managing user profile operations
/// Handles all profile-related API calls and data management
class ProfileRepository extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  /// Updates the user profile on the backend
  Future<UserModel> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      DebugLogger.info('👤 Updating user profile with data: ${profileData.keys.join(', ')}');
      final response = await _apiClient.put(ApiPaths.usersProfile, body: profileData);
      final updatedUser = _parseUser(response.body);
      DebugLogger.success('✅ Profile updated successfully');
      return updatedUser;
    } on AppException catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to update user profile: ${e.message}', e, stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error updating user profile: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Updates the user's location on the backend (fire-and-forget, no profile refetch)
  Future<void> updateUserLocation(Map<String, dynamic> locationData) async {
    try {
      DebugLogger.info('📍 Updating user location');
      final lat = locationData['current_latitude'] as double?;
      final lon = locationData['current_longitude'] as double?;
      if (lat != null && lon != null) {
        await _apiClient.put(ApiPaths.usersLocation, body: {'latitude': lat, 'longitude': lon});
        DebugLogger.success('✅ Location updated successfully');
      }
    } on AppException catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to update user location: ${e.message}', e, stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error updating user location: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Updates the user's preferences on the backend
  Future<UserModel> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      DebugLogger.info('⚙️ Updating user preferences');
      await _apiClient.put(ApiPaths.usersPreferences, body: preferences);
      // Refetch profile to get the most up-to-date user model
      return await getCurrentUserProfile();
    } on AppException catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to update user preferences: ${e.message}', e, stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error updating user preferences: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Gets the current user profile from the backend
  Future<UserModel> getCurrentUserProfile() async {
    try {
      DebugLogger.info('👤 Fetching current user profile');
      final response = await _apiClient.get(ApiPaths.usersProfile, useCache: false, dedupe: false);
      final user = _parseUser(response.body);
      DebugLogger.success('✅ User profile fetched successfully');
      return user;
    } on AppException catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to fetch user profile: ${e.message}', e, stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error fetching user profile: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Calculates the profile completion percentage
  int calculateProfileCompletion(UserModel user) {
    // Create a list of completion conditions for each field
    final completionChecks = [
      user.fullName?.isNotEmpty == true,
      user.email.isNotEmpty,
      user.phone?.isNotEmpty == true,
      user.dateOfBirth?.isNotEmpty == true,
      user.profileImageUrl?.isNotEmpty == true,
      // Add more profile field checks as needed
      // Example additional fields:
      // user.address?.isNotEmpty == true,
      // user.city?.isNotEmpty == true,
      // user.occupation?.isNotEmpty == true,
      // user.bio?.isNotEmpty == true,
      // user.preferences != null,
    ];

    // Count the number of true conditions
    final completed = completionChecks.where((check) => check).length;
    final total = completionChecks.length;

    return ((completed / total) * 100).round();
  }

  /// Checks if the user profile is complete based on required fields
  bool isProfileComplete(UserModel user) {
    return user.isProfileComplete;
  }

  /// Updates a specific profile field
  Future<UserModel> updateProfileField(String field, dynamic value) async {
    return await updateUserProfile({field: value});
  }

  /// Uploads and updates user profile image
  Future<UserModel> updateProfileImage(String imagePath) async {
    try {
      DebugLogger.info('📸 Updating user profile image');
      // This would typically involve uploading the image first, then updating the profile
      // For now, we'll assume the imagePath is already a URL or the API handles the upload
      final updatedUser = await updateUserProfile({'profile_image_url': imagePath});
      DebugLogger.success('✅ Profile image updated successfully');
      return updatedUser;
    } on AppException catch (e, stackTrace) {
      DebugLogger.error('❌ Failed to update profile image: ${e.message}', e, stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error updating profile image: $e', e, stackTrace);
      rethrow;
    }
  }

  UserModel _parseUser(dynamic raw) {
    final payload = ResponseParser.unwrapObject(raw);
    if (payload.isEmpty) {
      throw const FormatException('Unexpected user response payload');
    }

    payload['email'] ??= '';
    payload['phone'] ??= '';
    if (payload['preferences'] is! Map<String, dynamic>) {
      payload['preferences'] = <String, dynamic>{};
    }

    return UserModel.fromJson(payload);
  }
}
