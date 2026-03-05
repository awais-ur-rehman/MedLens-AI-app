import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';
import 'package:medlens_mobile/services/local_storage_service.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────── Events ──────────────────────────────────

sealed class SummaryEvent extends Equatable {
  const SummaryEvent();
  @override
  List<Object?> get props => [];
}

/// Emitted when a care summary is received (e.g. from the WebSocket).
final class SummaryLoaded extends SummaryEvent {
  const SummaryLoaded(this.summary);
  final CareSummaryModel summary;

  @override
  List<Object?> get props => [summary];
}

/// Clear the current summary (e.g. when starting a new session).
final class SummaryCleared extends SummaryEvent {
  const SummaryCleared();
}

// ─────────────────────────────────── State ───────────────────────────────────

enum SummaryStatus { initial, loaded }

final class SummaryState extends Equatable {
  const SummaryState({
    this.status = SummaryStatus.initial,
    this.summary,
  });

  final SummaryStatus status;
  final CareSummaryModel? summary;

  SummaryState copyWith({
    SummaryStatus? status,
    CareSummaryModel? summary,
  }) {
    return SummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [status, summary];
}

// ──────────────────────────────────── Bloc ───────────────────────────────────

class SummaryBloc extends Bloc<SummaryEvent, SummaryState> {
  SummaryBloc({required LocalStorageService storageService})
      : _storage = storageService,
        super(const SummaryState()) {
    on<SummaryLoaded>(_onLoaded);
    on<SummaryCleared>(_onCleared);
  }

  final LocalStorageService _storage;
  static const _uuid = Uuid();

  Future<void> _onLoaded(
    SummaryLoaded event,
    Emitter<SummaryState> emit,
  ) async {
    // Ensure every saved summary has a non-empty session ID so Hive keys
    // are unique and the delete-by-ID path works correctly.
    var summary = event.summary;
    if (summary.sessionId.isEmpty) {
      summary = summary.copyWith(sessionId: _uuid.v4());
    }

    emit(state.copyWith(status: SummaryStatus.loaded, summary: summary));

    // Persist to local storage so the history screen can show it.
    try {
      await _storage.saveSummary(summary);
    } catch (_) {
      // Storage failure is non-fatal — session summary is still shown on screen.
    }
  }

  void _onCleared(SummaryCleared event, Emitter<SummaryState> emit) {
    emit(const SummaryState());
  }
}
