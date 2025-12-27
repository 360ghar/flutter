import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/features/tools/controllers/emi_calculator_controller.dart';

class EmiCalculatorView extends GetView<EmiCalculatorController> {
  const EmiCalculatorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'emi_calculator'.tr,
          style: TextStyle(color: AppColors.appBarText, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.iconColor),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.iconColor),
            onPressed: controller.clear,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      label: 'loan_amount'.tr,
                      controller: controller.principalController,
                      prefix: '₹',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'interest_rate'.tr,
                      controller: controller.rateController,
                      suffix: '%',
                      hint: 'annual_rate'.tr,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'tenure'.tr,
                            controller: controller.tenureController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Obx(
                          () => Column(
                            children: [
                              const SizedBox(height: 24),
                              SegmentedButton<bool>(
                                segments: [
                                  ButtonSegment(value: true, label: Text('years'.tr)),
                                  ButtonSegment(value: false, label: Text('months'.tr)),
                                ],
                                selected: {controller.tenureInYears.value},
                                onSelectionChanged: (value) {
                                  controller.tenureInYears.value = value.first;
                                },
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return AppColors.primaryYellow;
                                    }
                                    return AppColors.inputBackground;
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: controller.calculate, child: Text('calculate'.tr)),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (!controller.hasCalculated.value) {
                return const SizedBox.shrink();
              }
              return Card(
                color: AppColors.cardBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'emi_result'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'monthly_emi'.tr,
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${_formatCurrency(controller.monthlyEmi.value)}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryYellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildResultRow(
                        'total_interest'.tr,
                        '₹${_formatCurrency(controller.totalInterest.value)}',
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'total_payment'.tr,
                        '₹${_formatCurrency(controller.totalPayment.value)}',
                      ),
                      const SizedBox(height: 16),
                      _buildBreakdownChart(),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? suffix,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            prefixText: prefix,
            prefixStyle: TextStyle(color: AppColors.textPrimary),
            suffixText: suffix,
            suffixStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildBreakdownChart() {
    final principal = double.tryParse(controller.principalController.text) ?? 0;
    final interest = controller.totalInterest.value;
    final total = principal + interest;
    if (total == 0) return const SizedBox.shrink();

    final principalPercent = (principal / total * 100).toStringAsFixed(0);
    final interestPercent = (interest / total * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'breakdown'.tr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Expanded(
                flex: principal.toInt(),
                child: Container(
                  height: 24,
                  color: AppColors.accentGreen,
                  alignment: Alignment.center,
                  child: Text(
                    '$principalPercent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: interest.toInt(),
                child: Container(
                  height: 24,
                  color: AppColors.accentOrange,
                  alignment: Alignment.center,
                  child: Text(
                    '$interestPercent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLegendItem(AppColors.accentGreen, 'principal'.tr),
            const SizedBox(width: 16),
            _buildLegendItem(AppColors.accentOrange, 'interest'.tr),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}
