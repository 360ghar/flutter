import 'package:flutter/material.dart';

import 'package:ghar360/core/utils/app_spacing.dart';

/// A widget that smoothly transitions between loading and content states
class AnimatedContentSwitcher extends StatelessWidget {
  final bool isLoading;
  final Widget loadingWidget;
  final Widget contentWidget;
  final Duration duration;
  final Curve switchInCurve;
  final Curve switchOutCurve;

  const AnimatedContentSwitcher({
    super.key,
    required this.isLoading,
    required this.loadingWidget,
    required this.contentWidget,
    this.duration = AppDurations.normal,
    this.switchInCurve = Curves.easeOut,
    this.switchOutCurve = Curves.easeIn,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: switchInCurve,
      switchOutCurve: switchOutCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: isLoading
          ? KeyedSubtree(key: const ValueKey('loading'), child: loadingWidget)
          : KeyedSubtree(key: const ValueKey('content'), child: contentWidget),
    );
  }
}

/// A widget that smoothly transitions between loading, error, and content states
class AnimatedStateBuilder<T> extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final T? data;
  final Widget Function() loadingBuilder;
  final Widget Function(String error) errorBuilder;
  final Widget Function(T data) contentBuilder;
  final Widget Function()? emptyBuilder;
  final Duration duration;

  const AnimatedStateBuilder({
    super.key,
    required this.isLoading,
    this.error,
    this.data,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.contentBuilder,
    this.emptyBuilder,
    this.duration = AppDurations.normal,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    Key key;

    if (isLoading) {
      key = const ValueKey('loading');
      child = loadingBuilder();
    } else if (error != null) {
      key = const ValueKey('error');
      child = errorBuilder(error!);
    } else if (data == null && emptyBuilder != null) {
      key = const ValueKey('empty');
      child = emptyBuilder!();
    } else if (data != null) {
      key = const ValueKey('content');
      child = contentBuilder(data as T);
    } else {
      key = const ValueKey('loading');
      child = loadingBuilder();
    }

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(key: key, child: child),
    );
  }
}

/// Staggered animation for list items
class StaggeredListAnimation extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index, Animation<double> animation) itemBuilder;
  final Duration staggerDuration;
  final Duration itemDuration;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;

  const StaggeredListAnimation({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.staggerDuration = const Duration(milliseconds: 50),
    this.itemDuration = AppDurations.normal,
    this.controller,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return _StaggeredItem(
          index: index,
          staggerDuration: staggerDuration,
          itemDuration: itemDuration,
          builder: (animation) => itemBuilder(context, index, animation),
        );
      },
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Duration staggerDuration;
  final Duration itemDuration;
  final Widget Function(Animation<double> animation) builder;

  const _StaggeredItem({
    required this.index,
    required this.staggerDuration,
    required this.itemDuration,
    required this.builder,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.itemDuration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    Future.delayed(widget.staggerDuration * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
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
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - _animation.value)), child: child),
        );
      },
      child: widget.builder(_animation),
    );
  }
}

/// Fade in animation wrapper for single items
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool slideUp;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = AppDurations.normal,
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.slideUp = true,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: widget.slideUp ? const Offset(0, 0.1) : Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
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
