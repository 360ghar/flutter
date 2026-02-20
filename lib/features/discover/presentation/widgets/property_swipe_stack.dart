import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:ghar360/core/data/models/property_model.dart';
import 'package:ghar360/core/design/app_design_extensions.dart';
import 'package:ghar360/core/design/app_design_tokens.dart';
import 'package:ghar360/core/utils/debug_logger.dart';
import 'package:ghar360/core/widgets/common/error_states.dart';
import 'package:ghar360/core/widgets/common/robust_network_image.dart';
import 'package:ghar360/features/discover/presentation/widgets/property_swipe_card.dart';

/// The swipe stack containing multiple property cards with gesture
/// handling, animations, background preview cards, and sparkle effects.
class PropertySwipeStack extends StatefulWidget {
  final List<PropertyModel> properties;
  final Function(PropertyModel) onSwipeLeft;
  final Function(PropertyModel) onSwipeRight;
  final Function(PropertyModel) onSwipeUp;
  final bool showSwipeInstructions;
  final VoidCallback? onChangeFilters;
  final VoidCallback? onRefresh;

  const PropertySwipeStack({
    super.key,
    required this.properties,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    this.showSwipeInstructions = false,
    this.onChangeFilters,
    this.onRefresh,
  });

  @override
  State<PropertySwipeStack> createState() => _PropertySwipeStackState();
}

class _PropertySwipeStackState extends State<PropertySwipeStack> with TickerProviderStateMixin {
  late List<PropertyModel> _properties;
  List<PropertyModel>? _pendingProperties;
  late AnimationController _swipeAnimationController;
  late AnimationController _sparklesAnimationController;
  late Animation<double> _swipeAnimation;
  late Animation<double> _sparklesAnimation;

  Offset _dragPosition = Offset.zero;
  bool _isDragging = false;
  double _rotation = 0;
  bool _showSparkles = false;
  bool _isSwipingRight = false;
  bool _blockGestures = false;

  @override
  void initState() {
    super.initState();
    _properties = List.from(widget.properties);
    DebugLogger.debug('PropertySwipeStack initialized with ${_properties.length} properties');

    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _swipeAnimation = CurvedAnimation(parent: _swipeAnimationController, curve: Curves.easeInOut);

    _sparklesAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sparklesAnimation = CurvedAnimation(
      parent: _sparklesAnimationController,
      curve: Curves.easeOut,
    );

    _swipeAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_pendingProperties != null) {
          _properties = _pendingProperties!;
          _pendingProperties = null;
        } else if (_properties.isNotEmpty) {
          _properties.removeAt(0);
        }
        _swipeAnimationController.reset();
        _sparklesAnimationController.reset();
        _dragPosition = Offset.zero;
        _rotation = 0;
        _showSparkles = false;
        _isSwipingRight = false;
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(PropertySwipeStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_arePropertyListsEqual(widget.properties, oldWidget.properties)) {
      final nextProperties = List<PropertyModel>.from(widget.properties);
      if (_swipeAnimationController.isAnimating || _isDragging) {
        _pendingProperties = nextProperties;
      } else {
        _properties = nextProperties;
        _pendingProperties = null;
        DebugLogger.debug('PropertySwipeStack updated with ${_properties.length} properties');
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _sparklesAnimationController.dispose();
    super.dispose();
  }

  bool _arePropertyListsEqual(List<PropertyModel> a, List<PropertyModel> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    final aIds = a.map((p) => p.id).toList(growable: false);
    final bIds = b.map((p) => p.id).toList(growable: false);
    return listEquals(aIds, bIds);
  }

  double _calculateRotation(Offset dragPosition, Size screenSize) {
    final horizontalRatio = dragPosition.dx / (screenSize.width * 0.5);
    final maxRotation = 0.785398; // 45 degrees
    return horizontalRatio * maxRotation * 0.7;
  }

  void _handlePanEnd(DragEndDetails details, Size screenSize) {
    setState(() => _isDragging = false);

    final dragDistance = _dragPosition.dx;
    final dragThreshold = screenSize.width * 0.25;
    final rotationThreshold = 0.3;

    if (dragDistance.abs() > dragThreshold || _rotation.abs() > rotationThreshold) {
      if (dragDistance > 0 || _rotation > 0) {
        _isSwipingRight = true;
        _showSparkles = true;
        _sparklesAnimationController.forward();
        widget.onSwipeRight(_properties[0]);
      } else {
        widget.onSwipeLeft(_properties[0]);
      }
      _swipeAnimationController.forward();
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    final snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final positionTween = Tween<Offset>(begin: _dragPosition, end: Offset.zero);
    final rotationTween = Tween<double>(begin: _rotation, end: 0);
    final snapAnimation = CurvedAnimation(parent: snapController, curve: Curves.elasticOut);

    snapController.addListener(() {
      setState(() {
        _dragPosition = positionTween.evaluate(snapAnimation);
        _rotation = rotationTween.evaluate(snapAnimation);
      });
    });

    snapController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        snapController.dispose();
      }
    });

