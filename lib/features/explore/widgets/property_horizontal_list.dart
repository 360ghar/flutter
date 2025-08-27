import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/debug_logger.dart';
import '../../../core/data/models/property_model.dart';
import '../../../widgets/property/compact_property_card.dart';
import '../controllers/explore_controller.dart';

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

  @override
  void initState() {
    super.initState();
    // Listen to selected property changes to auto-scroll
    _selectionWorker = ever(widget.controller.selectedProperty, (PropertyModel? p) {
      if (p == null) return;
      if (_lastSelectedId == p.id) return;
      _lastSelectedId = p.id;
      _scrollToProperty(p.id);
    });
  }

  @override
  void dispose() {
    _selectionWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToProperty(int propertyId) {
    try {
      final index = widget.controller.properties.indexWhere((e) => e.id == propertyId);
      if (index == -1) return;

      // Calculate target offset roughly based on item width and spacing
      const itemWidth = 260.0;
      const spacing = 12.0;
      final target = index * (itemWidth + spacing);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scrollController.animateTo(
          target.clamp(0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      DebugLogger.warning('Could not scroll to property: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final properties = widget.controller.properties;
      if (properties.isEmpty) {
        return Container(
          height: 10, // keep minimal footprint when empty
          color: Colors.transparent,
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
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: isSelected ? AppColors.getCardShadow() : null,
                border: Border.all(
                  color: isSelected ? AppColors.primaryYellow : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CompactPropertyCard(
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

