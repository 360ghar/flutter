import 'package:get/get.dart';
import '../controllers/visits_controller.dart';

class VisitsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisitsController>(() => VisitsController());
  }
} 