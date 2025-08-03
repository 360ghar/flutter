import 'package:get/get.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';
import '../data/providers/api_service.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  final UserRepository _repository;
  late final ApiService _apiService;
  late final AuthController _authController;
  
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isUpdatingProfile = false.obs;
  final RxString error = ''.obs;
  
  // Notification settings
  final RxMap<String, bool> notificationSettings = <String, bool>{
    'email_notifications': true,
    'push_notifications': true,
    'visit_reminders': true,
    'price_alerts': false,
    'new_properties': true,
  }.obs;

  UserController(this._repository);

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _authController = Get.find<AuthController>();
    _initializeController();
  }

  Future<void> _initializeController() async {
    // Listen to auth state changes
    ever(_authController.currentUser, (UserModel? user) {
      if (user != null) {
        this.user.value = user;
        _loadNotificationSettings();
      } else {
        this.user.value = null;
        _resetNotificationSettings();
      }
    });

    // Initial load
    await fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      error.value = '';
      
      if (_authController.isAuthenticated) {
        // Get user from auth controller (which gets it from API)
        await _authController.refreshUserProfile();
        user.value = _authController.currentUser.value;
      } else {
        // Fallback to repository
        final result = await _repository.getUserProfile();
        user.value = result;
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Failed to fetch user profile', snackPosition: SnackPosition.TOP);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    try {
      isUpdatingProfile.value = true;
      error.value = '';
      
      if (_authController.isAuthenticated) {
        final success = await _authController.updateUserProfile(profileData);
        if (success) {
          user.value = _authController.currentUser.value;
        }
        return success;
      } else {
        // Fallback to repository
        final updatedUser = UserModel.fromJson({
          ...user.value?.toJson() ?? {},
          ...profileData,
        });
        await _repository.updateUserProfile(updatedUser);
        user.value = updatedUser;
        return true;
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Failed to update profile', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      isUpdatingProfile.value = false;
    }
  }

  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      isLoading.value = true;
      error.value = '';
      
      if (_authController.isAuthenticated) {
        final success = await _authController.updateUserPreferences(preferences);
        if (success && user.value != null) {
          user.value = user.value!.copyWith(preferences: preferences);
        }
        return success;
      } else {
        // Fallback to repository
        await _repository.updateUserPreferences(preferences);
        if (user.value != null) {
          user.value = user.value!.copyWith(preferences: preferences);
        }
        return true;
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Error', 'Failed to update preferences', snackPosition: SnackPosition.TOP);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      if (_authController.isAuthenticated) {
        final profileData = {
          'notification_settings': settings,
        };
        
        final success = await updateProfile(profileData);
        if (success) {
          notificationSettings.addAll(settings);
        }
        return success;
      } else {
        // Store locally for non-authenticated users
        notificationSettings.addAll(settings);
        return true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update notification settings', snackPosition: SnackPosition.TOP);
      return false;
    }
  }

  void _loadNotificationSettings() {
    if (user.value?.toJson()['notification_settings'] != null) {
      final settings = Map<String, bool>.from(
        user.value!.toJson()['notification_settings'] as Map
      );
      notificationSettings.addAll(settings);
    }
  }

  void _resetNotificationSettings() {
    notificationSettings.assignAll({
      'email_notifications': true,
      'push_notifications': true,
      'visit_reminders': true,
      'price_alerts': false,
      'new_properties': true,
    });
  }

  Future<void> logout() async {
    try {
      await _authController.signOut();
      user.value = null;
      _resetNotificationSettings();
    } catch (e) {
      Get.snackbar('Error', 'Logout failed', snackPosition: SnackPosition.TOP);
    }
  }

  // Profile picture upload
  Future<bool> updateProfilePicture(String imageUrl) async {
    return await updateProfile({
      'profile_image_url': imageUrl,
    });
  }

  // Account deletion
  Future<bool> deleteAccount() async {
    try {
      await _authController.deleteAccount();
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete account', snackPosition: SnackPosition.TOP);
      return false;
    }
  }

  bool get isLoggedIn => user.value != null;
  
  Map<String, dynamic>? get preferences => user.value?.preferences;

  RxInt get profileCompletionPercentage {
    if (user.value == null) return 0.obs;
    
    int completedFields = 0;
    int totalFields = 4; // name, email, phone, profileImage
    
    final currentUser = user.value!;
    
    if (currentUser.name.isNotEmpty) completedFields++;
    if (currentUser.email.isNotEmpty) completedFields++;
    if (currentUser.phone != null && currentUser.phone!.isNotEmpty) completedFields++;
    if (currentUser.profileImage != null && currentUser.profileImage!.isNotEmpty) completedFields++;
    
    return ((completedFields / totalFields) * 100).round().obs;
  }
} 