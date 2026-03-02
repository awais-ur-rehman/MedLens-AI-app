import 'package:equatable/equatable.dart';

/// Session metadata for local storage and history.
class SessionModel extends Equatable {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? injuryType;
  final String? severity;

  const SessionModel({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.injuryType,
    this.severity,
  });

  @override
  List<Object?> get props =>
      [sessionId, startTime, endTime, injuryType, severity];
}
