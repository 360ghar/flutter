import 'package:get/get.dart';

import 'package:ghar360/features/assistant/data/assistant_repository.dart';
import 'package:ghar360/features/assistant/presentation/controllers/assistant_controller.dart';

class AssistantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AssistantRepository>(() => AssistantRepository(), fenix: true);
    Get.lazyPut<AssistantController>(() => AssistantController(), fenix: true);
  }
}
