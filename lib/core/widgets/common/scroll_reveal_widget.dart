import 'package:flutter/material.dart';

import 'package:ghar360/core/utils/app_spacing.dart';

/// Animates a child with fade + upward slide on first build.
/// Use [index] to stagger multiple sections (delay = index * [staggerDelay]).
class ScrollRevealWidget extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration staggerDelay;
  final Duration duration;
  final double slideOffset;

  const ScrollRevealWidget({
    super.key,
    required this.child,
    this.index = 0,
    this.staggerDelay = const Duration(milliseconds: 80),
    this.duration = AppDurations.normal,
    this.slideOffset = 0.05,
  });

  @override
  State<ScrollRevealWidget> createState() => _ScrollRevealWidgetState();
}

class _ScrollRevealWidgetState extends State<ScrollRevealWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: AppCurves.standard);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.standard));

    final delay = widget.staggerDelay * widget.index;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
