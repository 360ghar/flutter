import 'dart:ui';

import 'package:flutter/material.dart';

class FrostedGlassContainer extends StatelessWidget {
  const FrostedGlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.12,
    this.borderRadius = 20.0,
    this.borderOpacity = 0.2,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.tintColor,
    this.gradient,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final double borderOpacity;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTint = isDark ? Colors.white : Colors.black;
    final effectiveTintColor = tintColor ?? defaultTint;
    final effectiveBorderOpacity = borderOpacity.clamp(0.0, 1.0);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: effectiveTintColor.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.white).withValues(
                alpha: effectiveBorderOpacity,
              ),
              width: 1,
            ),
            gradient: gradient,
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
