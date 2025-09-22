import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/data/models/agent_model.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';

class AgentCard extends StatelessWidget {
  final AgentModel agent;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  const AgentCard({
    super.key,
    required this.agent,
    this.onCall,
    this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryYellow.withValues(alpha: 0.08),
            AppColors.primaryYellow.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryYellow.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RobustNetworkImageExtension.avatar(
            imageUrl: agent.avatarUrl ?? '',
            size: 44,
            placeholder: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(Icons.person, size: 22, color: AppColors.iconColor),
            ),
            errorWidget: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(Icons.person, size: 22, color: AppColors.iconColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.support_agent,
                      color: AppColors.primaryYellow,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Your Relationship Manager'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  agent.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.primaryYellow),
                    const SizedBox(width: 3),
                    Text(
                      agent.userSatisfactionRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.work_outline,
                      size: 14,
                      color: AppColors.iconColor,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        agent.experienceLevelString,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CompactIconButton(
            icon: Icons.phone,
            tooltip: 'Call'.tr,
            foreground: AppColors.primaryYellow,
            background: AppColors.primaryYellow.withValues(alpha: 0.08),
            borderColor: AppColors.primaryYellow.withValues(alpha: 0.4),
            onTap: onCall ?? () {},
          ),
          const SizedBox(width: 8),
          _CompactIconButton(
            icon: Icons.message,
            tooltip: 'WhatsApp'.tr,
            foreground: AppColors.buttonText,
            background: AppColors.accentGreen,
            borderColor: AppColors.accentGreen,
            onTap: onWhatsApp ?? () {},
          ),
        ],
      ),
    );
  }
}

class _CompactIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color foreground;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  const _CompactIconButton({
    required this.icon,
    required this.tooltip,
    required this.foreground,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: foreground),
        ),
      ),
    );
  }
}
