import 'package:get/get.dart';
import '../controllers/profile_completion_controller.dart';

class ProfileCompletionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileCompletionController>(
      () => ProfileCompletionController(),
    );
  }
}
