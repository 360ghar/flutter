import 'package:get/get.dart';

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();
  
  final RxInt tabIndex = 0.obs;
  
  void changeTabIndex(int index) {
    tabIndex.value = index;
  }
  
  @override
  void onInit() {
    super.onInit();
  }
}