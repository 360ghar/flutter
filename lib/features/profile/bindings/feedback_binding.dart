import 'package:get/get.dart';

import 'package:ghar360/core/data/repositories/support_repository.dart';
import 'package:ghar360/features/profile/controllers/feedback_controller.dart';

class FeedbackBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<SupportRepository>()) {
      Get.lazyPut<SupportRepository>(() => SupportRepository());
    }
    Get.lazyPut<FeedbackController>(() => FeedbackController());
  }
}
