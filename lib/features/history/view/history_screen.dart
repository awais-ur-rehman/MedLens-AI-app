import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:medlens_mobile/config/theme.dart';
import 'package:medlens_mobile/features/history/bloc/history_bloc.dart';
import 'package:medlens_mobile/features/history/widgets/session_tile.dart';
import 'package:medlens_mobile/features/summary/bloc/summary_bloc.dart';

/// History screen — scrollable list of past session summaries.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Load summaries when screen opens.
    context.read<HistoryBloc>().add(const HistoryLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed('home'),
        ),
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          // ── Loading ───────────────────────────────────────────────
          if (state.status == HistoryStatus.loading ||
              state.status == HistoryStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error ────────────────────────────────────────────────
          if (state.status == HistoryStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: MedLensTheme.error),
                    const SizedBox(height: 16),
                    Text(
                      state.errorMessage ?? 'Failed to load history.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: MedLensTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => context
                          .read<HistoryBloc>()
                          .add(const HistoryLoaded()),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Empty ────────────────────────────────────────────────
          if (state.summaries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 56,
                      color: MedLensTheme.textHint.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No past sessions yet.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: MedLensTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your session summaries will appear here after '
                      'each first-aid session with Dr. Muhammad.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: MedLensTheme.textHint,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.goNamed('session'),
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                      label: const Text('Start Session'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── List ─────────────────────────────────────────────────
          return RefreshIndicator(
            onRefresh: () async {
              context.read<HistoryBloc>().add(const HistoryLoaded());
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.summaries.length,
              itemBuilder: (context, index) {
                final summary = state.summaries[index];
                return SessionTile(
                  summary: summary,
                  onTap: () {
                    // Push the summary into SummaryBloc, then navigate
                    context
                        .read<SummaryBloc>()
                        .add(SummaryLoaded(summary));
                    context.goNamed('summary');
                  },
                  onDelete: () {
                    context
                        .read<HistoryBloc>()
                        .add(HistoryItemDeleted(summary.sessionId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Deleted ${summary.injuryType.isNotEmpty ? summary.injuryType : "session"} summary',
                        ),
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            // Re-save and reload — simple undo
                            // (In production you'd cache the deleted item)
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
