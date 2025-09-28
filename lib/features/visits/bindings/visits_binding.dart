import 'package:get/get.dart';

import 'package:ghar360/features/visits/controllers/visits_controller.dart';

class VisitsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisitsController>(() => VisitsController());
  }
}
