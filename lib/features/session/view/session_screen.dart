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

/// Main live-session screen.
///
/// Full-screen stack: camera preview → overlay painter → UI controls.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  @override
  void initState() {
    super.initState();
    // Start session when screen opens.
    context.read<SessionBloc>().add(SessionStarted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == SessionStatus.ended) {
          context.goNamed('summary');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<SessionBloc, SessionState>(
          builder: (context, state) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ---- Camera preview (full screen) ----
                _buildCameraPreview(),

                // ---- Overlay painter ----
                if (state.overlays.isNotEmpty)
                  CustomPaint(
                    painter: OverlayPainter(overlays: state.overlays),
                    size: Size.infinite,
                  ),

                // ---- Top bar ----
                _buildTopBar(state),

                // ---- Bottom transcript panel ----
                _buildBottomPanel(state),

                // ---- Pulse mic button ----
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: PulseMicButton(
                      isActive: state.isMicActive,
                      onTap: () {
                        if (state.agentStatus == AgentSpeaking.speaking) {
                          context.read<SessionBloc>().add(BargeInTriggered());
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  //  Camera preview
  // ---------------------------------------------------------------

  Widget _buildCameraPreview() {
    // TODO: Wire CameraService.controller into a CameraPreview widget.
    return Container(color: Colors.black);
  }

  // ---------------------------------------------------------------
  //  Top bar
  // ---------------------------------------------------------------

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
              // End session button
              _TopBarButton(
                icon: Icons.close,
                onTap: () =>
                    context.read<SessionBloc>().add(SessionEnded()),
              ),

              const Spacer(),

              // Connection status indicator
              _ConnectionDot(status: state.status),

              const Spacer(),

              // Dr. Muhammad avatar
              DrMuhammadAvatar(agentStatus: state.agentStatus),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  //  Bottom panel (transcript + citations + severity badge)
  // ---------------------------------------------------------------

  Widget _buildBottomPanel(SessionState state) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100, // Room for the mic button
      height: MediaQuery.of(context).size.height * 0.35,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Color(0xCC000000),
              Color(0xCC000000),
            ],
            stops: [0.0, 0.2, 1.0],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 32), // Gradient fade zone

            // Severity badge
            if (state.currentAssessment != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SeverityBadge(
                    severity: state.currentAssessment!.severity),
              ),

            // Transcript
            Expanded(
              child: TranscriptPanel(messages: state.transcript),
            ),

            // Citation chips
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
      ),
    );
  }
}

// =================================================================
//  Small private sub-widgets (kept here — too small to extract)
// =================================================================

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
