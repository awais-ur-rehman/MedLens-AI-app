import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:medlens_mobile/config/theme.dart';

/// Find Hospitals screen — opens native Maps with nearby hospital search.
///
/// Day 3 implementation: geolocator + filtered results list.
/// This version uses url_launcher to open Google Maps directly.
class HospitalsScreen extends StatelessWidget {
  const HospitalsScreen({super.key});

  Future<void> _openMaps() async {
    // Opens Google Maps with "hospitals near me" search
    final uri = Uri.parse(
      'https://www.google.com/maps/search/hospitals+near+me/',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:911');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Hospitals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Emergency banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MedLensTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MedLensTheme.error.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: MedLensTheme.error,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Life-threatening emergency?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MedLensTheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _callEmergency,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MedLensTheme.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.call_rounded, size: 20),
                      label: Text(
                        'Call 911 Now',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Map button
            Text(
              'Find Nearby Hospitals',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MedLensTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _openMaps,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: MedLensTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MedLensTheme.divider),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: MedLensTheme.secondary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.map_rounded,
                        color: MedLensTheme.secondary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Open in Maps',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: MedLensTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Hospitals near your location',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: MedLensTheme.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.local_hospital_rounded, size: 20),
              label: const Text('Find Hospitals Near Me'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.goNamed('session'),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text('Get Guidance from Dr. Muhammad'),
            ),
            const Spacer(),
            Text(
              'Always call emergency services for life-threatening situations. '
              'MedLens AI is not a substitute for emergency care.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: MedLensTheme.textHint,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
