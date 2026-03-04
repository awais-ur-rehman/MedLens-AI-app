import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:medlens_mobile/models/overlay_model.dart';

/// Paints injury-annotation overlays on top of the camera preview.
///
/// All coordinates in [OverlayModel] are normalised (0.0–1.0) and are
/// multiplied by the canvas size to get pixel positions.
///
/// Supports three overlay types:
///  - **highlight**: Semi-transparent rounded rect with severity-coloured border.
///  - **label**: White text on a semi-transparent black pill, positioned above
///    the highlight rect.
///  - **arrow**: Line from the edge of the canvas pointing at the (x, y) target.
class OverlayPainter extends CustomPainter {
  const OverlayPainter({required this.overlays});

  final List<OverlayModel> overlays;

  // Severity colours matching the user specification.
  static const _colorLow = Color(0xFF34A853);
  static const _colorMedium = Color(0xFFFBBC04);
  static const _colorHigh = Color(0xFFEA4335);

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
          // Draw label inside / above the highlight if present.
          if (overlay.label != null && overlay.label!.isNotEmpty) {
            _drawLabel(canvas, rect, color, overlay.label!);
          }
        case OverlayType.arrow:
          _drawArrow(canvas, size, rect, color);
        case OverlayType.label:
          _drawLabel(canvas, rect, color, overlay.label ?? '');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  //  Highlight — rounded rect with 30 % fill + 3 px border
  // ─────────────────────────────────────────────────────────────────

  void _drawHighlight(Canvas canvas, Rect rect, Color color) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    // 30 % opacity fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    // 3 px border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(rrect, borderPaint);
  }

  // ─────────────────────────────────────────────────────────────────
  //  Arrow — line from canvas edge → target (x, y)
  // ─────────────────────────────────────────────────────────────────

  void _drawArrow(Canvas canvas, Size size, Rect rect, Color color) {
    final target = rect.center;

    // Determine which edge is closest and draw from there.
    final fromLeft = target.dx;
    final fromRight = size.width - target.dx;
    final fromTop = target.dy;
    final fromBottom = size.height - target.dy;
    final minDist = [fromLeft, fromRight, fromTop, fromBottom].reduce(math.min);

    Offset origin;
    if (minDist == fromLeft) {
      origin = Offset(0, target.dy);
    } else if (minDist == fromRight) {
      origin = Offset(size.width, target.dy);
    } else if (minDist == fromTop) {
      origin = Offset(target.dx, 0);
    } else {
      origin = Offset(target.dx, size.height);
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Main line
    canvas.drawLine(origin, target, paint);

    // Arrowhead (two short lines at 30° from the main line)
    const headLen = 14.0;
    const headAngle = math.pi / 6; // 30 degrees
    final angle = math.atan2(
      origin.dy - target.dy,
      origin.dx - target.dx,
    );
    canvas.drawLine(
      target,
      Offset(
        target.dx + headLen * math.cos(angle + headAngle),
        target.dy + headLen * math.sin(angle + headAngle),
      ),
      paint,
    );
    canvas.drawLine(
      target,
      Offset(
        target.dx + headLen * math.cos(angle - headAngle),
        target.dy + headLen * math.sin(angle - headAngle),
      ),
      paint,
    );

    // Small target circle
    canvas.drawCircle(
      target,
      6,
      Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      target,
      6,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Label — white text on semi-transparent black pill above rect
  // ─────────────────────────────────────────────────────────────────

  void _drawLabel(Canvas canvas, Rect rect, Color color, String text) {
    if (text.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const hPad = 10.0;
    const vPad = 5.0;
    const gap = 6.0;

    final pillW = textPainter.width + hPad * 2;
    final pillH = textPainter.height + vPad * 2;

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rect.left,
        rect.top - pillH - gap,
        pillW,
        pillH,
      ),
      const Radius.circular(6),
    );

    // Semi-transparent black background
    canvas.drawRRect(
      pillRect,
      Paint()..color = const Color(0xCC000000),
    );

    // Thin left-edge accent bar
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(pillRect.left, pillRect.top, 3, pillH),
        topLeft: const Radius.circular(6),
        bottomLeft: const Radius.circular(6),
      ),
      Paint()..color = color,
    );

    textPainter.paint(
      canvas,
      Offset(pillRect.left + hPad, pillRect.top + vPad),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Severity → colour mapping
  // ─────────────────────────────────────────────────────────────────

  Color _colorForSeverity(String? severity) {
    return switch (severity?.toLowerCase()) {
      'high' => _colorHigh,
      'medium' => _colorMedium,
      _ => _colorLow,
    };
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) =>
      overlays != oldDelegate.overlays;
}
