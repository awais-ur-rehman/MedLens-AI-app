/// App-wide constants for MedLens AI.
class AppConstants {
  AppConstants._();

  // API
  static const String defaultBackendUrl = 'ws://10.0.2.2:8080'; // Android emulator
  static const String wsSessionEndpoint = '/ws/session';
  static const Duration wsReconnectDelay = Duration(seconds: 3);
  static const int wsMaxReconnectAttempts = 5;

  // Audio
  static const int micSampleRate = 16000; // 16kHz mono PCM
  static const int speakerSampleRate = 24000; // 24kHz mono PCM from Gemini
  static const int audioChunkDurationMs = 25; // 25ms chunks
  static const int audioChunkBytes = 800; // 16kHz * 16-bit * 25ms = 800 bytes

  // Camera
  static const int cameraFrameIntervalMs = 1000; // 1 FPS
  static const int cameraMaxDimension = 1024; // Max px on longest side
  static const int cameraJpegQuality = 70;

  // Session
  static const Duration sessionTimeout = Duration(minutes: 30);

  // App
  static const String appName = 'MedLens AI';
  static const String appTagline = 'See it. Speak it. Save it.';
  static const String doctorName = 'Dr. Muhammad';
}
