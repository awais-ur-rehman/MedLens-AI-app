import 'package:equatable/equatable.dart';

/// A single transcript message from user or agent.
class MessageModel extends Equatable {
  final String text;
  final String speaker; // "user" or "agent"
  final DateTime timestamp;

  const MessageModel({
    required this.text,
    required this.speaker,
    required this.timestamp,
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
  }) {
    return MessageModel(
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [text, speaker, timestamp];
}
