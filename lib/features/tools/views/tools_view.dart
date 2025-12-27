import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/routes/app_routes.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/features/tools/controllers/tools_controller.dart';
import 'package:ghar360/features/tools/widgets/tool_card.dart';

class ToolsView extends GetView<ToolsController> {
  const ToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'tools_calculators'.tr,
          style: TextStyle(color: AppColors.appBarText, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.iconColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'tools_subtitle'.tr,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ToolCard(
              icon: Icons.square_foot,
              title: 'area_converter'.tr,
              description: 'area_converter_desc'.tr,
              onTap: () => Get.toNamed(AppRoutes.areaConverter),
            ),
            const SizedBox(height: 12),
            ToolCard(
              icon: Icons.account_balance,
              title: 'loan_eligibility'.tr,
              description: 'loan_eligibility_desc'.tr,
              onTap: () => Get.toNamed(AppRoutes.loanEligibility),
            ),
            const SizedBox(height: 12),
            ToolCard(
              icon: Icons.calculate,
              title: 'emi_calculator'.tr,
              description: 'emi_calculator_desc'.tr,
              onTap: () => Get.toNamed(AppRoutes.emiCalculator),
            ),
            const SizedBox(height: 12),
            ToolCard(
              icon: Icons.home_work,
              title: 'carpet_area_calculator'.tr,
              description: 'carpet_area_desc'.tr,
              onTap: () => Get.toNamed(AppRoutes.carpetArea),
            ),
            const SizedBox(height: 12),
            ToolCard(
              icon: Icons.checklist,
              title: 'document_checklist'.tr,
              description: 'document_checklist_desc'.tr,
              onTap: () => Get.toNamed(AppRoutes.documentChecklist),
            ),
            const SizedBox(height: 12),
            ToolCard(
              icon: Icons.receipt_long,
              title: 'capital_gains'.tr,
              description: 'capital_gains_desc'.tr,
              onTap: () => Get.toNamed(AppRoutes.capitalGains),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
