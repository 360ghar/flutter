import 'package:get/get.dart';

class DashboardController extends GetxController {
  static DashboardController get to => Get.find();
  
  final RxInt currentIndex = 0.obs;
  
  void changeTab(int index) {
    currentIndex.value = index;
  }
  
}