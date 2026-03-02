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
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      label: json['label'] as String?,
      severity: json['severity'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, x, y, width, height, label, severity];
}
