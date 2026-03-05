import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:medlens_mobile/config/theme.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';
import 'package:medlens_mobile/features/summary/bloc/summary_bloc.dart';

/// Post-session care summary screen.
///
/// Reads the [CareSummaryModel] from [SummaryBloc] and displays it in a
/// scrollable card layout with share and new-session actions.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SummaryBloc, SummaryState>(
      builder: (context, state) {
        final summary = state.summary;

        if (summary == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Care Summary')),
            body: const Center(
              child: Text('No summary available.'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Care Summary'),
            leading: IconButton(
              icon: const Icon(Icons.home_rounded),
              tooltip: 'Home',
              onPressed: () => context.goNamed('home'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share',
                onPressed: () => _shareSummary(summary),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // 1 ── Header card ──────────────────────────────────────
              _HeaderCard(summary: summary),
              const SizedBox(height: 12),

              // 2 ── What happened ────────────────────────────────────
              _SectionCard(
                icon: Icons.description_rounded,
                title: 'What Happened',
                child: Text(
                  summary.patientDescription,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: MedLensTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3 ── Steps taken ──────────────────────────────────────
              if (summary.actionsTaken.isNotEmpty) ...[
                _SectionCard(
                  icon: Icons.checklist_rounded,
                  title: 'Steps Taken',
                  child: _NumberedList(items: summary.actionsTaken),
                ),
                const SizedBox(height: 12),
              ],

              // 4 ── Medications ──────────────────────────────────────
              if (summary.medicationsDiscussed.isNotEmpty) ...[
                _SectionCard(
                  icon: Icons.medication_rounded,
                  title: 'Medications Discussed',
                  child: _BulletList(items: summary.medicationsDiscussed),
                ),
                const SizedBox(height: 12),
              ],

              // 5 ── Follow up ────────────────────────────────────────
              if (summary.followUpRecommendations.isNotEmpty) ...[
                _SectionCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Follow Up',
                  child: _BulletList(items: summary.followUpRecommendations),
                ),
                const SizedBox(height: 12),
              ],

              // 6 ── Warning signs ────────────────────────────────────
              if (summary.warningSigns.isNotEmpty) ...[
                _WarningCard(signs: summary.warningSigns),
                const SizedBox(height: 12),
              ],

              // 7 ── Disclaimer ───────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  summary.disclaimer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MedLensTheme.textHint,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 8 ── Buttons ──────────────────────────────────────────
              ElevatedButton.icon(
                onPressed: () => context.goNamed('home'),
                icon: const Icon(Icons.home_rounded, size: 20),
                label: const Text('Back to Home'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.goNamed('session'),
                icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                label: const Text('Start New Session'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => _shareSummary(summary),
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share Summary'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Share helper ─────────────────────────────────────────────────

  void _shareSummary(CareSummaryModel s) {
    final date = DateFormat.yMMMd().add_jm().format(s.timestamp);
    final buf = StringBuffer()
      ..writeln('🩺 MedLens AI — Care Summary')
      ..writeln('Date: $date')
      ..writeln('Injury: ${s.injuryType} (${s.severity})')
      ..writeln()
      ..writeln('▸ What Happened')
      ..writeln(s.patientDescription)
      ..writeln();

    if (s.actionsTaken.isNotEmpty) {
      buf.writeln('▸ Steps Taken');
      for (var i = 0; i < s.actionsTaken.length; i++) {
        buf.writeln('  ${i + 1}. ${s.actionsTaken[i]}');
      }
      buf.writeln();
    }

    if (s.medicationsDiscussed.isNotEmpty) {
      buf.writeln('▸ Medications Discussed');
      for (final m in s.medicationsDiscussed) {
        buf.writeln('  • $m');
      }
      buf.writeln();
    }

    if (s.followUpRecommendations.isNotEmpty) {
      buf.writeln('▸ Follow Up');
      for (final r in s.followUpRecommendations) {
        buf.writeln('  • $r');
      }
      buf.writeln();
    }

    if (s.warningSigns.isNotEmpty) {
      buf.writeln('⚠️ Warning Signs');
      for (final w in s.warningSigns) {
        buf.writeln('  • $w');
      }
      buf.writeln();
    }

    buf.writeln(s.disclaimer);

    Share.share(buf.toString());
  }
}

// =====================================================================
//  Header card
// =====================================================================

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.summary});
  final CareSummaryModel summary;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_jm().format(summary.timestamp);
    final severityColor = MedLensTheme.severityColor(summary.severity);
    final severityLabel = switch (summary.severity.toLowerCase()) {
      'high' => '⚠ Seek Help',
      'medium' => 'Moderate',
      _ => 'Low Risk',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Session Complete" header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: MedLensTheme.secondary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: MedLensTheme.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Session Complete',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MedLensTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Date
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 16, color: MedLensTheme.textHint),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: MedLensTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Injury type + severity badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.injuryType,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MedLensTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    severityLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  Generic section card
// =====================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: MedLensTheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MedLensTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

// =====================================================================
//  Warning card (red-tinted)
// =====================================================================

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.signs});
  final List<String> signs;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: MedLensTheme.error.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: MedLensTheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 22, color: MedLensTheme.error),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Warning Signs',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: MedLensTheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Seek emergency care if you notice any of these:',
              style: TextStyle(
                fontSize: 13,
                color: MedLensTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            ...signs.map(
              (sign) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.error_outline_rounded,
                          size: 16, color: MedLensTheme.error),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        sign,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: MedLensTheme.textPrimary,
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
    );
  }
}

// =====================================================================
//  List helpers
// =====================================================================

class _NumberedList extends StatelessWidget {
  const _NumberedList({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MedLensTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MedLensTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: MedLensTheme.textPrimary,
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

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 6, color: MedLensTheme.textHint),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: MedLensTheme.textPrimary,
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
