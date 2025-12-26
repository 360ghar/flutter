import 'package:get/get.dart';

import 'package:ghar360/features/tools/controllers/area_converter_controller.dart';
import 'package:ghar360/features/tools/controllers/capital_gains_controller.dart';
import 'package:ghar360/features/tools/controllers/carpet_area_controller.dart';
import 'package:ghar360/features/tools/controllers/document_checklist_controller.dart';
import 'package:ghar360/features/tools/controllers/emi_calculator_controller.dart';
import 'package:ghar360/features/tools/controllers/loan_eligibility_controller.dart';
import 'package:ghar360/features/tools/controllers/tools_controller.dart';

class ToolsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ToolsController>(() => ToolsController());
  }
}

class AreaConverterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AreaConverterController>(() => AreaConverterController());
  }
}

class LoanEligibilityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoanEligibilityController>(() => LoanEligibilityController());
  }
}

class EmiCalculatorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmiCalculatorController>(() => EmiCalculatorController());
  }
}

class CarpetAreaBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CarpetAreaController>(() => CarpetAreaController());
  }
}

class DocumentChecklistBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DocumentChecklistController>(() => DocumentChecklistController());
  }
}

class CapitalGainsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CapitalGainsController>(() => CapitalGainsController());
  }
}
