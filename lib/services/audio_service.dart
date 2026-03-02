import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';

/// Handles low-level microphone recording (16 kHz PCM) and speaker playback
/// (24 kHz PCM) for the MedLens real-time session.
///
/// Recording and playback use **different sample rates** because Gemini Live
/// expects 16 kHz input but outputs 24 kHz audio.
class AudioService {
  // ---------- constants ----------

  /// Recording sample rate expected by Gemini Live (input).
  static const int kRecordSampleRate = 16000;

  /// Playback sample rate produced by Gemini Live (output).
  static const int kPlaySampleRate = 24000;

  /// Number of audio channels (mono).
  static const int kNumChannels = 1;

  /// Size of each PCM buffer delivered via [onChunk] (~25 ms at 16 kHz mono
  /// 16-bit = 800 bytes).
  static const int kBufferSize = 800;

  // ---------- internals ----------

  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;

  /// Subscription on the recording stream coming from flutter_sound.
  StreamSubscription<Uint8List>? _recorderSub;

  /// Controller used as the recording sink.
  StreamController<Food>? _recorderStreamCtrl;

  /// Sink used to feed PCM data into the player.
  StreamController<Food>? _playerFoodCtrl;

  bool _isRecording = false;
  bool _isPlayerOpen = false;

  // ---------------------------------------------------------------
  //  Recording (microphone → PCM 16 kHz)
  // ---------------------------------------------------------------

  /// Begin recording from the microphone and stream raw PCM chunks.
  ///
  /// Each [onChunk] callback delivers a [Uint8List] of 16-bit little-endian
  /// PCM samples at [kRecordSampleRate] Hz, mono.
  Future<void> startRecording({
    required void Function(Uint8List chunk) onChunk,
  }) async {
    if (_isRecording) return;

    // Ensure recorder is open.
    _recorder ??= FlutterSoundRecorder();
    if (!_recorder!.isOpen()) {
      await _recorder!.openRecorder();
    }

    // Create a stream controller to receive recorded data.
    _recorderStreamCtrl = StreamController<Food>();

    // flutter_sound delivers `FoodData` events via this stream.
    _recorderSub = _recorderStreamCtrl!.stream
        .where((food) => food is FoodData)
        .cast<FoodData>()
        .map((foodData) => foodData.data!)
        .listen(onChunk);

    await _recorder!.startRecorder(
      toStream: _recorderStreamCtrl!.sink,
      codec: Codec.pcm16,
      numChannels: kNumChannels,
      sampleRate: kRecordSampleRate,
      bufferSize: kBufferSize,
    );

    _isRecording = true;
  }

  /// Stop the microphone recording.
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    await _recorder?.stopRecorder();
    await _recorderSub?.cancel();
    await _recorderStreamCtrl?.close();

    _recorderSub = null;
    _recorderStreamCtrl = null;
    _isRecording = false;
  }

  bool get isRecording => _isRecording;

  // ---------------------------------------------------------------
  //  Playback (PCM 24 kHz → speaker)
  // ---------------------------------------------------------------

  /// Feed a chunk of PCM audio (24 kHz, 16-bit mono) to the speaker.
  ///
  /// The player is lazily opened on the first call. Subsequent calls simply
  /// push data into the player's food sink for gapless playback.
  Future<void> playChunk(Uint8List pcmData) async {
    // Lazily open the player and start a streaming session.
    if (!_isPlayerOpen) {
      _player ??= FlutterSoundPlayer();
      if (!_player!.isOpen()) {
        await _player!.openPlayer();
      }

      _playerFoodCtrl = StreamController<Food>();

      await _player!.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: kNumChannels,
        sampleRate: kPlaySampleRate,
      );

      _isPlayerOpen = true;
    }

    // Push the audio data into the player's food sink.
    _player!.foodSink?.add(FoodData(pcmData));
  }

  /// Immediately stop playback — used for barge-in when the user starts
  /// speaking while Dr. Muhammad is still talking.
  Future<void> stopPlayback() async {
    if (!_isPlayerOpen) return;

    try {
      await _player?.stopPlayer();
    } catch (_) {
      // Player may already be stopped.
    }

    await _playerFoodCtrl?.close();
    _playerFoodCtrl = null;
    _isPlayerOpen = false;
  }

  // ---------------------------------------------------------------
  //  Cleanup
  // ---------------------------------------------------------------

  /// Release all native resources.  Call this when the service is no longer
  /// needed (e.g. in a BLoC's `close` or a widget's `dispose`).
  Future<void> dispose() async {
    await stopRecording();
    await stopPlayback();

    await _recorder?.closeRecorder();
    await _player?.closePlayer();

    _recorder = null;
    _player = null;
  }
}
