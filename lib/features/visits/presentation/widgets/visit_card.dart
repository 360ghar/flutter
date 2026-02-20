import 'package:flutter/material.dart';

import 'package:ghar360/core/data/models/visit_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';

class VisitCard extends StatelessWidget {
  final VisitModel visit;
  final bool isUpcoming;
  final String dateText;
  final String timeText;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback? onTap;

  const VisitCard({
    super.key,
    required this.visit,
    required this.isUpcoming,
    required this.dateText,
    required this.timeText,
    required this.onReschedule,
    required this.onCancel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    DebugLogger.info(
      '🔖 Building VisitCard id=${visit.id} status=${visit.status} date=${visit.scheduledDate.toIso8601String()}',
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppDesign.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RobustNetworkImage(
                      imageUrl: visit.property?.mainImage ?? visit.property?.mainImageUrl ?? '',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(8),
                      errorWidget: Container(
                        width: 64,
                        height: 64,
                        color: AppDesign.inputBackground,
                        child: Icon(Icons.image, color: AppDesign.iconColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  visit.property?.title ?? visit.propertyTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppDesign.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusChip(visit.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (visit.property != null) ...[
                            Text(
                              visit.property!.addressDisplay,
                              style: TextStyle(fontSize: 13, color: AppDesign.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              [
                                if (visit.property!.bedrooms != null)
                                  '${visit.property!.bedrooms}BHK',
                                if (visit.property!.bathrooms != null)
                                  '${visit.property!.bathrooms}B',
                                if (visit.property!.areaSqft != null)
                                  '${visit.property!.areaSqft!.toStringAsFixed(0)} sqft',
                              ].join(' • '),
                              style: TextStyle(fontSize: 12, color: AppDesign.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 2,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppDesign.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateText,
                                    style: TextStyle(fontSize: 13, color: AppDesign.textSecondary),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 14, color: AppDesign.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeText,
                                    style: TextStyle(fontSize: 13, color: AppDesign.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (visit.property != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    visit.property!.formattedPrice,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppDesign.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  visit.property!.purposeString,
                  style: TextStyle(fontSize: 12, color: AppDesign.textSecondary),
                ),
              ],
            ),
          ],
          if (isUpcoming && (visit.canCancel || visit.canReschedule)) ...[
            const SizedBox(height: 12),
            if ((visit.specialRequirements ?? '').isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: AppDesign.iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      visit.specialRequirements!,
                      style: TextStyle(fontSize: 12, color: AppDesign.textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReschedule,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppDesign.primaryYellow),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(color: AppDesign.primaryYellow, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppDesign.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppDesign.errorRed, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(VisitStatus status) {
    Color color;
    String text;

    switch (status) {
      case VisitStatus.scheduled:
        color = AppDesign.primaryYellow;
        text = 'Scheduled';
        break;
      case VisitStatus.confirmed:
        color = AppDesign.accentGreen;
        text = 'Confirmed';
        break;
      case VisitStatus.completed:
        color = AppDesign.accentGreen;
        text = 'Completed';
        break;
      case VisitStatus.cancelled:
        color = AppDesign.errorRed;
        text = 'Cancelled';
        break;
      case VisitStatus.rescheduled:
        color = AppDesign.primaryYellow;
        text = 'Rescheduled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text.length > 6 ? text.substring(0, 6) : text,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }
}
