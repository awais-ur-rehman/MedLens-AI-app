import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Handles camera initialization, single frame capture, and live streaming bursts.
///
/// Images are resized to a max of 1024 px on the longest side, and JPEG-encoded
/// at quality 70 to save bandwidth and API cost.
class CameraService {
  CameraController? _controller;
  Timer? _captureTimer;

  /// The underlying [CameraController] — available after [initialize].
  CameraController? get controller => _controller;

  /// Whether the camera has been successfully initialised.
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  // ---------------------------------------------------------------
  //  Initialization
  // ---------------------------------------------------------------

  /// Initialise the camera, preferring the rear lens.
  Future<void> initialize() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('No cameras available on this device');
    }

    // Prefer the rear camera; fall back to whatever is available.
    final selected = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
  }

  // ---------------------------------------------------------------
  //  Single Photo Capture
  // ---------------------------------------------------------------

  /// Capture a single, high-quality JPEG frame on-demand.
  Future<Uint8List?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    if (_controller!.value.isTakingPicture) return null;

    try {
      final xFile = await _controller!.takePicture();
      final rawBytes = await xFile.readAsBytes();

      // Clean up temp file
      try {
        await File(xFile.path).delete();
      } catch (_) {}

      return _compressImage(rawBytes);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------
  //  Live Streaming (On-Demand Burst)
  // ---------------------------------------------------------------

  /// Start capturing JPEG frames at [intervalMs] millisecond intervals.
  void startLiveStream({
    required void Function(Uint8List jpegBytes) onFrame,
    int intervalMs = 1000,
  }) {
    // Avoid double-starting.
    _captureTimer?.cancel();

    _captureTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => _captureFrame(onFrame),
    );
  }

  /// Stop the active live stream timer.
  void stopLiveStream() {
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  // ---------------------------------------------------------------
  //  Internal capture + compress
  // ---------------------------------------------------------------

  Future<void> _captureFrame(
    void Function(Uint8List) onFrame,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Prevent overlapping captures if the previous one is still in flight.
    if (_controller!.value.isTakingPicture) return;

    try {
      final xFile = await _controller!.takePicture();
      final rawBytes = await xFile.readAsBytes();

      // Clean up the temp file immediately.
      try {
        await File(xFile.path).delete();
      } catch (_) {
        // Best-effort cleanup.
      }

      // Decode → resize → re-encode on the current isolate.
      // For heavier workloads this could be moved to compute().
      final compressed = _compressImage(rawBytes);
      if (compressed != null) {
        onFrame(compressed);
      }
    } catch (_) {
      // Silently skip frames that fail (e.g. camera busy).
    }
  }

  /// Resize to max 1024 px on the longest side and JPEG-encode at quality 70.
  Uint8List? _compressImage(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) return null;

    // Only resize if either dimension exceeds 1024.
    img.Image resized;
    if (decoded.width > 1024 || decoded.height > 1024) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: 1024);
      } else {
        resized = img.copyResize(decoded, height: 1024);
      }
    } else {
      resized = decoded;
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 70));
  }

  // ---------------------------------------------------------------
  //  Cleanup
  // ---------------------------------------------------------------

  /// Release all camera resources.
  Future<void> dispose() async {
    stopLiveStream();
    await _controller?.dispose();
    _controller = null;
  }
}
