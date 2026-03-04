import 'package:flutter/material.dart';
import 'package:medlens_mobile/features/session/bloc/session_state.dart';

/// Dr. Muhammad's avatar circle with animated glow/pulse based on agent state.
class DrMuhammadAvatar extends StatefulWidget {
  const DrMuhammadAvatar({super.key, required this.agentStatus});

  final AgentSpeaking agentStatus;

  @override
  State<DrMuhammadAvatar> createState() => _DrMuhammadAvatarState();
}

class _DrMuhammadAvatarState extends State<DrMuhammadAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant DrMuhammadAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agentStatus != widget.agentStatus) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    switch (widget.agentStatus) {
      case AgentSpeaking.speaking:
        _controller.repeat(reverse: true);
      case AgentSpeaking.listening:
        // Subtle slow pulse
        _controller
          ..duration = const Duration(milliseconds: 2000)
          ..repeat(reverse: true);
      case AgentSpeaking.thinking:
        _controller
          ..duration = const Duration(milliseconds: 600)
          ..repeat(reverse: true);
      case AgentSpeaking.idle:
        _controller
          ..stop()
          ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final isSpeaking = widget.agentStatus == AgentSpeaking.speaking;
        final isThinking = widget.agentStatus == AgentSpeaking.thinking;
        final glowVal = _glowAnimation.value;

        final Color borderColor;
        final double borderWidth;
        final List<BoxShadow>? shadows;

        if (isSpeaking) {
          borderColor = Color.fromRGBO(26, 115, 232, 0.5 + glowVal * 0.5);
          borderWidth = 2.5 + glowVal;
          shadows = [
            BoxShadow(
              color: Color.fromRGBO(26, 115, 232, glowVal * 0.5),
              blurRadius: 14 + glowVal * 6,
              spreadRadius: 2 + glowVal * 2,
            ),
          ];
        } else if (isThinking) {
          borderColor = Color.fromRGBO(255, 167, 38, 0.5 + glowVal * 0.5);
          borderWidth = 2;
          shadows = [
            BoxShadow(
              color: Color.fromRGBO(255, 167, 38, glowVal * 0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ];
        } else {
          borderColor = Colors.white.withValues(alpha: 0.3 + glowVal * 0.15);
          borderWidth = 1.5;
          shadows = null;
        }

        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadows,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/Dr.Muhammad.jpeg',
              fit: BoxFit.cover,
              width: 48,
              height: 48,
              errorBuilder: (_, __, ___) => const CircleAvatar(
                backgroundColor: Color(0xFF1A73E8),
                child: Text(
                  'Dr',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
