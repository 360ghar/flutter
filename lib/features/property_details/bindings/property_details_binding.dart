import 'package:get/get.dart';
import '../../visits/controllers/visits_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../../core/utils/controller_helper.dart';

class PropertyDetailsBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure PropertyController is available
    ControllerHelper.ensurePropertyController();
    
    Get.lazyPut<VisitsController>(() => VisitsController());
    Get.lazyPut<BookingController>(() => BookingController());
  }
} 