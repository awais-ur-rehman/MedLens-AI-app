import 'package:equatable/equatable.dart';

/// Model for an injury assessment from the Visual Assessor agent.
class AssessmentModel extends Equatable {
  final String injuryType; // burn, cut, sprain, rash, bruise, unknown
  final String severity; // low, medium, high
  final String bodyLocation;
  final String description;
  final double confidence;
  final bool requiresEscalation;

  const AssessmentModel({
    required this.injuryType,
    required this.severity,
    required this.bodyLocation,
    required this.description,
    required this.confidence,
    required this.requiresEscalation,
  });

  factory AssessmentModel.fromJson(Map<String, dynamic> json) {
    return AssessmentModel(
      injuryType: json['injury_type'] as String? ?? 'unknown',
      severity: json['severity'] as String? ?? 'low',
      bodyLocation: json['body_location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      requiresEscalation: json['requires_escalation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'injury_type': injuryType,
        'severity': severity,
        'body_location': bodyLocation,
        'description': description,
        'confidence': confidence,
        'requires_escalation': requiresEscalation,
      };

  @override
  List<Object?> get props => [
        injuryType,
        severity,
        bodyLocation,
        description,
        confidence,
        requiresEscalation,
      ];
}
