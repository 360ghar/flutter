import 'package:flutter/material.dart';

/// A Column widget that prevents overflow by using MainAxisSize.min by default
/// and provides additional safety measures for bounded layout
class SafeColumn extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<Widget> children;
  final bool shrinkWrap;
  final double? maxHeight;

  const SafeColumn({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min, // Default to min to prevent overflow
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    required this.children,
    this.shrinkWrap = false,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget column = Column(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: children,
    );

    // If maxHeight is specified, constrain the column
    if (maxHeight != null) {
      column = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: column,
      );
    }

    // If shrinkWrap is true, make it intrinsically sized
    if (shrinkWrap) {
      column = IntrinsicHeight(child: column);
    }

    return column;
  }
}

/// A Row widget that prevents overflow by using MainAxisSize.min by default
class SafeRow extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final List<Widget> children;
  final bool shrinkWrap;
  final double? maxWidth;

  const SafeRow({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min, // Default to min to prevent overflow
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    required this.children,
    this.shrinkWrap = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget row = Row(
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: children,
    );

    // If maxWidth is specified, constrain the row
    if (maxWidth != null) {
      row = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: row,
      );
    }

    // If shrinkWrap is true, make it intrinsically sized
    if (shrinkWrap) {
      row = IntrinsicWidth(child: row);
    }

    return row;
  }
}

/// A utility widget that wraps content with overflow protection
class OverflowSafeContainer extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final bool scrollable;

  const OverflowSafeContainer({
    super.key,
    required this.child,
    this.maxHeight,
    this.maxWidth,
    this.padding,
    this.margin,
    this.decoration,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // If scrollable, wrap in SingleChildScrollView
    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    // Apply constraints if specified
    if (maxHeight != null || maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? double.infinity,
          maxWidth: maxWidth ?? double.infinity,
        ),
        child: content,
      );
    }

    // Wrap in container if needed
    if (padding != null || margin != null || decoration != null) {
      content = Container(
        padding: padding,
        margin: margin,
        decoration: decoration,
        child: content,
      );
    }

    return content;
  }
}
