import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:medlens_mobile/config/theme.dart';

/// First Aid Guide screen — interactive reference cards for 12 critical scenarios.
///
/// Day 3 implementation: full content. This stub shows the layout skeleton.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  static const _scenarios = [
    _Scenario(
      icon: Icons.local_fire_department_rounded,
      title: 'Burns',
      subtitle: 'Heat, chemical, electrical',
      color: Color(0xFFEF4444),
    ),
    _Scenario(
      icon: Icons.water_drop_rounded,
      title: 'Bleeding',
      subtitle: 'Cuts, lacerations, wounds',
      color: Color(0xFFDC2626),
    ),
    _Scenario(
      icon: Icons.air_rounded,
      title: 'Choking',
      subtitle: 'Airway obstruction',
      color: Color(0xFFF59E0B),
    ),
    _Scenario(
      icon: Icons.favorite_rounded,
      title: 'Cardiac Arrest',
      subtitle: 'CPR & AED guidance',
      color: Color(0xFFEF4444),
    ),
    _Scenario(
      icon: Icons.psychology_rounded,
      title: 'Stroke',
      subtitle: 'FAST recognition',
      color: Color(0xFF8B5CF6),
    ),
    _Scenario(
      icon: Icons.warning_rounded,
      title: 'Anaphylaxis',
      subtitle: 'Severe allergic reaction',
      color: Color(0xFFF59E0B),
    ),
    _Scenario(
      icon: Icons.broken_image_rounded,
      title: 'Fractures',
      subtitle: 'Broken bones & splinting',
      color: Color(0xFF6366F1),
    ),
    _Scenario(
      icon: Icons.thermostat_rounded,
      title: 'Heat Stroke',
      subtitle: 'Hyperthermia management',
      color: Color(0xFFF97316),
    ),
    _Scenario(
      icon: Icons.ac_unit_rounded,
      title: 'Hypothermia',
      subtitle: 'Cold exposure & frostbite',
      color: Color(0xFF06B6D4),
    ),
    _Scenario(
      icon: Icons.electric_bolt_rounded,
      title: 'Electric Shock',
      subtitle: 'Electrical injury response',
      color: Color(0xFFFACC15),
    ),
    _Scenario(
      icon: Icons.waves_rounded,
      title: 'Drowning',
      subtitle: 'Near-drowning rescue',
      color: Color(0xFF3B82F6),
    ),
    _Scenario(
      icon: Icons.bug_report_rounded,
      title: 'Poisoning',
      subtitle: 'Ingestion & toxic exposure',
      color: Color(0xFF10B981),
    ),
  ];

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
          // Header info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MedLensTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MedLensTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: MedLensTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any scenario to see step-by-step guidance, '
                    'or start a session to get real-time help from Dr. Muhammad.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: MedLensTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: _scenarios.length,
              itemBuilder: (context, i) =>
                  _ScenarioCard(scenario: _scenarios[i]),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
//  Scenario card
// =====================================================================

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});
  final _Scenario scenario;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Day 3: navigate to scenario detail screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${scenario.title} guide — coming in Day 3!'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: MedLensTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MedLensTheme.divider),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scenario.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(scenario.icon, color: scenario.color, size: 24),
            ),
            const Spacer(),
            Text(
              scenario.title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: MedLensTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              scenario.subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: MedLensTheme.textHint,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Scenario {
  const _Scenario({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}
