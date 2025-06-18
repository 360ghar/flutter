import 'package:get/get.dart';
import '../../../controllers/property_controller.dart';

class FavouritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.find<PropertyController>();
  }
} 