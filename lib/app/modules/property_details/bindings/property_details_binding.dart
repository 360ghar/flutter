import 'package:get/get.dart';
import '../../../controllers/visits_controller.dart';
import '../../../controllers/booking_controller.dart';
import '../../../utils/controller_helper.dart';

class PropertyDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PropertyController is available
    ControllerHelper.ensurePropertyController();
    
    Get.lazyPut<VisitsController>(() => VisitsController());
    Get.lazyPut<BookingController>(() => BookingController());
  }
} 