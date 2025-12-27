import 'package:flutter/material.dart';

import 'package:ghar360/core/utils/app_spacing.dart';

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final int trigger;
  final double offset;
  final Duration duration;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.trigger,
    this.offset = 12,
    this.duration = AppDurations.normal,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int _lastTrigger = 0;

  @override
  void initState() {
    super.initState();
    _lastTrigger = widget.trigger;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -widget.offset), weight: 1),
      TweenSequenceItem(
        tween: Tween(begin: -widget.offset, end: widget.offset),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.offset, end: -widget.offset),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -widget.offset, end: widget.offset),
        weight: 2,
      ),
      TweenSequenceItem(tween: Tween(begin: widget.offset, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != _lastTrigger) {
      _lastTrigger = widget.trigger;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(offset: Offset(_animation.value, 0), child: child);
      },
      child: widget.child,
    );
  }
}
