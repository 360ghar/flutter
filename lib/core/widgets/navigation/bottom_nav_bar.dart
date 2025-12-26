import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/utils/app_colors.dart';
import 'package:ghar360/core/utils/app_spacing.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({super.key, required this.currentIndex, required this.onTap});

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  final List<_NavItem> _items = [
    const _NavItem(Icons.person_outline, Icons.person, 'profile'),
    const _NavItem(Icons.explore_outlined, Icons.explore, 'explore_properties'),
    const _NavItem(Icons.home_outlined, Icons.home, 'discover'),
    const _NavItem(Icons.favorite_border, Icons.favorite, 'liked'),
    const _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'visits'),
  ];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _items.length,
      (index) => AnimationController(vsync: this, duration: AppDurations.fast),
    );
    _scaleAnimations = _controllers
        .map(
          (controller) => Tween<double>(
            begin: 1.0,
            end: 1.2,
          ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut)),
        )
        .toList();

    // Animate initial selection
    if (widget.currentIndex >= 0 && widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (oldWidget.currentIndex >= 0 && oldWidget.currentIndex < _controllers.length) {
        _controllers[oldWidget.currentIndex].reverse();
      }
      if (widget.currentIndex >= 0 && widget.currentIndex < _controllers.length) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleTap(int index) {
    if (index == widget.currentIndex) return;
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navigationBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = widget.currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _handleTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: _scaleAnimations[index],
                    builder: (context, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: _scaleAnimations[index].value,
                            child: AnimatedSwitcher(
                              duration: AppDurations.fast,
                              child: Icon(
                                isSelected ? item.activeIcon : item.inactiveIcon,
                                key: ValueKey(isSelected),
                                color: isSelected
                                    ? AppColors.primaryYellow
                                    : AppColors.navigationUnselected,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: AppDurations.fast,
                            style: TextStyle(
                              fontSize: isSelected ? 11 : 10,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primaryYellow
                                  : AppColors.navigationUnselected,
                            ),
                            child: Text(item.label.tr),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.inactiveIcon, this.activeIcon, this.label);
}
