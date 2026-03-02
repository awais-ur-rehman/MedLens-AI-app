import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medlens_mobile/features/session/bloc/session_event.dart';
import 'package:medlens_mobile/features/session/bloc/session_state.dart';
import 'package:medlens_mobile/models/assessment_model.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';
import 'package:medlens_mobile/models/citation_model.dart';
import 'package:medlens_mobile/models/message_model.dart';
import 'package:medlens_mobile/models/overlay_model.dart';
import 'package:medlens_mobile/services/audio_service.dart';
import 'package:medlens_mobile/services/camera_service.dart';
import 'package:medlens_mobile/services/websocket_service.dart';
import 'package:uuid/uuid.dart';

/// Session Bloc — orchestrates the live session lifecycle.
///
/// Manages WebSocket connection, audio/camera streaming,
/// server message routing, and barge-in handling.
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required WebSocketService webSocketService,
    required AudioService audioService,
    required CameraService cameraService,
  })  : _ws = webSocketService,
        _audio = audioService,
        _camera = cameraService,
        super(const SessionState()) {
    on<SessionStarted>(_onSessionStarted);
    on<SessionEnded>(_onSessionEnded);
    on<AudioChunkReceived>(_onAudioChunk);
    on<CameraFrameCaptured>(_onCameraFrame);
    on<ServerMessageReceived>(_onServerMessage);
    on<ServerAudioReceived>(_onServerAudio);
    on<BargeInTriggered>(_onBargeIn);
    on<TextMessageSent>(_onTextMessage);
  }

  final WebSocketService _ws;
  final AudioService _audio;
  final CameraService _camera;

  StreamSubscription<Map<String, dynamic>>? _jsonSub;
  StreamSubscription<dynamic>? _audioSub;

  // ---------------------------------------------------------------
  //  SessionStarted
  // ---------------------------------------------------------------

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(
      status: SessionStatus.connecting,
      errorMessage: null,
    ));

    try {
      // 1. Connect WebSocket
      await _ws.connect();

      // 2. Send start_session control message
      _ws.sendJson({'type': 'start_session'});

      // 3. Subscribe to incoming streams from the backend
      _jsonSub = _ws.jsonStream.listen(
        (msg) => add(ServerMessageReceived(msg)),
      );
      _audioSub = _ws.audioStream.listen(
        (bytes) => add(ServerAudioReceived(bytes)),
      );

      // 4. Start microphone recording — each chunk fires AudioChunkReceived
      await _audio.startRecording(
        onChunk: (chunk) => add(AudioChunkReceived(chunk)),
      );

      final sessionId = const Uuid().v4();

      emit(state.copyWith(
        status: SessionStatus.active,
        sessionId: sessionId,
        agentStatus: AgentSpeaking.listening,
        isMicActive: true,
        transcript: const [],
        overlays: const [],
        citations: const [],
        currentAssessment: null,
        careSummary: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: SessionStatus.error,
        errorMessage: 'Failed to start session: $e',
      ));
    }
  }

  // ---------------------------------------------------------------
  //  SessionEnded
  // ---------------------------------------------------------------

  Future<void> _onSessionEnded(
    SessionEnded event,
    Emitter<SessionState> emit,
  ) async {
    emit(state.copyWith(status: SessionStatus.ending));

    // Tell the backend to wrap up (triggers care_summary).
    _ws.sendJson({'type': 'end_session'});

    await _audio.stopRecording();
    await _audio.stopPlayback();

    emit(state.copyWith(
      isMicActive: false,
      isCameraActive: false,
      agentStatus: AgentSpeaking.idle,
    ));

    // We don't immediately set status = ended here — that happens when the
    // backend responds with the care_summary message.
  }

  // ---------------------------------------------------------------
  //  AudioChunkReceived  (mic → backend)
  // ---------------------------------------------------------------

  void _onAudioChunk(
    AudioChunkReceived event,
    Emitter<SessionState> emit,
  ) {
    if (state.status == SessionStatus.active) {
      _ws.sendBinary(event.chunk);
    }
  }

  // ---------------------------------------------------------------
  //  CameraFrameCaptured  (camera → backend as base64 JSON)
  // ---------------------------------------------------------------

  void _onCameraFrame(
    CameraFrameCaptured event,
    Emitter<SessionState> emit,
  ) {
    if (state.status == SessionStatus.active) {
      final b64 = base64Encode(event.jpegFrame);
      _ws.sendJson({
        'type': 'image_frame',
        'data': b64,
      });
    }
  }

  // ---------------------------------------------------------------
  //  ServerMessageReceived  (backend JSON → state updates)
  // ---------------------------------------------------------------

  void _onServerMessage(
    ServerMessageReceived event,
    Emitter<SessionState> emit,
  ) {
    final msg = event.message;
    final type = msg['type'] as String? ?? '';

    switch (type) {
      case 'session_started':
        emit(state.copyWith(agentStatus: AgentSpeaking.listening));

      case 'transcript':
        final text = msg['text'] as String? ?? '';
        final isEscalation = msg['escalation'] as bool? ?? false;

        final message = MessageModel(
          text: text,
          speaker: 'agent',
          timestamp: DateTime.now(),
        );

        emit(state.copyWith(
          transcript: [...state.transcript, message],
          agentStatus: AgentSpeaking.speaking,
        ));

        // If escalation flag is set the UI layer should show an alert.
        if (isEscalation) {
          emit(state.copyWith(
            errorMessage: '🚨 Emergency escalation — call emergency services!',
          ));
        }

      case 'assessment':
        final data = msg['data'] as Map<String, dynamic>? ?? msg;
        emit(state.copyWith(
          currentAssessment: AssessmentModel.fromJson(data),
        ));

      case 'overlay':
        final data = msg['data'] as Map<String, dynamic>? ?? msg;
        emit(state.copyWith(
          overlays: [...state.overlays, OverlayModel.fromJson(data)],
        ));

      case 'citation':
        final data = msg['data'] as Map<String, dynamic>? ?? msg;
        emit(state.copyWith(
          citations: [...state.citations, CitationModel.fromJson(data)],
        ));

      case 'care_summary':
        final data = msg['data'] as Map<String, dynamic>? ?? msg;
        emit(state.copyWith(
          careSummary: CareSummaryModel.fromJson(data),
          status: SessionStatus.ended,
          agentStatus: AgentSpeaking.idle,
        ));

      case 'agent_thinking':
        emit(state.copyWith(agentStatus: AgentSpeaking.thinking));

      case 'error':
        emit(state.copyWith(
          errorMessage: msg['message'] as String? ?? 'Unknown error',
        ));

      case 'session_ended':
        emit(state.copyWith(
          status: SessionStatus.ended,
          agentStatus: AgentSpeaking.idle,
        ));

      case 'disconnected':
        emit(state.copyWith(
          status: SessionStatus.ended,
          agentStatus: AgentSpeaking.idle,
          errorMessage: 'Connection lost',
        ));
    }
  }

  // ---------------------------------------------------------------
  //  ServerAudioReceived  (backend audio → speaker)
  // ---------------------------------------------------------------

  void _onServerAudio(
    ServerAudioReceived event,
    Emitter<SessionState> emit,
  ) {
    _audio.playChunk(event.audioData);
    if (state.agentStatus != AgentSpeaking.speaking) {
      emit(state.copyWith(agentStatus: AgentSpeaking.speaking));
    }
  }

  // ---------------------------------------------------------------
  //  BargeInTriggered
  // ---------------------------------------------------------------

  Future<void> _onBargeIn(
    BargeInTriggered event,
    Emitter<SessionState> emit,
  ) async {
    // Immediately cut Dr. Muhammad's audio.
    await _audio.stopPlayback();

    // Tell the backend to interrupt the model.
    _ws.sendJson({'type': 'barge_in'});

    emit(state.copyWith(agentStatus: AgentSpeaking.listening));
  }

  // ---------------------------------------------------------------
  //  TextMessageSent
  // ---------------------------------------------------------------

  void _onTextMessage(
    TextMessageSent event,
    Emitter<SessionState> emit,
  ) {
    if (state.status != SessionStatus.active) return;

    // Add the user's message to the local transcript.
    final userMsg = MessageModel(
      text: event.text,
      speaker: 'user',
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      transcript: [...state.transcript, userMsg],
    ));

    // Forward to backend.
    _ws.sendJson({'type': 'text', 'content': event.text});
  }

  // ---------------------------------------------------------------
  //  Cleanup
  // ---------------------------------------------------------------

  @override
  Future<void> close() async {
    await _jsonSub?.cancel();
    await _audioSub?.cancel();
    await _ws.disconnect();
    await _audio.dispose();
    // CameraService dispose is handled by the widget that owns the controller.
    return super.close();
  }
}
