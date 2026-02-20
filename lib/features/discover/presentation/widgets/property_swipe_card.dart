import 'package:flutter/material.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/features/discover/presentation/widgets/swipe_card_details_section.dart';
import 'package:ghar360/features/discover/presentation/widgets/swipe_card_hero_section.dart';

/// A single swipe card displaying a property's hero image at the top
/// and scrollable details below. Composes [SwipeCardHeroSection] and
/// [SwipeCardDetailsSection].
class PropertySwipeCard extends StatefulWidget {
  final PropertyModel property;
  final VoidCallback? onTap;
  final bool showSwipeInstructions;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;

  const PropertySwipeCard({
    super.key,
    required this.property,
    this.onTap,
    this.showSwipeInstructions = false,
    this.onInteractionStart,
    this.onInteractionEnd,
  });

  @override
  State<PropertySwipeCard> createState() => _PropertySwipeCardState();
}

class _PropertySwipeCardState extends State<PropertySwipeCard> {
  bool _interactiveChildActive = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppDesign.shadowColor, blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: colorScheme.surface,
          child: SingleChildScrollView(
            physics: _interactiveChildActive
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwipeCardHeroSection(property: widget.property),
                SwipeCardDetailsSection(
                  property: widget.property,
                  showSwipeInstructions: widget.showSwipeInstructions,
                  onInteractionStart: () {
                    setState(() => _interactiveChildActive = true);
                    widget.onInteractionStart?.call();
                  },
                  onInteractionEnd: () {
                    setState(() => _interactiveChildActive = false);
                    widget.onInteractionEnd?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
