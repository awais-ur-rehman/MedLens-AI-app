import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:medlens_mobile/config/theme.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';

/// A list tile summarising a past session.
///
/// Shows date, injury type, and a severity-coloured pill badge.
/// Calls [onTap] when the user taps it and [onDelete] on swipe-to-dismiss.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.summary,
    required this.onTap,
    this.onDelete,
  });

  final CareSummaryModel summary;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat.yMMMd().add_jm().format(summary.timestamp);
    final color = MedLensTheme.severityColor(summary.severity);
    final severityLabel = switch (summary.severity.toLowerCase()) {
      'high' => 'Seek Help',
      'medium' => 'Moderate',
      _ => 'Low Risk',
    };

    final tile = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Severity dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),

              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.injuryType.isNotEmpty
                          ? summary.injuryType
                          : 'Session',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: MedLensTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 13,
                        color: MedLensTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Severity badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  severityLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: MedLensTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap in Dismissible if onDelete is provided
    if (onDelete != null) {
      return Dismissible(
        key: ValueKey(summary.sessionId),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: MedLensTheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: MedLensTheme.error,
          ),
        ),
        onDismissed: (_) => onDelete!(),
        child: tile,
      );
    }

    return tile;
  }
}
