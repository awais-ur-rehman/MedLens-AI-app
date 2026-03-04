import 'package:flutter/material.dart';
import 'package:medlens_mobile/models/overlay_model.dart';

/// Paints injury-annotation overlays on top of the camera preview.
///
/// Coordinates in [OverlayModel] are normalised (0.0–1.0), so they are
/// scaled to the actual canvas size before drawing.
class OverlayPainter extends CustomPainter {
  const OverlayPainter({required this.overlays});

  final List<OverlayModel> overlays;

  @override
  void paint(Canvas canvas, Size size) {
    for (final overlay in overlays) {
      final rect = Rect.fromLTWH(
        overlay.x * size.width,
        overlay.y * size.height,
        overlay.width * size.width,
        overlay.height * size.height,
      );

      final color = _colorForSeverity(overlay.severity);

      switch (overlay.type) {
        case OverlayType.highlight:
          _drawHighlight(canvas, rect, color);
        case OverlayType.arrow:
          _drawArrow(canvas, rect, color);
        case OverlayType.label:
          _drawLabel(canvas, rect, color, overlay.label ?? '');
      }
    }
  }

  // ---- highlight (rounded rect outline + tinted fill) ---------

  void _drawHighlight(Canvas canvas, Rect rect, Color color) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    // Tinted fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, borderPaint);
  }

  // ---- arrow (simple line from center-top to center) ----------

  void _drawArrow(Canvas canvas, Rect rect, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final from = Offset(rect.center.dx, rect.top);
    final to = rect.center;
    canvas.drawLine(from, to, paint);

    // Arrowhead
    const headLen = 10.0;
    canvas.drawLine(
        to, Offset(to.dx - headLen, to.dy - headLen), paint);
    canvas.drawLine(
        to, Offset(to.dx + headLen, to.dy - headLen), paint);
  }

  // ---- label (text above the rect) ---------------------------

  void _drawLabel(Canvas canvas, Rect rect, Color color, String text) {
    if (text.isEmpty) return;

    // Background pill
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 10,
        textPainter.width + 16,
        textPainter.height + 8,
      ),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      pillRect,
      Paint()..color = color.withValues(alpha: 0.85),
    );

    textPainter.paint(
      canvas,
      Offset(pillRect.left + 8, pillRect.top + 4),
    );
  }

  // ---- severity → colour mapping ----------------------------

  Color _colorForSeverity(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'high':
        return const Color(0xFFE53935);
      case 'medium':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) =>
      overlays != oldDelegate.overlays;
}
