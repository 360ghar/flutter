import 'package:get/get.dart';

import 'package:ghar360/features/location_search/controllers/location_search_controller.dart';

class LocationSearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LocationSearchController>(() => LocationSearchController());
  }
}
