import 'package:flutter/material.dart';

import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
import 'package:ghar360/core/widgets/common/animated_tap_wrapper.dart';

class ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? qaKey;

  const ToolCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.qaKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppDesignTokens.brandGold.withValues(alpha: 0.08)
        : AppDesignTokens.brandGoldSubtle;

    return AnimatedTapWrapper(
      onTap: onTap,
      child: Semantics(
        label: qaKey,
        identifier: qaKey,
        hint: description,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            key: qaKey != null ? ValueKey(qaKey) : null,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, weight: 100, color: AppDesignTokens.brandGoldDark),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppDesign.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
