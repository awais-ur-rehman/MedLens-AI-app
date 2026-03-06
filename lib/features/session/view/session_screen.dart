import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:medlens_mobile/features/session/bloc/session_bloc.dart';
import 'package:medlens_mobile/features/session/bloc/session_event.dart';
import 'package:medlens_mobile/features/session/bloc/session_state.dart';
import 'package:medlens_mobile/features/session/widgets/citation_chip.dart';
import 'package:medlens_mobile/features/session/widgets/dr_muhammad_avatar.dart';
import 'package:medlens_mobile/features/session/widgets/overlay_painter.dart';
import 'package:medlens_mobile/features/session/widgets/pulse_mic_button.dart';
import 'package:medlens_mobile/features/session/widgets/severity_badge.dart';
import 'package:medlens_mobile/features/session/widgets/transcript_panel.dart';
import 'package:medlens_mobile/features/summary/bloc/summary_bloc.dart';
import 'package:medlens_mobile/models/overlay_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Palette
// ─────────────────────────────────────────────────────────────────────────────

const _kBg = Color(0xFF0A0F1E);
const _kSurface = Color(0xFF111827);
const _kBlue = Color(0xFF3B82F6);

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showTextInput = false;

  bool _showPhotoConfirm = false;
  Uint8List? _photoConfirmImage;
  Timer? _photoConfirmTimer;

  @override
  void initState() {
    super.initState();
    context.read<SessionBloc>().add(SessionStarted());
  }

  @override
  void dispose() {
    _textController.dispose();
    _photoConfirmTimer?.cancel();
    super.dispose();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      context.read<SessionBloc>().add(TextMessageSent(text));
      _textController.clear();
      setState(() => _showTextInput = false);
      FocusScope.of(context).unfocus();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == SessionStatus.ended) {
              if (state.careSummary != null) {
                context.read<SummaryBloc>().add(SummaryLoaded(state.careSummary!));
              }
              context.goNamed('summary');
            }
          },
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (prev, curr) =>
              prev.lastCapturedImage != curr.lastCapturedImage,
          listener: (context, state) {
            if (state.lastCapturedImage != null) {
              setState(() {
                _showPhotoConfirm = true;
                _photoConfirmImage = state.lastCapturedImage;
              });
              _photoConfirmTimer?.cancel();
              _photoConfirmTimer = Timer(const Duration(seconds: 3), () {
                if (mounted) setState(() => _showPhotoConfirm = false);
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: _kBg,
        body: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            final cameraActive = state.cameraMode != CameraMode.inactive ||
                state.cameraInitializing;

            return Stack(
              fit: StackFit.expand,
              children: [
                // ── Main conversation UI ──────────────────────────────────
                _buildConversationUI(context, state),

                // ── Full-screen camera overlay ────────────────────────────
                if (cameraActive)
                  _buildCameraOverlay(context, state),

                // ── Photo-sent toast ──────────────────────────────────────
                if (_showPhotoConfirm && _photoConfirmImage != null)
                  _buildPhotoToast(_photoConfirmImage!),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Conversation UI (always visible behind camera overlay)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildConversationUI(BuildContext context, SessionState state) {
    final isThinking = state.sessionMode == SessionMode.thinking;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context, state),
          const Divider(height: 1, color: Color(0xFF1F2937)),

          // Severity strip (only when assessed)
          if (state.currentAssessment != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SeverityBadge(severity: state.currentAssessment!.severity),
            ),

          // Transcript — fills all available space
          Expanded(
            child: TranscriptPanel(
              messages: state.transcript,
              isThinking: isThinking,
            ),
          ),

          // Citations row
          if (state.citations.isNotEmpty) _buildCitations(state),

          const Divider(height: 1, color: Color(0xFF1F2937)),
          _buildBottomBar(context, state),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, SessionState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Status pill
          _StatusPill(status: state.status, mode: state.sessionMode),

          const Spacer(),

          // Doctor identity
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DrMuhammadAvatar(agentStatus: state.sessionMode),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Dr. Muhammad',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'AI First Aid',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // End session
          GestureDetector(
            onTap: () => context.read<SessionBloc>().add(SessionEnded()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                'End',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Citations row
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCitations(SessionState state) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.citations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) =>
            CitationChip(citation: state.citations[index]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Bottom bar
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, SessionState state) {
    return Container(
      color: _kSurface,
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input (hidden until keyboard icon tapped)
          if (_showTextInput) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.35)),
                      filled: true,
                      fillColor: const Color(0xFF1F2937),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendText(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendText,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: _kBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Main controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: camera button
              _buildCameraControl(context, state),

              // Centre: mic button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseMicButton(
                    isActive: state.isMicActive,
                    onTap: () =>
                        context.read<SessionBloc>().add(const MicTapped()),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _micHint(state.sessionMode),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              // Right: keyboard toggle
              _IconControl(
                icon: _showTextInput
                    ? Icons.keyboard_hide_rounded
                    : Icons.keyboard_rounded,
                active: _showTextInput,
                onTap: () => setState(() => _showTextInput = !_showTextInput),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControl(BuildContext context, SessionState state) {
    if (state.cameraMode == CameraMode.inactive) {
      return state.cameraButtonPulsing
          ? _PulsingCameraButton(
              onTap: () =>
                  context.read<SessionBloc>().add(CameraOpened()),
            )
          : _IconControl(
              icon: Icons.camera_alt_rounded,
              onTap: () =>
                  context.read<SessionBloc>().add(CameraOpened()),
            );
    }
    // Camera is open — show close button on left
    return _IconControl(
      icon: Icons.camera_alt_rounded,
      active: true,
      color: _kBlue,
      onTap: () {},
    );
  }

  String _micHint(SessionMode mode) => switch (mode) {
        SessionMode.doctorSpeaking => 'Tap to interrupt',
        SessionMode.userSpeaking => 'Tap to send',
        SessionMode.thinking => 'Processing…',
        SessionMode.idle => 'Tap to speak',
      };

  // ─────────────────────────────────────────────────────────────────────────
  //  Full-screen camera overlay
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCameraOverlay(BuildContext context, SessionState state) {
    return Positioned.fill(
      child: Material(
        color: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              // ── Overlay header ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          context.read<SessionBloc>().add(CameraClosed()),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const Spacer(),
                    if (state.cameraMode == CameraMode.liveStreaming)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.6)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                color: Colors.redAccent, size: 8),
                            SizedBox(width: 5),
                            Text('LIVE',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'Show the affected area',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    const Spacer(),
                    const SizedBox(width: 36), // balance the close button
                  ],
                ),
              ),

              // ── Camera preview ──────────────────────────────────────────
              Expanded(
                child: state.cameraInitializing
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: _kBlue),
                            SizedBox(height: 16),
                            Text(
                              'Starting camera…',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    : _buildCameraPreview(context, state.overlays),
              ),

              // ── Capture controls ────────────────────────────────────────
              if (state.cameraMode == CameraMode.captureReady)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: GestureDetector(
                    onTap: () async {
                      final bloc = context.read<SessionBloc>();
                      final bytes = await bloc.camera.capturePhoto();
                      if (bytes != null) {
                        bloc.add(PhotoCaptured(bytes));
                      }
                    },
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: Center(
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else if (state.cameraMode == CameraMode.liveStreaming)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Streaming live to Dr. Muhammad',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview(
      BuildContext context, List<OverlayModel> overlays) {
    final controller = context.read<SessionBloc>().camera.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Text('Camera unavailable',
            style: TextStyle(color: Colors.white38)),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          // Visual overlay annotations from Dr. Muhammad
          if (overlays.isNotEmpty)
            CustomPaint(
              painter: OverlayPainter(overlays: overlays),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Photo-sent toast
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPhotoToast(Uint8List imageBytes) {
    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _showPhotoConfirm ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.green.withValues(alpha: 0.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(imageBytes,
                      width: 48, height: 36, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Photo sent to Dr. Muhammad',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Status pill widget
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.mode});
  final SessionStatus status;
  final SessionMode mode;

  @override
  Widget build(BuildContext context) {
    final (Color dot, String label) = switch (status) {
      SessionStatus.active => (const Color(0xFF4CAF50), 'Live'),
      SessionStatus.connecting => (const Color(0xFFFFC107), 'Connecting'),
      SessionStatus.error => (Colors.redAccent, 'Error'),
      _ => (Colors.grey, ''),
    };

    if (label.isEmpty) return const SizedBox(width: 60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: dot.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dot.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: dot,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Generic icon control button
// ─────────────────────────────────────────────────────────────────────────────

class _IconControl extends StatelessWidget {
  const _IconControl({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? _kBlue : Colors.white54);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withValues(alpha: active ? 0.15 : 0.08),
          border: Border.all(color: c.withValues(alpha: active ? 0.4 : 0.2)),
        ),
        child: Icon(icon, color: c, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Pulsing camera button (when Dr. Muhammad requests camera)
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingCameraButton extends StatefulWidget {
  const _PulsingCameraButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PulsingCameraButton> createState() => _PulsingCameraButtonState();
}

class _PulsingCameraButtonState extends State<_PulsingCameraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.22)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _kBlue.withValues(alpha: 0.15),
            border: Border.all(color: _kBlue.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.4 * _scale.value),
                blurRadius: 16 * _scale.value,
                spreadRadius: 2 * _scale.value,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: _kBlue),
            onPressed: widget.onTap,
            iconSize: 20,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
