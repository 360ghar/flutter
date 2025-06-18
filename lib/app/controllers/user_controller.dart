import 'package:get/get.dart';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

class UserController extends GetxController {
  final UserRepository _repository;
  
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  UserController(this._repository);

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      error.value = '';
      final result = await _repository.getUserProfile();
      user.value = result;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _repository.updateUserProfile(updatedUser);
      user.value = updatedUser;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      isLoading.value = true;
      error.value = '';
      await _repository.updateUserPreferences(preferences);
      if (user.value != null) {
        user.value = user.value!.copyWith(preferences: preferences);
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    user.value = null;
    Get.offAllNamed('/login');
    Get.snackbar(
      'Logged Out',
      'You have been successfully logged out',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
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