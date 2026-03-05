import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A single transcript message from user or agent.
///
/// [imageBytes] is set when the user sends a photo (JPEG bytes).
/// When set, the transcript renders an image thumbnail instead of text.
class MessageModel extends Equatable {
  final String text;
  final String speaker; // "user" or "agent"
  final DateTime timestamp;
  final Uint8List? imageBytes; // non-null for photo messages

  const MessageModel({
    required this.text,
    required this.speaker,
    required this.timestamp,
    this.imageBytes,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      text: json['text'] as String? ?? '',
      speaker: json['speaker'] as String? ?? 'agent',
      timestamp: DateTime.now(),
    );
  }

  MessageModel copyWith({
    String? text,
    String? speaker,
    DateTime? timestamp,
    Uint8List? imageBytes,
  }) {
    return MessageModel(
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      timestamp: timestamp ?? this.timestamp,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  /// True if this message is a photo-only message with no text.
  bool get isPhoto => imageBytes != null;

  @override
  // imageBytes intentionally excluded — Uint8List uses reference equality
  // which would break deduplication. The list position change is sufficient
  // to trigger a BLoC state rebuild.
  List<Object?> get props => [text, speaker, timestamp];
}
