import 'package:flutter/material.dart';
import 'package:medlens_mobile/models/citation_model.dart';

/// Tappable citation chip — shows source name, opens a bottom sheet on tap.
class CitationChip extends StatelessWidget {
  const CitationChip({super.key, required this.citation});

  final CitationModel citation;

  @override
  Widget build(BuildContext context) {
    final label = citation.source.isNotEmpty
        ? '${citation.source}${citation.section.isNotEmpty ? ' ${citation.section}' : ''}'
        : 'Source';

    return GestureDetector(
      onTap: () => _showCitationSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A73E8), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded,
                color: Color(0xFF1A73E8), size: 14),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1A73E8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCitationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Source title
            Text(
              citation.source.isNotEmpty ? citation.source : 'Citation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // Section
            if (citation.section.isNotEmpty) ...[
              Text(
                citation.section,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],

            // URL
            if (citation.url.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.link, color: Color(0xFF1A73E8), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      citation.url,
                      style: const TextStyle(
                        color: Color(0xFF1A73E8),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

            // Confidence
            const SizedBox(height: 12),
            Text(
              'Confidence: ${(citation.confidence * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
