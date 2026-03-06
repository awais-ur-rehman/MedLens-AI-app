import 'package:equatable/equatable.dart';

/// Overlay type for camera annotations.
enum OverlayType { highlight, arrow, label }

/// Model for visual overlays drawn on the camera preview.
class OverlayModel extends Equatable {
  final OverlayType type;
  final double x; // Normalized 0.0–1.0
  final double y;
  final double width;
  final double height;
  final String? label;
  final String? severity;

  const OverlayModel({
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.label,
    this.severity,
  });

  factory OverlayModel.fromJson(Map<String, dynamic> json) {
    return OverlayModel(
      type: OverlayType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OverlayType.highlight,
      ),
      // Coordinates are optional — backend may send region/instruction format
      // instead of pixel-normalised x/y/width/height. Default to a centred box.
      x: (json['x'] as num?)?.toDouble() ?? 0.2,
      y: (json['y'] as num?)?.toDouble() ?? 0.3,
      width: (json['width'] as num?)?.toDouble() ?? 0.6,
      height: (json['height'] as num?)?.toDouble() ?? 0.25,
      // 'instruction' (prompt format) falls back gracefully to 'label'
      label: json['label'] as String? ?? json['instruction'] as String?,
      severity: json['severity'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, x, y, width, height, label, severity];
}
