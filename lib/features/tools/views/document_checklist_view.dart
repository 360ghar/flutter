import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/features/tools/controllers/document_checklist_controller.dart';

class DocumentChecklistView extends GetView<DocumentChecklistController> {
  const DocumentChecklistView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        title: Text(
          'document_checklist'.tr,
          style: TextStyle(color: AppColors.appBarText, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.iconColor),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.iconColor),
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Obx(
            () => Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.cardBackground,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'progress'.tr,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${controller.checkedItems.value}/${controller.totalItems.value}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryYellow,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: controller.progress,
                      backgroundColor: AppColors.inputBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        controller.progress == 1.0
                            ? AppColors.accentGreen
                            : AppColors.primaryYellow,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.categories.length,
                itemBuilder: (context, index) {
                  final category = controller.categories[index];
                  return _buildCategorySection(category);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(DocumentCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.titleKey.tr,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: category.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == category.items.length - 1;
              return Column(
                children: [
                  _buildDocumentItem(item),
                  if (!isLast) Divider(height: 1, indent: 56, color: AppColors.divider),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDocumentItem(DocumentItem item) {
    return InkWell(
      onTap: () => controller.toggleItem(item.id),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.isChecked ? AppColors.accentGreen : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.isChecked ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.titleKey.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: item.isChecked ? AppColors.textSecondary : AppColors.textPrimary,
                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.descriptionKey.tr,
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('reset_checklist'.tr, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'reset_checklist_confirm'.tr,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () {
              controller.resetAll();
              Get.back();
            },
            child: Text('reset'.tr),
          ),
        ],
      ),
    );
  }
}
