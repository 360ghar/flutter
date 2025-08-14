import 'package:get/get.dart';
import '../controllers/filters_controller.dart';

class FiltersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FiltersController>(
      () => FiltersController(),
      fenix: true,
    );
  }
}