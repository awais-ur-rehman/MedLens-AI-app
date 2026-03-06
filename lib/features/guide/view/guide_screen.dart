import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:medlens_mobile/config/theme.dart';
import 'package:medlens_mobile/features/guide/data/guide_data.dart';
import 'package:medlens_mobile/models/guide_entry.dart';

/// First Aid Guide screen — 2-column grid of 12 critical first-aid scenarios.
///
/// Tap any card to open the full step-by-step [GuideDetailScreen].
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String _filter = 'all'; // 'all' | 'critical' | 'high' | 'medium'

  List<GuideEntry> get _filtered => _filter == 'all'
      ? guideEntries
      : guideEntries.where((e) => e.severity == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Aid Guide'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: MedLensTheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MedLensTheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: MedLensTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap a scenario for step-by-step guidance. '
                    'For real-time help, start a session with Dr. Muhammad.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: MedLensTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == 'all',
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Critical',
                  color: MedLensTheme.error,
                  selected: _filter == 'critical',
                  onTap: () => setState(() => _filter = 'critical'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'High',
                  color: MedLensTheme.warning,
                  selected: _filter == 'high',
                  onTap: () => setState(() => _filter = 'high'),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No scenarios found.',
                      style: GoogleFonts.inter(color: MedLensTheme.textHint),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) =>
                        _ScenarioCard(entry: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  Filter chip
// =====================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? MedLensTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.15)
              : MedLensTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : MedLensTheme.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? activeColor : MedLensTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  Scenario card
// =====================================================================

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.entry});
  final GuideEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCritical = entry.severity == 'critical';

    return GestureDetector(
      onTap: () => context.goNamed(
        'guide_detail',
        pathParameters: {'id': entry.id},
      ),
      child: Container(
        decoration: BoxDecoration(
          color: MedLensTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCritical
                ? entry.color.withValues(alpha: 0.25)
                : MedLensTheme.divider,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + severity dot
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: entry.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(entry.icon, color: entry.color, size: 22),
                ),
                const Spacer(),
                if (isCritical)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: entry.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              entry.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MedLensTheme.textPrimary,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              entry.tldr,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: entry.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
