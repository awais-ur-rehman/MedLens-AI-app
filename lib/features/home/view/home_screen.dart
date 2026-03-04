import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:medlens_mobile/config/theme.dart';

/// Home screen — calming landing page with branding & session entry point.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ------------------------------------------------------------------
  //  Permissions
  // ------------------------------------------------------------------

  Future<bool> _checkPermissions(BuildContext context) async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;

    if (camera.isGranted && mic.isGranted) return true;

    // Request both at once.
    final results = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraOk = results[Permission.camera]?.isGranted ?? false;
    final micOk = results[Permission.microphone]?.isGranted ?? false;

    if (cameraOk && micOk) return true;

    // Show explanation dialog if denied.
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

  // ------------------------------------------------------------------
  //  Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              // ── Top section (logo + tagline) ──────────────────────
              const Spacer(flex: 2),
              _buildLogo(),
              const SizedBox(height: 12),
              const Text(
                'MedLens AI',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: MedLensTheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'See it. Speak it. Save it.',
                style: TextStyle(
                  fontSize: 16,
                  color: MedLensTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),

              // ── Middle section (description + feature icons) ─────
              const Spacer(flex: 2),
              Text(
                'Your real-time first aid companion.\n'
                'Point your camera at an injury and '
                'Dr. Muhammad will guide you step by step.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: MedLensTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              const _FeatureRow(),
              const Spacer(flex: 3),

              // ── Bottom section (buttons + disclaimer) ────────────
              _StartSessionButton(onPermissionsCheck: _checkPermissions),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.goNamed('history'),
                child: const Text('View History'),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'MedLens AI provides first aid guidance only. '
                  'Not a substitute for professional medical care.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: MedLensTheme.textHint,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  //  Logo composite: medical cross + eye
  // ------------------------------------------------------------------

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A73E8),
            Color(0xFF4E9BF5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MedLensTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          // Medical cross
          Icon(
            Icons.add_rounded,
            color: Colors.white24,
            size: 64,
          ),
          // Camera / eye icon
          Icon(
            Icons.visibility_rounded,
            color: Colors.white,
            size: 38,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  Feature icons row
// =====================================================================

class _FeatureRow extends StatelessWidget {
  const _FeatureRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FeatureItem(
          icon: Icons.visibility_rounded,
          label: 'Sees',
        ),
        SizedBox(width: 36),
        _FeatureItem(
          icon: Icons.hearing_rounded,
          label: 'Listens',
        ),
        SizedBox(width: 36),
        _FeatureItem(
          icon: Icons.record_voice_over_rounded,
          label: 'Guides',
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: MedLensTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: MedLensTheme.primary, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: MedLensTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
//  Start Session button with animated shimmer on press
// =====================================================================

class _StartSessionButton extends StatefulWidget {
  const _StartSessionButton({required this.onPermissionsCheck});
  final Future<bool> Function(BuildContext) onPermissionsCheck;

  @override
  State<_StartSessionButton> createState() => _StartSessionButtonState();
}

class _StartSessionButtonState extends State<_StartSessionButton> {
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
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _onTap,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Start Session',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
