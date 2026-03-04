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

  /// Controller used as the recording sink (Uint8List in flutter_sound 9.30+).
  StreamController<Uint8List>? _recorderStreamCtrl;

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
    if (_recorder!.isStopped) {
      await _recorder!.openRecorder();
    }

    // Create a stream controller to receive recorded data.
    _recorderStreamCtrl = StreamController<Uint8List>();

    // flutter_sound 9.30+ delivers Uint8List directly via toStream.
    _recorderStreamCtrl!.stream.listen(onChunk);

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
    await _recorderStreamCtrl?.close();

    _recorderStreamCtrl = null;
    _isRecording = false;
  }

  bool get isRecording => _isRecording;

  // ---------------------------------------------------------------
  //  Playback (PCM 24 kHz → speaker)
  // ---------------------------------------------------------------

  /// Plays a complete buffer of raw PCM audio (24 kHz, 16-bit mono) by
  /// dynamically wrapping it in a standard WAV header, ensuring stable playback
  /// without threading stutters.
  Future<void> playWavBuffer(Uint8List rawPcm, void Function() onFinished) async {
    // Interrupt any currently playing audio
    await stopPlayback();

    if (!_isPlayerOpen) {
      _player ??= FlutterSoundPlayer();
      if (!_player!.isOpen()) {
        await _player!.openPlayer();
      }
      _isPlayerOpen = true;
    }

    // Attach WAV header to the raw PCM data
    final header = _buildWavHeader(rawPcm.length, kPlaySampleRate, kNumChannels);
    final wavBytes = Uint8List(header.length + rawPcm.length);
    wavBytes.setAll(0, header);
    wavBytes.setAll(header.length, rawPcm);

    await _player!.startPlayer(
      fromDataBuffer: wavBytes,
      codec: Codec.pcm16WAV,
      whenFinished: () {
        onFinished();
      },
    );
  }

  /// Builds a standard 44-byte WAV header for the raw PCM stream.
  Uint8List _buildWavHeader(int dataLength, int sampleRate, int channels) {
    final byteRate = sampleRate * channels * 2;
    final header = ByteData(44);
    header.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    header.setUint32(4, dataLength + 36, Endian.little); // ChunkSize
    header.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    header.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    header.setUint32(16, 16, Endian.little); // Subchunk1Size
    header.setUint16(20, 1, Endian.little); // AudioFormat (PCM)
    header.setUint16(22, channels, Endian.little); // NumChannels
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, byteRate, Endian.little); // ByteRate
    header.setUint16(32, channels * 2, Endian.little); // BlockAlign
    header.setUint16(34, 16, Endian.little); // BitsPerSample
    header.setUint32(36, 0x64617461, Endian.big); // "data"
    header.setUint32(40, dataLength, Endian.little); // Subchunk2Size
    return header.buffer.asUint8List();
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