    snapController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_properties.isEmpty) {
      DebugLogger.warning('PropertySwipeStack: No properties to display');
      return ErrorStates.swipeDeckEmpty(
        onRefresh: widget.onRefresh,
        onChangeFilters: widget.onChangeFilters,
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final dragThreshold = screenSize.width * 0.25;
    DebugLogger.debug('PropertySwipeStack: Rendering ${_properties.length} properties');

    return GestureDetector(
      onHorizontalDragStart: (details) {
        if (_blockGestures) return;
        setState(() => _isDragging = true);
      },
      onHorizontalDragUpdate: (details) {
        if (_blockGestures) return;
        setState(() {
          final dx = details.primaryDelta ?? 0;
          _dragPosition = Offset(_dragPosition.dx + dx, 0);
          _rotation = _calculateRotation(_dragPosition, screenSize);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_blockGestures) return;
        _handlePanEnd(details, screenSize);
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Background cards
          if (_properties.length > 1)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.95,
                child: Opacity(opacity: 0.8, child: _buildBackgroundPreviewCard(_properties[1])),
              ),
            ),
          if (_properties.length > 2)
            Positioned.fill(
              child: Transform.scale(
                scale: 0.9,
                child: Opacity(opacity: 0.6, child: _buildBackgroundPreviewCard(_properties[2])),
              ),
            ),

          // Top card with rotation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _swipeAnimation,
              builder: (context, child) {
                final swipeOffset = _isDragging
                    ? Offset(_dragPosition.dx, 0)
                    : Offset(_dragPosition.dx * (1 + _swipeAnimation.value * 2), 0);

                final swipeRotation = _isDragging
                    ? _rotation
                    : _rotation * (1 + _swipeAnimation.value * 2);

                final likeProgress = (_dragPosition.dx / dragThreshold).clamp(0.0, 1.0);
                final passProgress = (-_dragPosition.dx / dragThreshold).clamp(0.0, 1.0);
                final showFeedback = _isDragging && (likeProgress > 0 || passProgress > 0);

                return Transform.translate(
                  offset: swipeOffset,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateZ(swipeRotation),
                    child: Opacity(
                      opacity: _swipeAnimationController.isAnimating
                          ? (1 - _swipeAnimation.value)
                          : 1.0,
                      child: Stack(
                        children: [
                          PropertySwipeCard(
                            property: _properties[0],
                            showSwipeInstructions: widget.showSwipeInstructions,
                            onInteractionStart: () => setState(() => _blockGestures = true),
                            onInteractionEnd: () => setState(() => _blockGestures = false),
                          ),
                          if (showFeedback)
                            _buildSwipeFeedbackOverlay(
                              context,
                              likeProgress: likeProgress,
                              passProgress: passProgress,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sparkles animation
          if (_showSparkles && _isSwipingRight)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sparklesAnimation,
                builder: (context, child) {
                  return IgnorePointer(child: _SparklesWidget(animation: _sparklesAnimation));
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPreviewCard(PropertyModel property) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RobustNetworkImage(
            imageUrl: property.mainImage,
            fit: BoxFit.cover,
            placeholder: Container(color: AppDesign.inputBackground),
            errorWidget: Container(
              color: AppDesign.surface,
              alignment: Alignment.center,
              child: Icon(Icons.home_work_outlined, color: AppDesign.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppDesign.transparent, AppDesign.shadowColor.withValues(alpha: 0.7)],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  property.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppDesignTokens.neutralWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  property.formattedPrice,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppDesign.primaryYellow,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeFeedbackOverlay(
    BuildContext context, {
    required double likeProgress,
    required double passProgress,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            if (likeProgress > 0)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppDesign.transparent,
                      AppDesign.successGreen.withValues(alpha: 0.18 * likeProgress),
                    ],
                  ),
                ),
              ),
            if (passProgress > 0)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      AppDesign.transparent,
                      AppDesign.errorRed.withValues(alpha: 0.18 * passProgress),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 24,
              left: 24,
              child: Opacity(
                opacity: likeProgress,
                child: Transform.rotate(
                  angle: -0.18,
                  child: _buildSwipeDecisionBadge(
                    context,
                    color: AppDesign.successGreen,
                    icon: Icons.favorite_rounded,
                    label: 'liked'.tr.toUpperCase(),
                    progress: likeProgress,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: Opacity(
                opacity: passProgress,
                child: Transform.rotate(
                  angle: 0.18,
                  child: _buildSwipeDecisionBadge(
                    context,
                    color: AppDesign.errorRed,
                    icon: Icons.close_rounded,
                    label: 'passed'.tr.toUpperCase(),
                    progress: passProgress,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeDecisionBadge(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String label,
    required double progress,
  }) {
    final theme = Theme.of(context);
    final scale = 0.92 + 0.08 * progress;

    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppDesign.darkTextPrimary.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.95), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sparkles widget for the enthusiasm animation
class _SparklesWidget extends StatelessWidget {
  final Animation<double> animation;

  const _SparklesWidget({required this.animation});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SparklesPainter(animation.value), size: Size.infinite);
  }
}

class _SparklesPainter extends CustomPainter {
  final double animationValue;

  _SparklesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppDesign.primaryYellow.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final sparklePositions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.3, size.height * 0.7),
      Offset(size.width * 0.7, size.height * 0.8),
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.9, size.height * 0.4),
      Offset(size.width * 0.4, size.height * 0.2),
    ];

    for (int i = 0; i < sparklePositions.length; i++) {
      final position = sparklePositions[i];
      final delay = i * 0.1;
      final sparkleAnimation = ((animationValue - delay) / (1 - delay)).clamp(0.0, 1.0);

      if (sparkleAnimation > 0) {
        final sparkleSize = 8.0 * sparkleAnimation * (1 - sparkleAnimation * 0.5);
        final sparkleOpacity = (1 - sparkleAnimation).clamp(0.0, 1.0);

        paint.color = AppDesign.primaryYellow.withValues(alpha: sparkleOpacity * 0.8);

        _drawStar(canvas, paint, position, sparkleSize);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, Offset center, double size) {
    final path = ui.Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
