import 'package:flutter/material.dart';

import '../../../core/data/models/visit_model.dart';
import '../../../core/utils/app_colors.dart';
import '../../../widgets/common/robust_network_image.dart';

class VisitCard extends StatelessWidget {
  final VisitModel visit;
  final bool isUpcoming;
  final String dateText;
  final String timeText;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  const VisitCard({
    super.key,
    required this.visit,
    required this.isUpcoming,
    required this.dateText,
    required this.timeText,
    required this.onReschedule,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.getCardShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepaintBoundary(
                child: RobustNetworkImage(
                  imageUrl:
                      visit.property?.mainImage ??
                      visit.property?.mainImageUrl ??
                      '',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(8),
                  errorWidget: Container(
                    width: 64,
                    height: 64,
                    color: AppColors.inputBackground,
                    child: Icon(Icons.image, color: AppColors.iconColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visit.property?.title ?? visit.propertyTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (visit.property != null) ...[
                      Text(
                        visit.property!.addressDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (visit.property!.bedrooms != null) ...[
                            Icon(
                              Icons.bed,
                              size: 14,
                              color: AppColors.iconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${visit.property!.bedrooms} BHK',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (visit.property!.bathrooms != null) ...[
                            Icon(
                              Icons.bathtub_outlined,
                              size: 14,
                              color: AppColors.iconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${visit.property!.bathrooms} Bath',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (visit.property!.areaSqft != null) ...[
                            Icon(
                              Icons.square_foot,
                              size: 14,
                              color: AppColors.iconColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${visit.property!.areaSqft!.toStringAsFixed(0)} sq ft',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusChip(visit.status),
            ],
          ),

          if (visit.property != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  visit.property!.formattedPrice,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  visit.property!.purposeString,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          if (isUpcoming && visit.status == VisitStatus.scheduled) ...[
            const SizedBox(height: 12),
            if ((visit.specialRequirements ?? '').isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: AppColors.iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      visit.specialRequirements!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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
                      side: BorderSide(color: AppColors.primaryYellow),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Reschedule',
                      style: TextStyle(
                        color: AppColors.primaryYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
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
        color = AppColors.primaryYellow;
        text = 'Scheduled';
        break;
      case VisitStatus.confirmed:
        color = AppColors.accentGreen;
        text = 'Confirmed';
        break;
      case VisitStatus.completed:
        color = AppColors.accentGreen;
        text = 'Completed';
        break;
      case VisitStatus.cancelled:
        color = AppColors.errorRed;
        text = 'Cancelled';
        break;
      case VisitStatus.rescheduled:
        color = AppColors.primaryYellow;
        text = 'Rescheduled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
