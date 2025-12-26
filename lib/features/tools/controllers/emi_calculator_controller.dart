import 'dart:math';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

class EmiCalculatorController extends GetxController {
  final TextEditingController principalController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController tenureController = TextEditingController();

  final RxBool tenureInYears = true.obs;
  final RxBool hasCalculated = false.obs;

  // Results
  final RxDouble monthlyEmi = 0.0.obs;
  final RxDouble totalInterest = 0.0.obs;
  final RxDouble totalPayment = 0.0.obs;

  void calculate() {
    final principal = double.tryParse(principalController.text) ?? 0;
    final annualRate = double.tryParse(rateController.text) ?? 0;
    final tenure = int.tryParse(tenureController.text) ?? 0;

    if (principal <= 0 || annualRate <= 0 || tenure <= 0) {
      hasCalculated.value = false;
      return;
    }

    final months = tenureInYears.value ? tenure * 12 : tenure;
    final monthlyRate = annualRate / 12 / 100;

    // EMI = P * r * (1+r)^n / ((1+r)^n - 1)
    final factor = pow(1 + monthlyRate, months);
    final emi = principal * monthlyRate * factor / (factor - 1);

    monthlyEmi.value = emi;
    totalPayment.value = emi * months;
    totalInterest.value = totalPayment.value - principal;
    hasCalculated.value = true;
  }

  void toggleTenureUnit() {
    tenureInYears.value = !tenureInYears.value;
    if (hasCalculated.value) {
      calculate();
    }
  }

  void clear() {
    principalController.clear();
    rateController.clear();
    tenureController.clear();
    tenureInYears.value = true;
    hasCalculated.value = false;
    monthlyEmi.value = 0;
    totalInterest.value = 0;
    totalPayment.value = 0;
  }

  @override
  void onClose() {
    principalController.dispose();
    rateController.dispose();
    tenureController.dispose();
    super.onClose();
  }
}
