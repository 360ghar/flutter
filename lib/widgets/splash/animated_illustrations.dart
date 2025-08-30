import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/utils/theme.dart';

// 360 Tour Illustration with rotating animation
class Tour360Illustration extends StatelessWidget {
  final Animation<double> rotationAnimation;
  final Animation<double> scaleAnimation;

  const Tour360Illustration({
    super.key,
    required this.rotationAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([rotationAnimation, scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rotating ring
              Transform.rotate(
                angle: rotationAnimation.value * 2 * math.pi,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                      width: 3,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Rotating dots around the circle
                      ...List.generate(12, (index) {
                        final angle = (index * 30) * math.pi / 180;
                        return Positioned(
                          left: 94 + 85 * math.cos(angle),
                          top: 94 + 85 * math.sin(angle),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.accentBlue.withValues(alpha: 0.7),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Center house icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryYellow,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryYellow.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              // 360° text
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '360°',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Virtual Tours Convenience Illustration
class VirtualToursIllustration extends StatelessWidget {
  final Animation<Offset> slideAnimation;
  final Animation<double> scaleAnimation;

  const VirtualToursIllustration({
    super.key,
    required this.slideAnimation,
    required this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([slideAnimation, scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Phone mockup
              Container(
                width: 160,
                height: 280,
                decoration: BoxDecoration(
                  color: AppTheme.textDark,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Screen
                    Positioned(
                      top: 20,
                      left: 12,
                      right: 12,
                      bottom: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundWhite,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Property image
                            Positioned(
                              top: 16,
                              left: 16,
                              right: 16,
                              height: 120,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue.withValues(
                                    alpha: 0.3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.apartment,
                                  size: 40,
                                  color: AppTheme.accentBlue,
                                ),
                              ),
                            ),
                            // Play button for virtual tour
                            Positioned(
                              top: 60,
                              left: 55,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.primaryYellow,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Floating elements showing convenience
              Positioned(
                top: 50,
                right: 20,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: scaleAnimation as AnimationController,
                          curve: const Interval(0.0, 0.3),
                        ),
                      ),
                  child: const _FloatingIcon(
                    icon: Icons.access_time,
                    color: AppTheme.accentGreen,
                    delay: 0,
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                left: 20,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(-1, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: scaleAnimation as AnimationController,
                          curve: const Interval(0.2, 0.5),
                        ),
                      ),
                  child: const _FloatingIcon(
                    icon: Icons.location_on,
                    color: AppTheme.accentOrange,
                    delay: 500,
                  ),
                ),
              ),
              Positioned(
                top: 120,
                left: 30,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, -1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: scaleAnimation as AnimationController,
                          curve: const Interval(0.4, 0.7),
                        ),
                      ),
                  child: const _FloatingIcon(
                    icon: Icons.home_work,
                    color: AppTheme.accentBlue,
                    delay: 1000,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Verified Listing Illustration
class VerifiedListingIllustration extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;

  const VerifiedListingIllustration({
    super.key,
    required this.scaleAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, fadeAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Opacity(
            opacity: fadeAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Document/List background
                Container(
                  width: 220,
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Property image placeholder
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 30,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Property details with checkmarks
                      ...List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.successGreen,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundGray,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Verified badge
                Positioned(
                  top: -10,
                  right: -10,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.successGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Low Brokerage Complete Service Illustration
class LowBrokerageIllustration extends StatelessWidget {
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;

  const LowBrokerageIllustration({
    super.key,
    required this.scaleAnimation,
    required this.rotationAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([scaleAnimation, rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Money/savings illustration
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.successGreen.withValues(alpha: 0.1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Coins/money
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.successGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.successGreen.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.attach_money,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    // Percentage badge
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'LOW %',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Service icons floating around
              ...List.generate(6, (index) {
                final angle = (index * 60) * math.pi / 180;
                final radius = 130.0;
                final icons = [
                  Icons.support_agent,
                  Icons.verified_user,
                  Icons.handshake,
                  Icons.schedule,
                  Icons.security,
                  Icons.thumb_up,
                ];

                return Positioned(
                  left:
                      100 +
                      radius *
                          math.cos(
                            angle + rotationAnimation.value * 2 * math.pi,
                          ),
                  top:
                      100 +
                      radius *
                          math.sin(
                            angle + rotationAnimation.value * 2 * math.pi,
                          ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentBlue.withValues(alpha: 0.8),
                    ),
                    child: Icon(icons[index], size: 20, color: Colors.white),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// Helper widget for floating icons
class _FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final int delay;

  const _FloatingIcon({
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  State<_FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<_FloatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
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
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(widget.icon, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }
}
