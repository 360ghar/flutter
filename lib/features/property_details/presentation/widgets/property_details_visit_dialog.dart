import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/features/visits/presentation/controllers/visits_controller.dart';

/// Shows a dialog for scheduling a property visit with date picker and notes.
void showBookVisitDialog(
  BuildContext context,
  PropertyModel property,
  VisitsController visitsController,
) {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  const defaultHour = 10;
  const defaultMinute = 0;
  final TextEditingController notesController = TextEditingController();

  Get.dialog(
    AlertDialog(
      backgroundColor: AppDesign.surface,
      title: Text('schedule_visit'.tr, style: TextStyle(color: AppDesign.textPrimary)),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'schedule_visit_to'.trParams({'property': property.title}),
                style: TextStyle(fontSize: 16, color: AppDesign.textSecondary),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.calendar_today, color: AppDesign.primaryYellow),
                title: Text('date'.tr, style: TextStyle(color: AppDesign.textPrimary)),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: TextStyle(color: AppDesign.textSecondary),
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'special_requirements_label'.tr,
                  hintText: 'special_requirements_hint'.tr,
                  filled: true,
                  fillColor: AppDesign.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppDesign.border),
                  ),
                ),
                style: TextStyle(color: AppDesign.textPrimary),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr, style: TextStyle(color: AppDesign.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (visitsController.isBookingVisit.value) return;

            final visitDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              defaultHour,
              defaultMinute,
            );

            final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();

            final didBook = await visitsController.bookVisit(property, visitDateTime, notes: notes);
            if (didBook && (Get.isDialogOpen ?? false)) {
              Get.back();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesign.primaryYellow,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text('schedule_visit'.tr),
        ),
      ],
    ),
  );
}
