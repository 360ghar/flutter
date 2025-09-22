import 'package:flutter/material.dart';

import '../../../core/data/models/property_model.dart';
import '../../../core/utils/app_colors.dart';

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
    final textColor = theme.colorScheme.onPrimary;
    final backgroundColor = isSelected ? AppColors.primaryYellow : AppColors.accentBlue;
    final semanticLabel = property.title.isNotEmpty
        ? 'Property marker for ${property.title}'
        : 'Property marker';

    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RepaintBoundary(
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: textColor, width: 2),
              boxShadow: AppColors.getCardShadow(),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
