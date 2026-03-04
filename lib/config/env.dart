import 'dart:io';

/// Environment configuration for dev / prod switching.
///
/// URLs are injected at build time via `--dart-define`:
///
/// ```bash
/// # Development (default — points to local backend)
/// flutter run
///
/// # Production (uses Cloud Run)
/// flutter run --dart-define=BACKEND_WS_URL=wss://medlens-backend-nw7kauj2aa-uc.a.run.app \
///             --dart-define=BACKEND_HTTP_URL=https://medlens-backend-nw7kauj2aa-uc.a.run.app
/// ```
enum Env { dev, prod }

class EnvConfig {
  EnvConfig._();

  // ── Compile-time values from --dart-define ──────────────────────

  static const _wsUrl = String.fromEnvironment(
    'BACKEND_WS_URL',
    defaultValue: '', // empty → use dev default
  );

  static const _httpUrl = String.fromEnvironment(
    'BACKEND_HTTP_URL',
    defaultValue: '',
  );

  // ── Runtime env detection ──────────────────────────────────────

  static Env get current => _wsUrl.isEmpty ? Env.dev : Env.prod;

  static bool get isDebug => current == Env.dev;

  // ── URLs ────────────────────────────────────────────────────────

  /// WebSocket base URL used by [WebSocketService].
  ///
  /// • Dev:  `ws://10.0.2.2:8080`  (Android emulator → host)
  ///         `ws://localhost:8080`  (iOS simulator → host)
  /// • Prod: value from `--dart-define=BACKEND_WS_URL=...`
  static String get backendWsUrl {
    if (_wsUrl.isNotEmpty) return _wsUrl;
    // Default dev URL — pick based on platform.
    return Platform.isAndroid
        ? 'ws://10.0.2.2:8080'
        : 'ws://localhost:8080';
  }

  /// HTTP base URL for REST calls (health check, etc).
  static String get backendHttpUrl {
    if (_httpUrl.isNotEmpty) return _httpUrl;
    return Platform.isAndroid
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  /// Full WebSocket session endpoint.
  static String get wsSessionUrl => '$backendWsUrl/ws/session';

  /// Full health-check endpoint.
  static String get healthUrl => '$backendHttpUrl/health';
}
