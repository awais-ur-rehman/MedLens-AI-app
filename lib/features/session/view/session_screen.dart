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

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final TextEditingController _textController = TextEditingController();

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

  String _micHintText(SessionMode mode) => switch (mode) {
    SessionMode.doctorSpeaking => 'Tap mic to interrupt',
    SessionMode.userSpeaking   => 'Tap mic when done speaking',
    SessionMode.thinking       => 'Processing...',
    SessionMode.idle           => 'Speak or tap mic to send',
  };

  Widget _buildPhotoConfirmOverlay(Uint8List imageBytes) {
    return Positioned(
      top: 90,
      right: 16,
      child: AnimatedOpacity(
        opacity: _showPhotoConfirm ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 120,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(imageBytes, fit: BoxFit.cover),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.75),
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: const Text(
                      '✓ Sent',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      context.read<SessionBloc>().add(TextMessageSent(text));
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (prev, curr) => prev.status != curr.status,
          listener: (context, state) {
            if (state.status == SessionStatus.ended) {
              // Bridge the summary to SummaryBloc before navigating.
              // SummaryScreen reads from SummaryBloc, not SessionBloc.
              if (state.careSummary != null) {
                context.read<SummaryBloc>().add(SummaryLoaded(state.careSummary!));
              }
              context.goNamed('summary');
            }
          },
        ),
        BlocListener<SessionBloc, SessionState>(
          listenWhen: (prev, curr) => prev.lastCapturedImage != curr.lastCapturedImage,
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
        backgroundColor: const Color(0xFF121212),
        body: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            final hasCameraArea =
                state.cameraMode != CameraMode.inactive || state.cameraInitializing;
            final screenHeight = MediaQuery.of(context).size.height;
            final cameraAreaHeight = screenHeight * 0.45;

            return Stack(
              fit: StackFit.expand,
              children: [
                // ---- Background (always dark) ----
                _buildDarkBackground(),

                // ---- Camera Preview (top portion, only when active) ----
                if (hasCameraArea) _buildCameraPreview(context, state, cameraAreaHeight),

                // ---- Overlays (Bounding Boxes) ----
                if (hasCameraArea && state.overlays.isNotEmpty)
                  CustomPaint(
                    painter: OverlayPainter(overlays: state.overlays),
                    size: Size.infinite,
                  ),

                // ---- Top bar ----
                _buildTopBar(state),

                // ---- Main Transcript Area ----
                _buildTranscriptArea(context, state, hasCameraArea, cameraAreaHeight),

                // ---- Bottom Control Panel ----
                _buildBottomInputArea(state),

                // ---- Photo Confirmation Overlay ----
                if (_showPhotoConfirm && _photoConfirmImage != null)
                  _buildPhotoConfirmOverlay(_photoConfirmImage!),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDarkBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(
    BuildContext context,
    SessionState state,
    double height,
  ) {
    const top = 80.0;
    if (state.cameraInitializing) {
      return Positioned(
        top: top,
        left: 0,
        right: 0,
        height: height,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
        ),
      );
    }
    final controller = context.read<SessionBloc>().camera.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildTopBar(SessionState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _TopBarButton(
                icon: Icons.close,
                onTap: () => context.read<SessionBloc>().add(SessionEnded()),
              ),
              const Spacer(),
              _ConnectionDot(status: state.status),
              const Spacer(),
              DrMuhammadAvatar(agentStatus: state.sessionMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptArea(
    BuildContext context,
    SessionState state,
    bool hasCameraArea,
    double cameraAreaHeight,
  ) {
    final top = hasCameraArea ? 80.0 + cameraAreaHeight + 8.0 : 100.0;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      bottom: 200, // Above bottom input panel
      child: Column(
        children: [
          if (state.currentAssessment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SeverityBadge(severity: state.currentAssessment!.severity),
            ),
          Expanded(
            child: TranscriptPanel(messages: state.transcript),
          ),
          if (state.citations.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: state.citations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) =>
                    CitationChip(citation: state.citations[index]),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea(SessionState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             // Mic button and Camera state button
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 if (state.cameraMode == CameraMode.inactive)
                   state.cameraButtonPulsing
                     ? _PulsingCameraButton(
                         onTap: () => context.read<SessionBloc>().add(CameraOpened()),
                       )
                     : IconButton(
                         icon: const Icon(Icons.camera_alt, color: Colors.white70),
                         onPressed: () => context.read<SessionBloc>().add(CameraOpened()),
                         iconSize: 28,
                       )
                 else if (state.cameraMode == CameraMode.captureReady)
                   IconButton(
                     icon: const Icon(Icons.camera, color: Colors.white, size: 40),
                     onPressed: () async {
                         final bloc = context.read<SessionBloc>();
                         final bytes = await bloc.camera.capturePhoto();
                         if (bytes != null) {
                             bloc.add(PhotoCaptured(bytes));
                         }
                     },
                   )
                 else if (state.cameraMode == CameraMode.liveStreaming)
                     const Text("Live streaming...", style: TextStyle(color: Colors.redAccent)),

                 const SizedBox(width: 16),
                 
                 PulseMicButton(
                   isActive: state.isMicActive,
                   onTap: () => context.read<SessionBloc>().add(const MicTapped()),
                 ),

                 if (state.cameraMode != CameraMode.inactive)
                   ...[
                     const SizedBox(width: 16),
                     IconButton(
                       icon: const Icon(Icons.close, color: Colors.white70),
                       onPressed: () {
                           context.read<SessionBloc>().add(CameraClosed());
                       },
                     )
                   ]
                 else 
                   const SizedBox(width: 44), // Placeholder for symmetry
               ],
             ),
             
             const SizedBox(height: 4),

             // Context label so user knows what mic tap does
             Text(
               _micHintText(state.sessionMode),
               style: TextStyle(
                 color: Colors.white.withValues(alpha: 0.45),
                 fontSize: 11,
               ),
             ),

             const SizedBox(height: 12),

             // Text input
             Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendText,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A73E8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  )
                ],
             )
          ],
        ),
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.5),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.status});
  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      SessionStatus.active => (const Color(0xFF4CAF50), 'Connected'),
      SessionStatus.connecting => (const Color(0xFFFFC107), 'Connecting…'),
      SessionStatus.error => (const Color(0xFFE53935), 'Error'),
      _ => (Colors.grey, ''),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// Animated camera button that pulses with a blue glow when Dr. Muhammad
/// has requested the camera.
class _PulsingCameraButton extends StatefulWidget {
  const _PulsingCameraButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PulsingCameraButton> createState() => _PulsingCameraButtonState();
}

class _PulsingCameraButtonState extends State<_PulsingCameraButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.7 * _scale.value),
                  blurRadius: 18 * _scale.value,
                  spreadRadius: 4 * _scale.value,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Color(0xFF1A73E8)),
              onPressed: widget.onTap,
              iconSize: 26,
            ),
          ),
        );
      },
    );
  }
}
