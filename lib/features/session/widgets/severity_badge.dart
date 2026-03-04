import 'package:flutter/material.dart';

/// Severity badge — small animated pill showing injury severity.
///
/// Slides in from the top when it first appears.
class SeverityBadge extends StatefulWidget {
  const SeverityBadge({super.key, required this.severity});

  /// One of: `low`, `medium`, `high`.
  final String severity;

  @override
  State<SeverityBadge> createState() => _SeverityBadgeState();
}

class _SeverityBadgeState extends State<SeverityBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (Color bg, String label) = switch (widget.severity.toLowerCase()) {
      'high' => (const Color(0xFFE53935), '⚠ Seek Help'),
      'medium' => (const Color(0xFFFFA726), 'Moderate'),
      _ => (const Color(0xFF4CAF50), 'Low Risk'),
    };

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
