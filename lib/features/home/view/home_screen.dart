import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:medlens_mobile/config/theme.dart';
import 'package:medlens_mobile/features/history/bloc/history_bloc.dart';
import 'package:medlens_mobile/features/summary/bloc/summary_bloc.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';

/// Home screen — dark-themed landing page with action grid and recent sessions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(const HistoryLoaded());
  }

  // ── Permissions ─────────────────────────────────────────────────────

  Future<bool> _checkPermissions(BuildContext context) async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;

    if (camera.isGranted && mic.isGranted) return true;

    final results = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraOk = results[Permission.camera]?.isGranted ?? false;
    final micOk = results[Permission.microphone]?.isGranted ?? false;

    if (cameraOk && micOk) return true;

    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: MedLensTheme.warning),
              SizedBox(width: 12),
              Text('Permissions Required'),
            ],
          ),
          content: const Text(
            'MedLens AI needs camera and microphone access to see your '
            'injury and hear your voice so Dr. Muhammad can guide you '
            'in real time.\n\n'
            'Please grant both permissions in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    return false;
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: MedLensTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverToBoxAdapter(child: _buildHero()),
              SliverToBoxAdapter(child: _buildActionGrid(context)),
              SliverToBoxAdapter(child: _buildRecentSessions(context)),
              SliverToBoxAdapter(child: _buildDisclaimer()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: MedLensTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: MedLensTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.visibility_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'MedLens AI',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: MedLensTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              color: MedLensTheme.textSecondary,
            ),
            onPressed: () => context.goNamed('history'),
            tooltip: 'Session History',
          ),
        ],
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How can I\nhelp you today?',
            style: GoogleFonts.inter(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: MedLensTheme.textPrimary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Real-time first aid guidance from Dr. Muhammad',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: MedLensTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action grid ──────────────────────────────────────────────────────

  Widget _buildActionGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: SizedBox(
        height: 210,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Large primary tile — Start Session
            Expanded(
              flex: 3,
              child: _StartSessionTile(onPermissionsCheck: _checkPermissions),
            ),
            const SizedBox(width: 12),
            // Two small tiles stacked on the right
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SmallActionTile(
                      icon: Icons.menu_book_rounded,
                      label: 'First Aid\nGuide',
                      accentColor: MedLensTheme.accent,
                      onTap: () => context.goNamed('guide'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _SmallActionTile(
                      icon: Icons.local_hospital_rounded,
                      label: 'Find\nHospitals',
                      accentColor: MedLensTheme.secondary,
                      onTap: () => context.goNamed('hospitals'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent sessions ──────────────────────────────────────────────────

  Widget _buildRecentSessions(BuildContext context) {
    return BlocBuilder<HistoryBloc, HistoryState>(
      builder: (context, state) {
        if (state.status != HistoryStatus.loaded || state.summaries.isEmpty) {
          return const SizedBox.shrink();
        }

        final recent = state.summaries.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Recent Sessions',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MedLensTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.goNamed('history'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'See all',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: MedLensTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: MedLensTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MedLensTheme.divider),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    _SessionRow(
                      summary: recent[i],
                      onTap: () {
                        context
                            .read<SummaryBloc>()
                            .add(SummaryLoaded(recent[i]));
                        context.goNamed('summary');
                      },
                    ),
                    if (i < recent.length - 1)
                      const Divider(height: 1, indent: 60),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Disclaimer ───────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
      child: Text(
        'MedLens AI provides first aid guidance only. '
        'Not a substitute for professional medical care.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: MedLensTheme.textHint,
          height: 1.5,
        ),
      ),
    );
  }
}

// =====================================================================
//  Start Session tile (large, gradient)
// =====================================================================

class _StartSessionTile extends StatefulWidget {
  const _StartSessionTile({required this.onPermissionsCheck});
  final Future<bool> Function(BuildContext) onPermissionsCheck;

  @override
  State<_StartSessionTile> createState() => _StartSessionTileState();
}

class _StartSessionTileState extends State<_StartSessionTile> {
  bool _loading = false;

  Future<void> _onTap() async {
    if (_loading) return;
    setState(() => _loading = true);

    final ok = await widget.onPermissionsCheck(context);

    if (mounted) {
      setState(() => _loading = false);
      if (ok) context.goNamed('session');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          gradient: MedLensTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: MedLensTheme.primary.withValues(alpha: 0.30),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
            const Spacer(),
            Text(
              'Start\nSession',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Talk to Dr. Muhammad',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  Small action tile (Guide / Hospitals)
// =====================================================================

class _SmallActionTile extends StatelessWidget {
  const _SmallActionTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: MedLensTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MedLensTheme.divider),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MedLensTheme.textPrimary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  Recent session row
// =====================================================================

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.summary, required this.onTap});
  final CareSummaryModel summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.MMMd().format(summary.timestamp);
    final severityColor = MedLensTheme.severityColor(summary.severity);
    final label = summary.injuryType.isEmpty ? 'Session' : summary.injuryType;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medical_information_rounded,
                color: severityColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: MedLensTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: MedLensTheme.textHint,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summary.severity,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: severityColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: MedLensTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
