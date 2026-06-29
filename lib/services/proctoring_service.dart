import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../models/exam_config.dart';

class ProctoringService {
  CameraController? _cameraController;
  Timer? _captureTimer;
  bool _isRunning = false;
  String? _uploadUrl;

  final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
  final ValueNotifier<int> snapshotsTaken = ValueNotifier<int>(0);

  CameraController? get cameraController => _cameraController;
  bool get isRunning => _isRunning;

  Future<void> start({
    required ExamConfig config,
    String? uploadUrl,
  }) async {
    // Validate upload URL scheme at start — reject non-HTTPS immediately.
    if (uploadUrl != null) {
      final uri = Uri.parse(uploadUrl);
      if (uri.scheme != 'https') {
        debugPrint('Proctoring start rejected: upload URL must use HTTPS, got ${uri.scheme}');
        return;
      }
    }
    _uploadUrl = uploadUrl;

    // Request camera permission before attempting to use the camera
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint('Camera permission denied');
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('No camera available');
      return;
    }

    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    isActive.value = true;

    _isRunning = true;
    _captureTimer = Timer.periodic(
      Duration(seconds: config.proctoringIntervalSeconds),
      (_) => _captureAndUpload(),
    );
  }

  Future<void> _captureAndUpload() async {
    if (!_isRunning || _cameraController == null) return;

    String? imagePath;
    try {
      final image = await _cameraController!.takePicture();
      imagePath = image.path;
      snapshotsTaken.value++;

      if (_uploadUrl != null) {
        final uploadUri = Uri.parse(_uploadUrl!);
        // Reject non-HTTPS URLs — camera images contain biometric data.
        if (uploadUri.scheme != 'https') {
          debugPrint('Upload rejected: URL must use HTTPS, got ${uploadUri.scheme}');
          // Continue to cleanup; don't upload over HTTP.
        } else {
          final request = http.MultipartRequest('POST', uploadUri);
          request.files.add(
            await http.MultipartFile.fromPath('snapshot', image.path),
          );
          final response = await request.send();
          if (response.statusCode != 200) {
            debugPrint('Upload failed: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      debugPrint('Capture/upload error: $e');
    } finally {
      // Securely wipe temp file even if upload failed
      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            // Overwrite with zeros to prevent forensic recovery of biometric data
            final len = await file.length();
            if (len > 0) {
              final raf = await file.open(mode: FileMode.write);
              try {
                // Write zeros in 4KB chunks
                final zeros = List<int>.filled(4096, 0);
                int written = 0;
                while (written < len) {
                  final chunkSize = (len - written).clamp(0, 4096);
                  if (chunkSize <= 0) break;
                  await raf.writeFrom(zeros, 0, chunkSize);
                  written += chunkSize;
                }
              } finally {
                await raf.close();
              }
            }
            await file.delete();
          }
        } catch (_) {}
      }
    }
  }

  Future<void> stop() async {
    _isRunning = false;
    _captureTimer?.cancel();
    _captureTimer = null;

    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}
    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;

    isActive.value = false;
  }

  Future<void> dispose() async {
    await stop();
  }

}
