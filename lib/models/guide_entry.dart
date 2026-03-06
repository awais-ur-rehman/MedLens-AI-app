import 'package:flutter/material.dart';

/// A single first-aid guide entry displayed in the Guide section.
class GuideEntry {
  const GuideEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.severity,
    required this.tldr,
    required this.icon,
    required this.color,
    required this.steps,
    required this.doNot,
    this.callEmergency = false,
    this.emergencyTip,
  });

  /// Unique key, used as URL path parameter.
  final String id;

  /// Display title.
  final String title;

  /// One-line context (trigger / symptoms).
  final String subtitle;

  /// Triage level: 'critical' | 'high' | 'medium'
  final String severity;

  /// 3-word action shown on grid tile (e.g. "EpiPen → 911").
  final String tldr;

  final IconData icon;
  final Color color;

  /// Ordered list of first-aid steps.
  final List<String> steps;

  /// Common dangerous mistakes to avoid.
  final List<String> doNot;

  /// Whether 911 should always be called.
  final bool callEmergency;

  /// What to say to the dispatcher (optional).
  final String? emergencyTip;
}
