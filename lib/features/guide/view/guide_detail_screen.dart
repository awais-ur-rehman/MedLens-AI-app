import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:medlens_mobile/config/theme.dart';
import 'package:medlens_mobile/features/guide/data/guide_data.dart';
import 'package:medlens_mobile/models/guide_entry.dart';

/// Full step-by-step first-aid detail screen for a single [GuideEntry].
class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context) {
    final entry = guideEntries.firstWhere(
      (e) => e.id == entryId,
      orElse: () => guideEntries.first,
    );

    final severityColor = _severityColor(entry.severity);
    final severityLabel = _severityLabel(entry.severity);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero SliverAppBar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: MedLensTheme.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.goNamed('guide'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      entry.color.withValues(alpha: 0.25),
                      MedLensTheme.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Severity badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: severityColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            severityLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: severityColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color:
                                    entry.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(entry.icon,
                                  color: entry.color, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                entry.title,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: MedLensTheme.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      entry.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: MedLensTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),

                  // Quick action banner
                  _QuickActionBanner(entry: entry),
                  const SizedBox(height: 20),

                  // Steps
                  _Section(
                    icon: Icons.checklist_rounded,
                    iconColor: MedLensTheme.secondary,
                    title: 'What To Do',
                    child: _NumberedSteps(steps: entry.steps),
                  ),
                  const SizedBox(height: 16),

                  // Do NOT list
                  _Section(
                    icon: Icons.block_rounded,
                    iconColor: MedLensTheme.error,
                    title: 'Do NOT',
                    child: _DoNotList(items: entry.doNot),
                  ),
                  const SizedBox(height: 16),

                  // Emergency tip (if present)
                  if (entry.emergencyTip != null) ...[
                    _EmergencyTipCard(tip: entry.emergencyTip!),
                    const SizedBox(height: 16),
                  ],

                  // CTA buttons
                  if (entry.callEmergency)
                    _CallButton(
                      label: 'Call 911',
                      number: 'tel:911',
                      color: MedLensTheme.error,
                    ),
                  if (entry.id == 'poisoning' || entry.id == 'snake_bite') ...[
                    const SizedBox(height: 10),
                    _CallButton(
                      label: 'US Poison Control: 1-800-222-1222',
                      number: 'tel:18002221222',
                      color: MedLensTheme.warning,
                    ),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => context.goNamed('session'),
                    icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 20),
                    label: const Text(
                        'Get Real-Time Help from Dr. Muhammad'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _severityColor(String s) => switch (s) {
        'critical' => MedLensTheme.error,
        'high' => MedLensTheme.warning,
        _ => MedLensTheme.secondary,
      };

  static String _severityLabel(String s) => switch (s) {
        'critical' => '● CRITICAL',
        'high' => '● HIGH',
        _ => '● MEDIUM',
      };
}

// =====================================================================
//  Quick action banner
// =====================================================================

class _QuickActionBanner extends StatelessWidget {
  const _QuickActionBanner({required this.entry});
  final GuideEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: entry.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.flash_on_rounded, color: entry.color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUICK ACTION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: entry.color,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.tldr,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: MedLensTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  Section card
// =====================================================================

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MedLensTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MedLensTheme.divider),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MedLensTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// =====================================================================
//  Numbered steps
// =====================================================================

class _NumberedSteps extends StatelessWidget {
  const _NumberedSteps({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MedLensTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MedLensTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i],
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: MedLensTheme.textPrimary,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// =====================================================================
//  Do NOT list
// =====================================================================

class _DoNotList extends StatelessWidget {
  const _DoNotList({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 16,
                      color: MedLensTheme.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: MedLensTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// =====================================================================
//  Emergency tip card
// =====================================================================

class _EmergencyTipCard extends StatelessWidget {
  const _EmergencyTipCard({required this.tip});
  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MedLensTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MedLensTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.call_rounded,
              size: 18, color: MedLensTheme.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What to tell 911',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MedLensTheme.warning,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: MedLensTheme.textSecondary,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  Call button
// =====================================================================

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.label,
    required this.number,
    required this.color,
  });

  final String label;
  final String number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () async {
          final uri = Uri.parse(number);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.call_rounded, size: 20),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
