import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medlens_mobile/features/session/bloc/session_event.dart';
import 'package:medlens_mobile/features/session/bloc/session_state.dart';

/// Session Bloc — orchestrates the live session lifecycle.
///
/// Manages WebSocket connection, audio/camera streaming,
/// server message routing, and barge-in handling.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc() : super(const SessionState()) {
    on<SessionStarted>(_onSessionStarted);
    on<SessionEnded>(_onSessionEnded);
    on<AudioChunkReceived>(_onAudioChunk);
    on<CameraFrameCaptured>(_onCameraFrame);
    on<ServerMessageReceived>(_onServerMessage);
    on<ServerAudioReceived>(_onServerAudio);
    on<BargeInTriggered>(_onBargeIn);
    on<TextMessageSent>(_onTextMessage);
  }

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.connecting));
    // TODO: Connect WebSocket, start audio, start camera
  }

  Future<void> _onSessionEnded(
    SessionEnded event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.ending));
    // TODO: Disconnect WebSocket, stop audio, stop camera
    emit(state.copyWith(status: SessionStatus.ended));
  }

  void _onAudioChunk(AudioChunkReceived event, Emitter<SessionState> emit) {
    // TODO: Forward audio chunk to WebSocket
  }

  void _onCameraFrame(CameraFrameCaptured event, Emitter<SessionState> emit) {
    // TODO: Forward camera frame to WebSocket
  }

  void _onServerMessage(
    ServerMessageReceived event,
    Emitter<SessionState> emit,
  ) {
    // TODO: Route server messages (transcript, assessment, overlay, etc.)
  }

  void _onServerAudio(ServerAudioReceived event, Emitter<SessionState> emit) {
    // TODO: Play audio chunk through speaker
  }

  void _onBargeIn(BargeInTriggered event, Emitter<SessionState> emit) {
    // TODO: Stop playback, send barge-in to server
  }

  void _onTextMessage(TextMessageSent event, Emitter<SessionState> emit) {
    // TODO: Send text to WebSocket
  }

  @override
  Future<void> close() {
    // TODO: Dispose resources
    return super.close();
  }
}
