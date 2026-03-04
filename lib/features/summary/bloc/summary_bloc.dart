import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';

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
  SummaryBloc() : super(const SummaryState()) {
    on<SummaryLoaded>(_onLoaded);
    on<SummaryCleared>(_onCleared);
  }

  void _onLoaded(SummaryLoaded event, Emitter<SummaryState> emit) {
    emit(state.copyWith(
      status: SummaryStatus.loaded,
      summary: event.summary,
    ));
  }

  void _onCleared(SummaryCleared event, Emitter<SummaryState> emit) {
    emit(const SummaryState());
  }
}
