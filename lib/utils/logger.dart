import 'package:flutter/foundation.dart';

/// Simple app-wide logger.
class AppLogger {
  AppLogger._();

  static void info(String tag, String message) {
    debugPrint('[$tag] $message');
  }

  static void error(String tag, String message, [Object? error]) {
    debugPrint('[$tag] ERROR: $message ${error ?? ''}');
  }

  static void warning(String tag, String message) {
    debugPrint('[$tag] WARN: $message');
  }
}
