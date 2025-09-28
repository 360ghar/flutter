import 'package:flutter/material.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/utils/app_colors.dart';

class PropertyMarkerChip extends StatelessWidget {
  final PropertyModel property;
  final bool isSelected;
  final VoidCallback onTap;
  final String label;

  const PropertyMarkerChip({
    super.key,
    required this.property,
    required this.isSelected,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool selected = isSelected;
    final Color bg = selected ? AppColors.primaryYellow : AppColors.surface;
    final Color border = selected ? AppColors.accentOrange : AppColors.accentBlue;
    final Color text = selected ? Colors.black : AppColors.textPrimary;

    final semanticLabel = property.title.isNotEmpty
        ? 'Property price marker for ${property.title}'
        : 'Property price marker';

    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: 1.5),
              boxShadow: AppColors.getCardShadow(),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              style: theme.textTheme.labelMedium?.copyWith(
                color: text,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
