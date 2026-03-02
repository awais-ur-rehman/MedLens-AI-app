import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Events for the Session Bloc.
sealed class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

/// Start a new session.
final class SessionStarted extends SessionEvent {}

/// End the current session.
final class SessionEnded extends SessionEvent {}

/// Received a raw audio chunk from the microphone.
final class AudioChunkReceived extends SessionEvent {
  final Uint8List chunk;
  const AudioChunkReceived(this.chunk);

  @override
  List<Object?> get props => [chunk];
}

/// Captured a JPEG camera frame.
final class CameraFrameCaptured extends SessionEvent {
  final Uint8List jpegFrame;
  const CameraFrameCaptured(this.jpegFrame);

  @override
  List<Object?> get props => [jpegFrame];
}

/// Received a JSON message from the backend.
final class ServerMessageReceived extends SessionEvent {
  final Map<String, dynamic> message;
  const ServerMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

/// Received binary audio from the backend (Gemini response).
final class ServerAudioReceived extends SessionEvent {
  final Uint8List audioData;
  const ServerAudioReceived(this.audioData);

  @override
  List<Object?> get props => [audioData];
}

/// User interrupted the agent (barge-in).
final class BargeInTriggered extends SessionEvent {}

/// User sent a text message.
final class TextMessageSent extends SessionEvent {
  final String text;
  const TextMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}
