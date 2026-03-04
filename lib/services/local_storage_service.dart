import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:medlens_mobile/models/care_summary_model.dart';

/// Persistent storage backed by Hive.
///
/// Stores [CareSummaryModel] instances as JSON strings in a Hive box,
/// keyed by `sessionId`.  No code generation or TypeAdapters needed.
class LocalStorageService {
  static const _boxName = 'summaries';

  Box<String>? _box;

  // ── Lifecycle ──────────────────────────────────────────────────────

  /// Initialise Hive and open the summaries box.
  ///
  /// Call once in `main()` before `runApp`.
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  // ── Write ──────────────────────────────────────────────────────────

  /// Persist a care summary. Uses `sessionId` as the key.
  Future<void> saveSummary(CareSummaryModel summary) async {
    final box = _ensureBox();
    final json = jsonEncode(summary.toJson());
    await box.put(summary.sessionId, json);
  }

  // ── Read ───────────────────────────────────────────────────────────

  /// Return all summaries, newest first.
  List<CareSummaryModel> getSummaries() {
    final box = _ensureBox();
    final summaries = box.values
        .map((raw) => CareSummaryModel.fromJson(
              jsonDecode(raw) as Map<String, dynamic>,
            ))
        .toList();

    summaries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return summaries;
  }

  /// Return a single summary by session ID, or `null`.
  CareSummaryModel? getSummary(String sessionId) {
    final box = _ensureBox();
    final raw = box.get(sessionId);
    if (raw == null) return null;
    return CareSummaryModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────

  /// Delete a specific summary.
  Future<void> deleteSummary(String sessionId) async {
    final box = _ensureBox();
    await box.delete(sessionId);
  }

  /// Delete all stored summaries.
  Future<void> clearAll() async {
    final box = _ensureBox();
    await box.clear();
  }

  // ── Internal ───────────────────────────────────────────────────────

  Box<String> _ensureBox() {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError(
        'LocalStorageService not initialised. Call init() first.',
      );
    }
    return box;
  }
}
