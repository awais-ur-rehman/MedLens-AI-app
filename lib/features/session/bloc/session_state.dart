import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:medlens_mobile/models/assessment_model.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';
import 'package:medlens_mobile/models/citation_model.dart';
import 'package:medlens_mobile/models/message_model.dart';
import 'package:medlens_mobile/models/overlay_model.dart';

/// Session connection lifecycle.
enum SessionStatus { initial, connecting, connected, active, ending, ended, error }

/// Agent speaking / listening state.
enum SessionMode { idle, doctorSpeaking, userSpeaking, thinking }

/// Camera UI state.
enum CameraMode { inactive, captureReady, liveStreaming }

/// State for the Session Bloc.
final class SessionState extends Equatable {
  final SessionStatus status;
  final SessionMode sessionMode;
  final CameraMode cameraMode;
  final String sessionId;
  final List<MessageModel> transcript;
  final AssessmentModel? currentAssessment;
  final List<OverlayModel> overlays;
  final List<CitationModel> citations;
  final CareSummaryModel? careSummary;
  final String? errorMessage;
  final bool isMicActive;
  final bool isCameraActive;
  final bool isAgentTurnActive;
  final Uint8List? lastCapturedImage;
  final bool cameraButtonPulsing;
  final bool cameraInitializing;

  const SessionState({
    this.status = SessionStatus.initial,
    this.sessionMode = SessionMode.idle,
    this.cameraMode = CameraMode.inactive,
    this.sessionId = '',
    this.transcript = const [],
    this.currentAssessment,
    this.overlays = const [],
    this.citations = const [],
    this.careSummary,
    this.errorMessage,
    this.isMicActive = false,
    this.isCameraActive = false,
    this.isAgentTurnActive = false,
    this.lastCapturedImage,
    this.cameraButtonPulsing = false,
    this.cameraInitializing = false,
  });

  SessionState copyWith({
    SessionStatus? status,
    SessionMode? sessionMode,
    CameraMode? cameraMode,
    String? sessionId,
    List<MessageModel>? transcript,
    AssessmentModel? currentAssessment,
    List<OverlayModel>? overlays,
    List<CitationModel>? citations,
    CareSummaryModel? careSummary,
    String? errorMessage,
    bool? isMicActive,
    bool? isCameraActive,
    bool? isAgentTurnActive,
    Uint8List? lastCapturedImage,
    bool? cameraButtonPulsing,
    bool? cameraInitializing,
  }) =>
      SessionState(
        status: status ?? this.status,
        sessionMode: sessionMode ?? this.sessionMode,
        cameraMode: cameraMode ?? this.cameraMode,
        sessionId: sessionId ?? this.sessionId,
        transcript: transcript ?? this.transcript,
        currentAssessment: currentAssessment ?? this.currentAssessment,
        overlays: overlays ?? this.overlays,
        citations: citations ?? this.citations,
        careSummary: careSummary ?? this.careSummary,
        errorMessage: errorMessage ?? this.errorMessage,
        isMicActive: isMicActive ?? this.isMicActive,
        isCameraActive: isCameraActive ?? this.isCameraActive,
        isAgentTurnActive: isAgentTurnActive ?? this.isAgentTurnActive,
        lastCapturedImage: lastCapturedImage ?? this.lastCapturedImage,
        cameraButtonPulsing: cameraButtonPulsing ?? this.cameraButtonPulsing,
        cameraInitializing: cameraInitializing ?? this.cameraInitializing,
      );

  @override
  List<Object?> get props => [
        status,
        sessionMode,
        cameraMode,
        sessionId,
        transcript,
        currentAssessment,
        overlays,
        citations,
        careSummary,
        errorMessage,
        isMicActive,
        isCameraActive,
        isAgentTurnActive,
        lastCapturedImage,
        cameraButtonPulsing,
        cameraInitializing,
      ];
}
