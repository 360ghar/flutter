import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/features/tools/controllers/carpet_area_controller.dart';

class CarpetAreaView extends GetView<CarpetAreaController> {
  const CarpetAreaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'carpet_area_calculator'.tr,
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.accentBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'carpet_area_info'.tr,
                      style: const TextStyle(fontSize: 13, color: AppColors.accentBlue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'super_built_up_area'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller.superBuiltUpController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'enter_area_sqft'.tr,
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        suffixText: 'sq_ft'.tr,
                        suffixStyle: TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'loading_percentage'.tr,
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
                            value: controller.loadingPercentage.value,
                            min: 15,
                            max: 40,
                            divisions: 25,
                            activeColor: AppColors.primaryYellow,
                            inactiveColor: AppColors.inputBackground,
                            label: '${controller.loadingPercentage.value.toInt()}%',
                            onChanged: controller.onLoadingChanged,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '15%',
                                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              ),
                              Text(
                                '${controller.loadingPercentage.value.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryYellow,
                                ),
                              ),
                              Text(
                                '40%',
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
                        'area_breakdown'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildAreaCard(
                        'carpet_area'.tr,
                        controller.carpetArea.value,
                        AppColors.accentGreen,
                        'actual_usable_space'.tr,
                      ),
                      const SizedBox(height: 12),
                      _buildAreaCard(
                        'built_up_area'.tr,
                        controller.builtUpArea.value,
                        AppColors.accentBlue,
                        'carpet_plus_walls'.tr,
                      ),
                      const SizedBox(height: 12),
                      _buildAreaCard(
                        'super_built_up'.tr,
                        double.tryParse(controller.superBuiltUpController.text) ?? 0,
                        AppColors.accentOrange,
                        'includes_common_areas'.tr,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pie_chart, color: AppColors.primaryYellow, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'usable_area'.tr,
                                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    '${controller.usablePercentage.value.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryYellow,
                                    ),
                                  ),
                                ],
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

  Widget _buildAreaCard(String title, double value, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} ${'sq_ft'.tr}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
