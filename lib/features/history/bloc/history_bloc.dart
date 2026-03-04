import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';
import 'package:medlens_mobile/services/local_storage_service.dart';

// ─────────────────────────────────── Events ──────────────────────────────────

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

/// Load all summaries from local storage.
final class HistoryLoaded extends HistoryEvent {
  const HistoryLoaded();
}

/// Delete a single summary by session ID.
final class HistoryItemDeleted extends HistoryEvent {
  const HistoryItemDeleted(this.sessionId);
  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

// ─────────────────────────────────── State ───────────────────────────────────

enum HistoryStatus { initial, loading, loaded, error }

final class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.summaries = const [],
    this.errorMessage,
  });

  final HistoryStatus status;
  final List<CareSummaryModel> summaries;
  final String? errorMessage;

  HistoryState copyWith({
    HistoryStatus? status,
    List<CareSummaryModel>? summaries,
    String? errorMessage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      summaries: summaries ?? this.summaries,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summaries, errorMessage];
}

// ──────────────────────────────────── Bloc ───────────────────────────────────

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required LocalStorageService storageService})
      : _storage = storageService,
        super(const HistoryState()) {
    on<HistoryLoaded>(_onLoaded);
    on<HistoryItemDeleted>(_onDeleted);
  }

  final LocalStorageService _storage;

  void _onLoaded(HistoryLoaded event, Emitter<HistoryState> emit) {
    emit(state.copyWith(status: HistoryStatus.loading));

    try {
      final summaries = _storage.getSummaries();
      emit(state.copyWith(
        status: HistoryStatus.loaded,
        summaries: summaries,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleted(
    HistoryItemDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    await _storage.deleteSummary(event.sessionId);
    final updated = _storage.getSummaries();
    emit(state.copyWith(
      status: HistoryStatus.loaded,
      summaries: updated,
    ));
  }
}
