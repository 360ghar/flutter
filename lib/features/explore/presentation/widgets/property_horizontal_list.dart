import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
import 'package:ghar360/core/utils/app_spacing.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/features/explore/presentation/controllers/explore_controller.dart';
import 'package:ghar360/features/explore/presentation/widgets/explore_property_card.dart';

class PropertyHorizontalList extends StatefulWidget {
  final ExploreController controller;

  const PropertyHorizontalList({super.key, required this.controller});

  @override
  State<PropertyHorizontalList> createState() => _PropertyHorizontalListState();
}

class _PropertyHorizontalListState extends State<PropertyHorizontalList> {
  final ScrollController _scrollController = ScrollController();
  Worker? _selectionWorker;
  int? _lastSelectedId;
  Timer? _scrollDebounce;
  static const double _itemWidth = 260.0;
  static const double _spacing = 12.0;

  @override
  void initState() {
    super.initState();
    // Listen to selected property changes to auto-scroll
    _selectionWorker = ever(widget.controller.selectedProperty, (PropertyModel? p) {
      if (p == null) return;
      if (_lastSelectedId == p.id) return;
      _lastSelectedId = p.id;
      HapticFeedback.selectionClick();
      _scrollToProperty(p.id);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _selectionWorker?.dispose();
    _scrollDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToProperty(int propertyId) {
    try {
      final index = widget.controller.properties.indexWhere((e) => e.id == propertyId);
      if (index == -1) return;

      // Center the selected card in the viewport
      final viewportWidth = _scrollController.position.viewportDimension;
      final target = index * (_itemWidth + _spacing) - (viewportWidth / 2) + (_itemWidth / 2);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollController.animateTo(
          target.clamp(0, _scrollController.position.maxScrollExtent),
          duration: AppDurations.normal,
          curve: AppCurves.standard,
        );
      });
    } catch (e) {
      DebugLogger.warning('Could not scroll to property: $e');
    }
  }

  void _onScroll() {
    // Debounce to avoid spamming highlight updates
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 80), () {
      try {
        final offset = _scrollController.offset;
        final rawIndex = offset / (_itemWidth + _spacing);
        final index = rawIndex.round().clamp(0, widget.controller.properties.length - 1);
        if (widget.controller.properties.isEmpty) return;
        final property = widget.controller.properties[index];
        if (property.id != _lastSelectedId) {
          _lastSelectedId = property.id;
          widget.controller.highlightPropertyFromCard(property);
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final properties = widget.controller.properties;
      // Force Obx to subscribe to like state changes
      final _ = widget.controller.likedOverrides.entries.toList();
      if (properties.isEmpty) {
        return Container(
          height: 10, // keep minimal footprint when empty
          color: AppDesign.transparent,
        );
      }

      return Container(
        height: 220,
        padding: const EdgeInsets.only(bottom: 10),
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final property = properties[index];
            final isSelected = widget.controller.selectedProperty.value?.id == property.id;
            final isFavourite = widget.controller.isPropertyLiked(property);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 260,
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isSelected ? AppDesignTokens.brandGoldSubtle.withValues(alpha: 0.5) : null,
                border: Border.all(
                  color: isSelected ? AppDesignTokens.brandGold : AppDesign.transparent,
                  width: isSelected ? 1.5 : 0,
                ),
              ),
              child: ExplorePropertyCard(
                property: property,
                isFavourite: isFavourite,
                onFavouriteToggle: () => widget.controller.toggleLike(property),
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemCount: properties.length,
        ),
      );
    });
  }
}
