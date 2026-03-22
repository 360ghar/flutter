import 'package:flutter/material.dart';

import 'package:get/get.dart';

class CarpetAreaController extends GetxController {
  final TextEditingController superBuiltUpController = TextEditingController();
  final RxDouble loadingPercentage = 25.0.obs;
  final RxBool hasCalculated = false.obs;

  // Results
  final RxDouble carpetArea = 0.0.obs;
  final RxDouble builtUpArea = 0.0.obs;
  final RxDouble usablePercentage = 0.0.obs;

  void calculate() {
    final superBuiltUp = double.tryParse(superBuiltUpController.text) ?? 0;

    if (superBuiltUp <= 0) {
      hasCalculated.value = false;
      return;
    }

    // Super built-up includes common areas (loading)
    // Built-up = Super built-up - common area loading
    // Carpet = Built-up - wall thickness (typically 10-15%)

    final loading = loadingPercentage.value / 100;
    final builtUp = superBuiltUp / (1 + loading);

    // Wall thickness typically reduces by 10-15%
    const wallThicknessReduction = 0.12;
    final carpet = builtUp * (1 - wallThicknessReduction);

    builtUpArea.value = builtUp;
    carpetArea.value = carpet;
    usablePercentage.value = (carpet / superBuiltUp) * 100;
    hasCalculated.value = true;
  }

  void onLoadingChanged(double value) {
    loadingPercentage.value = value;
    if (hasCalculated.value) {
      calculate();
    }
  }

  void clear() {
    superBuiltUpController.clear();
    loadingPercentage.value = 25.0;
    hasCalculated.value = false;
    carpetArea.value = 0;
    builtUpArea.value = 0;
    usablePercentage.value = 0;
  }

  @override
  void onClose() {
    superBuiltUpController.dispose();
    super.onClose();
  }
}
