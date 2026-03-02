import 'package:equatable/equatable.dart';

/// A grounding citation from RAG or Google Search.
class CitationModel extends Equatable {
  final String source;
  final String section;
  final String url;
  final double confidence;

  const CitationModel({
    required this.source,
    required this.section,
    required this.url,
    required this.confidence,
  });

  factory CitationModel.fromJson(Map<String, dynamic> json) {
    return CitationModel(
      source: json['source'] as String? ?? '',
      section: json['section'] as String? ?? '',
      url: json['url'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [source, section, url, confidence];
}
