import 'package:equatable/equatable.dart';
import 'package:medlens_mobile/models/assessment_model.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';
import 'package:medlens_mobile/models/citation_model.dart';
import 'package:medlens_mobile/models/message_model.dart';
import 'package:medlens_mobile/models/overlay_model.dart';

/// Session connection lifecycle.
enum SessionStatus { initial, connecting, connected, active, ending, ended, error }

/// Agent speaking / listening state.
enum AgentSpeaking { idle, listening, thinking, speaking }

/// State for the Session Bloc.
final class SessionState extends Equatable {
  final SessionStatus status;
  final AgentSpeaking agentStatus;
  final String sessionId;
  final List<MessageModel> transcript;
  final AssessmentModel? currentAssessment;
  final List<OverlayModel> overlays;
  final List<CitationModel> citations;
  final CareSummaryModel? careSummary;
  final String? errorMessage;
  final bool isMicActive;
  final bool isCameraActive;

  const SessionState({
    this.status = SessionStatus.initial,
    this.agentStatus = AgentSpeaking.idle,
    this.sessionId = '',
    this.transcript = const [],
    this.currentAssessment,
    this.overlays = const [],
    this.citations = const [],
    this.careSummary,
    this.errorMessage,
    this.isMicActive = false,
    this.isCameraActive = false,
  });

  SessionState copyWith({
    SessionStatus? status,
    AgentSpeaking? agentStatus,
    String? sessionId,
    List<MessageModel>? transcript,
    AssessmentModel? currentAssessment,
    List<OverlayModel>? overlays,
    List<CitationModel>? citations,
    CareSummaryModel? careSummary,
    String? errorMessage,
    bool? isMicActive,
    bool? isCameraActive,
  }) =>
      SessionState(
        status: status ?? this.status,
        agentStatus: agentStatus ?? this.agentStatus,
        sessionId: sessionId ?? this.sessionId,
        transcript: transcript ?? this.transcript,
        currentAssessment: currentAssessment ?? this.currentAssessment,
        overlays: overlays ?? this.overlays,
        citations: citations ?? this.citations,
        careSummary: careSummary ?? this.careSummary,
        errorMessage: errorMessage ?? this.errorMessage,
        isMicActive: isMicActive ?? this.isMicActive,
        isCameraActive: isCameraActive ?? this.isCameraActive,
      );

  @override
  List<Object?> get props => [
        status,
        agentStatus,
        sessionId,
        transcript,
        currentAssessment,
        overlays,
        citations,
        careSummary,
        errorMessage,
        isMicActive,
        isCameraActive,
      ];
}
