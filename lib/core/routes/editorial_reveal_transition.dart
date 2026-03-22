import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/app_spacing.dart';

/// Editorial "reveal" transition: fade in + subtle upward slide.
/// Gives page entrances a magazine-like unveiling feel.
class EditorialRevealTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve ?? AppCurves.standard);

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
