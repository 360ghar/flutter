import 'package:flutter/material.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/features/discover/widgets/property_card.dart';

class SwipeStack extends StatefulWidget {
  final List<PropertyModel> properties;
  final Function(PropertyModel) onSwipeLeft;
  final Function(PropertyModel) onSwipeRight;

  const SwipeStack({
    super.key,
    required this.properties,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<SwipeStack> createState() => _SwipeStackState();
}

class _SwipeStackState extends State<SwipeStack> with SingleTickerProviderStateMixin {
  late List<PropertyModel> _properties;
  late AnimationController _animationController;

  Offset _dragStart = Offset.zero;
  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _properties = List.from(widget.properties);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_properties.isEmpty) {
      return Center(
        child: Text(
          'No more properties to show',
          style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
      );
    }

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
          _dragStart = details.localPosition;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _dragPosition = details.localPosition - _dragStart;
        });
      },
      onPanEnd: (details) {
        setState(() {
          _isDragging = false;
        });

        final screenWidth = MediaQuery.of(context).size.width;
        final dragDistance = _dragPosition.dx;
        final dragThreshold = screenWidth * 0.3;

        if (dragDistance.abs() > dragThreshold) {
          if (dragDistance > 0) {
            widget.onSwipeRight(_properties[0]);
          } else {
            widget.onSwipeLeft(_properties[0]);
          }
          _animationController.forward();
        } else {
          setState(() {
            _dragPosition = Offset.zero;
          });
        }
      },
      child: Stack(
        children: [
          if (_properties.length > 1)
            Positioned.fill(
              child: PropertyCard(
                property: _properties[1],
                isFavourite: false,
                onFavouriteToggle: () {},
                onTap: () {},
              ),
            ),
          Positioned.fill(
            child: Transform.translate(
              offset: _isDragging ? _dragPosition : Offset.zero,
              child: Transform.rotate(
                angle: _isDragging ? _dragPosition.dx * 0.01 : 0,
                child: PropertyCard(
                  property: _properties[0],
                  isFavourite: false,
                  onFavouriteToggle: () {},
                  onTap: () {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
