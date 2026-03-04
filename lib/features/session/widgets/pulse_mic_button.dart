import 'package:flutter/material.dart';

/// Large circular mic button with animated sonar-pulse rings.
class PulseMicButton extends StatefulWidget {
  const PulseMicButton({
    super.key,
    required this.isActive,
    required this.onTap,
  });

  /// When `true`, the sonar rings animate outwards.
  final bool isActive;

  final VoidCallback onTap;

  @override
  State<PulseMicButton> createState() => _PulseMicButtonState();
}

class _PulseMicButtonState extends State<PulseMicButton>
    with TickerProviderStateMixin {
  // We use two staggered controllers to create overlapping rings.
  late final AnimationController _ring1;
  late final AnimationController _ring2;

  @override
  void initState() {
    super.initState();
    _ring1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ring2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant PulseMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    if (widget.isActive) {
      _ring1.repeat();
      // Stagger the second ring by half a cycle.
      Future.delayed(const Duration(milliseconds: 750), () {
        if (mounted && widget.isActive) _ring2.repeat();
      });
    } else {
      _ring1.stop();
      _ring2.stop();
      _ring1.value = 0;
      _ring2.value = 0;
    }
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonSize = 72;
    const double maxRingSize = 120;
    const Color primaryBlue = Color(0xFF1A73E8);

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: maxRingSize,
        height: maxRingSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ring 1
            if (widget.isActive)
              _SonarRing(
                controller: _ring1,
                maxSize: maxRingSize,
                color: primaryBlue,
              ),
            // Ring 2 (staggered)
            if (widget.isActive)
              _SonarRing(
                controller: _ring2,
                maxSize: maxRingSize,
                color: primaryBlue,
              ),
            // Main button
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isActive ? primaryBlue : Colors.grey.shade700,
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single expanding + fading ring used by [PulseMicButton].
class _SonarRing extends StatelessWidget {
  const _SonarRing({
    required this.controller,
    required this.maxSize,
    required this.color,
  });

  final AnimationController controller;
  final double maxSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final size = 72 + (maxSize - 72) * t;
        final opacity = (1.0 - t) * 0.4;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: opacity),
              width: 2.5 - t * 1.5,
            ),
          ),
        );
      },
    );
  }
}
