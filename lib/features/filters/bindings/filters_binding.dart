import 'package:get/get.dart';
// FiltersController has been consolidated into FilterService
// which is now registered globally in InitialBinding

class FiltersBinding extends Bindings {
  @override
  void dependencies() {
    // No dependencies needed - FilterService is globally available
    // This binding is kept for compatibility but does nothing
  }
}