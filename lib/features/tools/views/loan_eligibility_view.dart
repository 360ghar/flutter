import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/features/tools/controllers/loan_eligibility_controller.dart';

class LoanEligibilityView extends GetView<LoanEligibilityController> {
  const LoanEligibilityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'loan_eligibility'.tr,
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
                      label: 'monthly_income'.tr,
                      controller: controller.incomeController,
                      prefix: '₹',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'your_age'.tr,
                      controller: controller.ageController,
                      suffix: 'years'.tr,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'existing_emi'.tr,
                      controller: controller.existingEmiController,
                      prefix: '₹',
                      hint: 'optional'.tr,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'credit_score'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Column(
                        children: [
                          Slider(
                            value: controller.creditScore.value,
                            min: 300,
                            max: 900,
                            divisions: 60,
                            activeColor: AppColors.primaryYellow,
                            inactiveColor: AppColors.inputBackground,
                            label: controller.creditScore.value.toInt().toString(),
                            onChanged: (value) => controller.creditScore.value = value,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '300',
                                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                              Text(
                                controller.creditScore.value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                              Text(
                                '900',
                                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'interest_rate'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Column(
                        children: [
                          Slider(
                            value: controller.interestRate.value,
                            min: 6.0,
                            max: 15.0,
                            divisions: 90,
                            activeColor: AppColors.primaryYellow,
                            inactiveColor: AppColors.inputBackground,
                            label: '${controller.interestRate.value.toStringAsFixed(1)}%',
                            onChanged: (value) => controller.interestRate.value = value,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '6%',
                                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                              Text(
                                '${controller.interestRate.value.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                              Text(
                                '15%',
                                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                        'eligibility_result'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildResultRow(
                        'max_loan_amount'.tr,
                        '₹${_formatCurrency(controller.maxLoanAmount.value)}',
                        isHighlight: true,
                      ),
                      const Divider(height: 24),
                      _buildResultRow(
                        'eligible_emi'.tr,
                        '₹${_formatCurrency(controller.eligibleEmi.value)}/mo',
                      ),
                      const SizedBox(height: 8),
                      _buildResultRow(
                        'max_tenure'.tr,
                        '${controller.maxTenure.value} ${'years'.tr}',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.accentBlue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'loan_eligibility_note'.tr,
                                style: const TextStyle(fontSize: 12, color: AppColors.accentBlue),
                              ),
                            ),
                          ],
                        ),
                      ),
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
          keyboardType: TextInputType.number,
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

  Widget _buildResultRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: isHighlight ? AppColors.primaryYellow : AppColors.textPrimary,
          ),
        ),
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
