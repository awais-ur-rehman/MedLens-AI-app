import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages the WebSocket connection to the MedLens backend.
///
/// Incoming frames are demuxed into two broadcast streams:
/// - [jsonStream] for JSON control messages (`Map<String, dynamic>`)
/// - [audioStream] for binary PCM audio chunks (`Uint8List`)
class WebSocketService {
  WebSocketService({required String baseUrl}) : _baseUrl = baseUrl;

  final String _baseUrl;

  WebSocketChannel? _channel;

  // ---- broadcast controllers ----

  final StreamController<Map<String, dynamic>> _jsonController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<Uint8List> _audioController =
      StreamController<Uint8List>.broadcast();

  /// JSON control messages from the backend (transcripts, errors, summaries).
  Stream<Map<String, dynamic>> get jsonStream => _jsonController.stream;

  /// Raw PCM audio chunks from the backend (Dr. Muhammad's voice).
  Stream<Uint8List> get audioStream => _audioController.stream;

  bool get isConnected => _channel != null;

  // ---------------------------------------------------------------
  //  Connection
  // ---------------------------------------------------------------

  /// Open a WebSocket connection to the backend.
  Future<void> connect() async {
    final uri = Uri.parse('$_baseUrl/ws/session');
    _channel = WebSocketChannel.connect(uri);

    // Wait for the underlying connection to be established.
    await _channel!.ready;

    // Listen and demux incoming frames.
    _channel!.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  // ---------------------------------------------------------------
  //  Sending
  // ---------------------------------------------------------------

  /// Send a JSON control message to the backend.
  void sendJson(Map<String, dynamic> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  /// Send raw binary data (PCM audio) to the backend.
  void sendBinary(Uint8List data) {
    _channel?.sink.add(data);
  }

  // ---------------------------------------------------------------
  //  Teardown
  // ---------------------------------------------------------------

  /// Close the WebSocket connection and free resources.
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
  }

  /// Permanently close all streams.  Call only when the service will not be
  /// reused (e.g. app shutdown).
  Future<void> dispose() async {
    await disconnect();
    await _jsonController.close();
    await _audioController.close();
  }

  // ---------------------------------------------------------------
  //  Internal listeners
  // ---------------------------------------------------------------

  void _onData(dynamic data) {
    if (data is String) {
      // Text frame → JSON control message.
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        _jsonController.add(decoded);
      } catch (e) {
        _jsonController.add({
          'type': 'error',
          'message': 'Failed to decode server message: $e',
        });
      }
    } else if (data is List<int>) {
      // Binary frame → PCM audio.
      _audioController.add(Uint8List.fromList(data));
    }
  }

  void _onError(Object error) {
    _jsonController.add({
      'type': 'error',
      'message': 'WebSocket error: $error',
    });
  }

  void _onDone() {
    _jsonController.add({'type': 'disconnected'});
    _channel = null;
  }
}
