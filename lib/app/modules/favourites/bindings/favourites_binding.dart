import 'package:get/get.dart';
import '../../../utils/controller_helper.dart';

class FavouritesBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PropertyController is available
    ControllerHelper.ensurePropertyController();
  }
} 