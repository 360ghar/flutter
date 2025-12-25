import 'package:ghar360/core/data/models/user_model.dart';
import 'package:ghar360/core/network/api_client.dart';
import 'package:ghar360/core/utils/debug_logger.dart';

/// Remote datasource for authentication operations.
class AuthRemoteDatasource {
  final ApiClient _apiClient;

  AuthRemoteDatasource(this._apiClient);

  /// Sends OTP to the given phone number.
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    DebugLogger.debug('📱 Sending OTP to $phoneNumber');
    final response = await _apiClient.post('/auth/send-otp', body: {'phone_number': phoneNumber});
    return response.body as Map<String, dynamic>;
  }

  /// Verifies OTP and returns user data.
  Future<UserModel> verifyOTP(String phoneNumber, String otp) async {
    DebugLogger.debug('🔐 Verifying OTP for $phoneNumber');
    final response = await _apiClient.post(
      '/auth/verify-otp',
      body: {'phone_number': phoneNumber, 'otp': otp},
    );
    return UserModel.fromJson(response.body as Map<String, dynamic>);
  }

  /// Fetches the current user profile.
  Future<UserModel> fetchUserProfile() async {
    DebugLogger.debug('👤 Fetching user profile');
    final response = await _apiClient.get('/auth/profile');
    return UserModel.fromJson(response.body as Map<String, dynamic>);
  }

  /// Updates the user profile.
  Future<UserModel> updateUserProfile(Map<String, dynamic> updates) async {
    DebugLogger.debug('📝 Updating user profile');
    final response = await _apiClient.put('/auth/profile', body: updates);
    return UserModel.fromJson(response.body as Map<String, dynamic>);
  }

  /// Completes user profile with additional details.
  Future<UserModel> completeProfile(Map<String, dynamic> profileData) async {
    DebugLogger.debug('✅ Completing user profile');
    final response = await _apiClient.post('/auth/complete-profile', body: profileData);
    return UserModel.fromJson(response.body as Map<String, dynamic>);
  }
}
