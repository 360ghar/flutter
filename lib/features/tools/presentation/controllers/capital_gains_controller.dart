import 'package:flutter/material.dart';

import 'package:get/get.dart';

class CapitalGainsController extends GetxController {
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController improvementCostController = TextEditingController();

  final RxInt purchaseYear = 2020.obs;
  final RxInt saleYear = 2024.obs;
  final RxBool hasCalculated = false.obs;

  // Results
  final RxBool isLongTerm = false.obs;
  final RxDouble indexedCost = 0.0.obs;
  final RxDouble capitalGain = 0.0.obs;
  final RxDouble taxWithIndexation = 0.0.obs;
  final RxDouble taxWithoutIndexation = 0.0.obs;

  // Cost Inflation Index (CII) values - updated for FY 2024-25
  static const Map<int, int> ciiValues = {
    2001: 100,
    2002: 105,
    2003: 109,
    2004: 113,
    2005: 117,
    2006: 122,
    2007: 129,
    2008: 137,
    2009: 148,
    2010: 167,
    2011: 184,
    2012: 200,
    2013: 220,
    2014: 240,
    2015: 254,
    2016: 264,
    2017: 272,
    2018: 280,
    2019: 289,
    2020: 301,
    2021: 317,
    2022: 331,
    2023: 348,
    2024: 363,
    2025: 363, // Using 2024 value as 2025 not yet announced
  };

  List<int> get availableYears => List.generate(25, (i) => 2001 + i);

  void calculate() {
    final purchasePrice = double.tryParse(purchasePriceController.text) ?? 0;
    final salePrice = double.tryParse(salePriceController.text) ?? 0;
    final improvementCost = double.tryParse(improvementCostController.text) ?? 0;

    if (purchasePrice <= 0 || salePrice <= 0) {
      hasCalculated.value = false;
      return;
    }

    // Check if long-term (held for more than 24 months)
    final holdingMonths = (saleYear.value - purchaseYear.value) * 12;
    isLongTerm.value = holdingMonths > 24;

    if (isLongTerm.value) {
      // Long-term capital gains calculation
      final purchaseCii = ciiValues[purchaseYear.value] ?? 301;
      final saleCii = ciiValues[saleYear.value] ?? 363;

      // Indexed cost = Purchase price * (Sale CII / Purchase CII)
      final indexedPurchase = purchasePrice * saleCii / purchaseCii;
      final indexedImprovement = improvementCost * saleCii / purchaseCii;
      indexedCost.value = indexedPurchase + indexedImprovement;

      // Capital gain with indexation
      final gainWithIndexation = salePrice - indexedCost.value;
      capitalGain.value = gainWithIndexation > 0 ? gainWithIndexation : 0;

      // Tax calculation (post Budget 2024)
      // Option 1: 20% with indexation (old regime, grandfathered)
      // Option 2: 12.5% without indexation (new regime)
      taxWithIndexation.value = capitalGain.value * 0.20;

      // Without indexation
      final gainWithoutIndexation = salePrice - purchasePrice - improvementCost;
      taxWithoutIndexation.value = (gainWithoutIndexation > 0 ? gainWithoutIndexation : 0) * 0.125;
    } else {
      // Short-term: Added to income, taxed at slab rates
      // Using 30% as highest slab for estimation
      indexedCost.value = purchasePrice + improvementCost;
      capitalGain.value = salePrice - indexedCost.value;
      if (capitalGain.value < 0) capitalGain.value = 0;

      // Estimate at 30% slab
      taxWithIndexation.value = capitalGain.value * 0.30;
      taxWithoutIndexation.value = capitalGain.value * 0.30;
    }

    hasCalculated.value = true;
  }

  void clear() {
    purchasePriceController.clear();
    salePriceController.clear();
    improvementCostController.clear();
    purchaseYear.value = 2020;
    saleYear.value = 2024;
    hasCalculated.value = false;
    isLongTerm.value = false;
    indexedCost.value = 0;
    capitalGain.value = 0;
    taxWithIndexation.value = 0;
    taxWithoutIndexation.value = 0;
  }

  @override
  void onClose() {
    purchasePriceController.dispose();
    salePriceController.dispose();
    improvementCostController.dispose();
    super.onClose();
  }
}
