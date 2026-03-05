import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
    on<CameraRequested>(_onCameraRequested);
    on<MicTapped>(_onMicTapped);
    on<CameraOpened>(_onCameraOpened);
    on<CameraInitialized>(_onCameraInitialized);
    on<PhotoCaptured>(_onPhotoCaptured);
    on<LiveStreamStarted>(_onLiveStreamStarted);
    on<LiveStreamStopped>(_onLiveStreamStopped);
    on<CameraClosed>(_onCameraClosed);
    on<AudioPlaybackFinished>(_onAudioPlaybackFinished);
  }

  final WebSocketService _ws;
  final AudioService _audio;
  final CameraService _camera;

  /// Buffer for accumulating audio chunks during an agent turn.
  final List<Uint8List> _turnAudioBuffer = [];

  /// True when the user triggered a barge-in. The next turn_complete from
  /// Gemini will be the tail of the interrupted speech — discard its audio.
  bool _bargeInActive = false;

  /// Expose camera service for providing the CameraController to the UI.
  CameraService get camera => _camera;

  StreamSubscription<Map<String, dynamic>>? _jsonSub;
  StreamSubscription<dynamic>? _audioSub;

  // ---------------------------------------------------------------
  //  SessionStarted
  // ---------------------------------------------------------------

  Future<void> _onSessionStarted(
    SessionStarted event,
    Emitter<SessionState> emit,
  ) async {
    // Cancel any orphaned subscriptions and clear stale runtime state from a
    // previous session before opening a fresh connection.
    await _jsonSub?.cancel();
    await _audioSub?.cancel();
    _jsonSub = null;
    _audioSub = null;
    _turnAudioBuffer.clear();
    _bargeInActive = false;

    emit(state.copyWith(
      status: SessionStatus.connecting,
      sessionMode: SessionMode.idle,
      isAgentTurnActive: false,
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
        sessionMode: SessionMode.idle,
        isMicActive: true,
        isCameraActive: false,
        cameraMode: CameraMode.inactive,
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
      cameraMode: CameraMode.inactive,
      sessionMode: SessionMode.idle,
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
    // Always forward mic audio when session is active.
    // Gemini Live API handles VAD and barge-in on the server side.
    // The doctorSpeaking mode is UI-only and must not block user audio.
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
    debugPrint('[MedLens] ← SERVER: $type');

    switch (type) {
      case 'session_started':
        emit(state.copyWith(sessionMode: SessionMode.idle));

      case 'transcript':
        final text = msg['text'] as String? ?? '';
        final isEscalation = msg['escalation'] as bool? ?? false;

        if (state.isAgentTurnActive) {
          // APPEND to the last agent message
          final updatedTranscript = List<MessageModel>.from(state.transcript);
          if (updatedTranscript.isNotEmpty && updatedTranscript.last.speaker == 'agent') {
            final lastMsg = updatedTranscript.last;
            updatedTranscript[updatedTranscript.length - 1] = lastMsg.copyWith(
              text: lastMsg.text + text,
            );
            emit(state.copyWith(
              transcript: updatedTranscript,
              sessionMode: SessionMode.doctorSpeaking,
            ));
          } else {
            // Edge case: turn is active but no agent message exists — start one.
            final message = MessageModel(text: text, speaker: 'agent', timestamp: DateTime.now());
            emit(state.copyWith(
              transcript: [...state.transcript, message],
              sessionMode: SessionMode.doctorSpeaking,
            ));
          }
        } else {
          // START a new agent turn
          final message = MessageModel(text: text, speaker: 'agent', timestamp: DateTime.now());
          emit(state.copyWith(
            transcript: [...state.transcript, message],
            isAgentTurnActive: true,
            sessionMode: SessionMode.doctorSpeaking,
          ));
        }

        // If escalation flag is set the UI layer should show an alert.
        if (isEscalation) {
          emit(state.copyWith(
            errorMessage: '🚨 Emergency escalation — call emergency services!',
          ));
        }

      case 'user_transcript':
        final text = msg['text'] as String? ?? '';
        if (text.isNotEmpty) {
          final message = MessageModel(
            text: text,
            speaker: 'user',
            timestamp: DateTime.now(),
          );
          // Don't change sessionMode — we stay in thinking while waiting for
          // the agent's response. Switching to userSpeaking here confused the
          // mic button and could prompt the user to tap again prematurely.
          emit(state.copyWith(
            transcript: [...state.transcript, message],
            isAgentTurnActive: false,
          ));
        }

      case 'turn_complete':
        final speaker = msg['speaker'] as String? ?? '';
        debugPrint('[MedLens] TURN_COMPLETE speaker=$speaker, audioBuffer=${_turnAudioBuffer.length} chunks, bargeIn=$_bargeInActive');
        if (speaker == 'agent') {
          // If a barge-in was active, this turn_complete is the tail of the
          // interrupted speech. Discard its audio and return to userSpeaking.
          if (_bargeInActive) {
            _turnAudioBuffer.clear();
            _bargeInActive = false;
            emit(state.copyWith(
              isAgentTurnActive: false,
              sessionMode: SessionMode.userSpeaking,
            ));
            break;
          }

          // Play the accumulated audio for this turn all at once as a continuous WAV flow.
          if (_turnAudioBuffer.isNotEmpty) {
            final totalLength = _turnAudioBuffer.fold<int>(0, (sum, chunk) => sum + chunk.length);
            final mergedAudio = Uint8List(totalLength);
            int offset = 0;
            for (final chunk in _turnAudioBuffer) {
              mergedAudio.setAll(offset, chunk);
              offset += chunk.length;
            }
            
            _audio.playWavBuffer(mergedAudio, () {
              if (!isClosed) {
                add(const AudioPlaybackFinished());
              }
            });
            _turnAudioBuffer.clear();

            emit(state.copyWith(
              isAgentTurnActive: false,
              // Keep sessionMode as doctorSpeaking until audio finishes playing!
            ));
          } else {
            // Empty turn_complete — this is Gemini acknowledging the user's
            // speech turn. The agent's actual response will arrive in the
            // next receive() iteration. Stay in thinking if we're waiting
            // for a response; only go idle if we weren't expecting one.
            if (state.sessionMode == SessionMode.thinking) {
              emit(state.copyWith(isAgentTurnActive: false));
            } else {
              emit(state.copyWith(
                isAgentTurnActive: false,
                sessionMode: SessionMode.idle,
              ));
            }
          }
        }

      case 'request_camera':
        final prompt = msg['prompt'] as String? ?? '';
        add(CameraRequested(prompt));

      case 'request_live_camera':
        final prompt = msg['prompt'] as String? ?? '';
        final duration = msg['duration_seconds'] as int? ?? 10;
        add(LiveStreamStarted(prompt, duration));

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
        // Backend sends {"type":"citation","sources":[{source,url,...},...]}
        final sources = msg['sources'] as List? ?? [];
        if (sources.isNotEmpty) {
          final newCitations = sources
              .map((s) => CitationModel.fromJson(s as Map<String, dynamic>))
              .toList();
          emit(state.copyWith(
            citations: [...state.citations, ...newCitations],
          ));
        }

      case 'care_summary':
        final data = msg['data'] as Map<String, dynamic>? ?? msg;
        emit(state.copyWith(
          careSummary: CareSummaryModel.fromJson(data),
          status: SessionStatus.ended,
          sessionMode: SessionMode.idle,
        ));

      case 'agent_thinking':
        emit(state.copyWith(sessionMode: SessionMode.thinking));

      case 'error':
        emit(state.copyWith(
          errorMessage: msg['message'] as String? ?? 'Unknown error',
        ));

      case 'session_ended':
        emit(state.copyWith(
          status: SessionStatus.ended,
          sessionMode: SessionMode.idle,
        ));

      case 'disconnected':
        debugPrint('[MedLens] ← DISCONNECTED (WebSocket closed by server)');
        if (state.status == SessionStatus.ending) {
          // Session was ending — treat disconnect as graceful end so we still
          // navigate to the summary screen (possibly with no summary data).
          emit(state.copyWith(
            status: SessionStatus.ended,
            sessionMode: SessionMode.idle,
          ));
        } else {
          emit(state.copyWith(
            status: SessionStatus.error,
            sessionMode: SessionMode.idle,
            errorMessage: 'Connection lost. Please start a new session.',
          ));
        }
    }
  }

  // ---------------------------------------------------------------
  //  ServerAudioReceived  (backend audio → speaker)
  // ---------------------------------------------------------------

  void _onServerAudio(
    ServerAudioReceived event,
    Emitter<SessionState> emit,
  ) {
    _turnAudioBuffer.add(event.audioData);
    debugPrint('[MedLens] ← AUDIO chunk ${event.audioData.length}b (buffer: ${_turnAudioBuffer.length} chunks)');
    if (state.sessionMode != SessionMode.doctorSpeaking) {
      emit(state.copyWith(sessionMode: SessionMode.doctorSpeaking));
    }
  }

  // ---------------------------------------------------------------
  //  MicTapped
  // ---------------------------------------------------------------

  Future<void> _onMicTapped(
    MicTapped event,
    Emitter<SessionState> emit,
  ) async {
    debugPrint('[MedLens] MIC TAPPED — mode=${state.sessionMode}, status=${state.status}');
    if (state.status != SessionStatus.active) {
      debugPrint('[MedLens] MIC TAPPED ignored — session not active');
      return;
    }

    if (state.sessionMode == SessionMode.doctorSpeaking) {
      // Barge-in: interrupt Dr. Muhammad
      debugPrint('[MedLens] → BARGE-IN');
      add(BargeInTriggered());
    } else if (state.sessionMode == SessionMode.userSpeaking) {
      // User taps mic again to SEND their speech
      debugPrint('[MedLens] → end_of_turn sent to backend (user finished speaking)');
      _ws.sendJson({'type': 'end_of_turn'});
      emit(state.copyWith(sessionMode: SessionMode.thinking));
    } else {
      // Idle / thinking → tap to START speaking
      debugPrint('[MedLens] → activity_start sent to backend (user starting to speak)');
      _ws.sendJson({'type': 'activity_start'});
      emit(state.copyWith(sessionMode: SessionMode.userSpeaking));
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
    _turnAudioBuffer.clear();
    _bargeInActive = true;

    // Tell the backend about the barge-in (backend no longer sends ActivityEnd
    // — auto-VAD detects the user's speech and interrupts Gemini naturally).
    _ws.sendJson({'type': 'barge_in'});

    emit(state.copyWith(sessionMode: SessionMode.userSpeaking));
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
  Future<void> close() {
    _jsonSub?.cancel();
    _audioSub?.cancel();
    _ws.disconnect();
    return super.close();
  }

  // ---------------------------------------------------------------
  //  Camera Flow
  // ---------------------------------------------------------------

  void _onCameraRequested(CameraRequested event, Emitter<SessionState> emit) {
    emit(state.copyWith(cameraButtonPulsing: true));
  }

  Future<void> _onCameraOpened(CameraOpened event, Emitter<SessionState> emit) async {
    emit(state.copyWith(cameraButtonPulsing: false, cameraInitializing: true));
    try {
      await _camera.initialize();
    } catch (e) {
      emit(state.copyWith(
        cameraInitializing: false,
        errorMessage: 'Camera failed to start: $e',
      ));
      return;
    }
    emit(state.copyWith(
      cameraMode: CameraMode.captureReady,
      isCameraActive: true,
      cameraInitializing: false,
    ));
  }

  void _onCameraInitialized(CameraInitialized event, Emitter<SessionState> emit) {
    emit(state.copyWith(cameraInitializing: false));
  }

  void _onPhotoCaptured(PhotoCaptured event, Emitter<SessionState> emit) {
    // Add a photo bubble to the transcript immediately so the user sees it.
    final photoMsg = MessageModel(
      text: '',
      speaker: 'user',
      timestamp: DateTime.now(),
      imageBytes: event.jpegFrame,
    );

    emit(state.copyWith(
      cameraMode: CameraMode.inactive,
      isCameraActive: false,
      lastCapturedImage: event.jpegFrame,
      transcript: [...state.transcript, photoMsg],
    ));

    if (state.status == SessionStatus.active) {
      // 1. Send the image to Gemini
      final b64 = base64Encode(event.jpegFrame);
      _ws.sendJson({'type': 'image_frame', 'data': b64});

      // 2. Immediately follow with a text prompt so Gemini knows to analyze it.
      //    Without this, the Live API doesn't automatically respond to a lone image.
      _ws.sendJson({
        'type': 'text',
        'content': 'I just sent you a photo. Please analyze it and provide guidance.',
      });

      // 3. Show thinking indicator while Dr. Muhammad processes the image.
      emit(state.copyWith(sessionMode: SessionMode.thinking));
    }
  }

  void _onLiveStreamStarted(LiveStreamStarted event, Emitter<SessionState> emit) {
    emit(state.copyWith(cameraMode: CameraMode.liveStreaming, isCameraActive: true));
    _camera.startLiveStream(
      onFrame: (bytes) => add(CameraFrameCaptured(bytes)),
      intervalMs: 1000,
    );
    // Auto-stop after the requested duration.
    Future.delayed(Duration(seconds: event.durationSeconds), () {
      if (!isClosed) add(LiveStreamStopped());
    });
  }

  void _onLiveStreamStopped(LiveStreamStopped event, Emitter<SessionState> emit) {
    _camera.stopLiveStream();
    emit(state.copyWith(cameraMode: CameraMode.inactive, isCameraActive: false));
  }

  void _onCameraClosed(CameraClosed event, Emitter<SessionState> emit) {
    emit(state.copyWith(cameraMode: CameraMode.inactive));
  }

  void _onAudioPlaybackFinished(AudioPlaybackFinished event, Emitter<SessionState> emit) {
    debugPrint('[MedLens] PLAYBACK FINISHED — mode was=${state.sessionMode}, now=idle');
    if (state.sessionMode == SessionMode.doctorSpeaking) {
      emit(state.copyWith(sessionMode: SessionMode.idle));
    }
  }
}
