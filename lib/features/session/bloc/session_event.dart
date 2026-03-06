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

/// Dr. Muhammad requested to see the injury.
final class CameraRequested extends SessionEvent {
  final String prompt;
  const CameraRequested(this.prompt);
  @override
  List<Object?> get props => [prompt];
}

/// User opened the camera preview.
final class CameraOpened extends SessionEvent {}

/// User captured a single high-quality photo.
final class PhotoCaptured extends SessionEvent {
  final Uint8List jpegFrame;
  const PhotoCaptured(this.jpegFrame);

  @override
  List<Object?> get props => [jpegFrame];
}

/// Dr. Muhammad requested a brief live camera feed.
final class LiveStreamStarted extends SessionEvent {
  final String prompt;
  final int durationSeconds;
  const LiveStreamStarted(this.prompt, this.durationSeconds);
  @override
  List<Object?> get props => [prompt, durationSeconds];
}

/// Live camera feed explicitly stopped.
final class LiveStreamStopped extends SessionEvent {}

/// User closed the camera preview.
final class CameraClosed extends SessionEvent {}

/// Camera finished initializing and is ready for preview.
final class CameraInitialized extends SessionEvent {
  const CameraInitialized();
}

/// User tapped the mic button.
///
/// When Dr. Muhammad is speaking → triggers barge-in.
/// Otherwise → sends an explicit end-of-turn signal so Gemini responds
/// immediately (fallback when VAD is slow to detect speech end).
final class MicTapped extends SessionEvent {
  const MicTapped();
}

/// Dr. Muhammad's voice finished playing.
final class AudioPlaybackFinished extends SessionEvent {
  const AudioPlaybackFinished();
  @override
  List<Object?> get props => [];
}

/// All active camera overlays have expired (auto-cleared after 8 s).
final class OverlaysCleared extends SessionEvent {
  const OverlaysCleared();
}
