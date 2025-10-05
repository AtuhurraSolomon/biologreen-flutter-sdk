// lib/src/services/face_detection_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

/// A robust service dedicated to processing camera images to detect faces.
///
/// This service encapsulates all interactions with Google's ML Kit face detection library.
/// It includes the definitive, modern logic for converting a `CameraImage` into a format
/// that the ML model can reliably process, including handling complex rotations and mirroring.
class FaceDetectionService {
  final FaceDetector _faceDetector;
  Timer? _stabilityTimer;
  bool _isDetecting = false;
  bool _isFaceDetected = false;

  bool get isFaceDetected => _isFaceDetected;

  // A callback to be triggered when a stable face is found.
  VoidCallback? onStableFaceFound;

  FaceDetectionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.fast, // Use fast mode for real-time detection
          ),
        );

  /// Processes a single camera image to detect faces.
  /// If a single face is found, it starts a stability check.
  Future<void> processImage({
    required CameraImage image,
    required CameraDescription cameraDescription,
  }) async {
    if (_isDetecting) return;
    _isDetecting = true;

    // Use the definitive conversion logic to create an InputImage
    final inputImage = await _inputImageFromCameraImage(image, cameraDescription);
    if (inputImage == null) {
      _isDetecting = false;
      return;
    }

    final faces = await _faceDetector.processImage(inputImage);

    _isFaceDetected = faces.length == 1;

    if (faces.length == 1) {
      // If one face is found, start a timer. If the timer completes without the
      // face being lost, we consider it "stable".
      _stabilityTimer ??= Timer(const Duration(milliseconds: 750), () {
        onStableFaceFound?.call();
        _stabilityTimer = null; // Reset after firing
      });
    } else {
      // If no face (or more than one face) is found, cancel the stability timer.
      _stabilityTimer?.cancel();
      _stabilityTimer = null;
    }

    _isDetecting = false;
  }

  /// Disposes of the face detector to free up resources.
  void dispose() {
    _stabilityTimer?.cancel();
    _faceDetector.close();
  }

  // --- Definitive Image Conversion Logic (updated for Android NV21 compatibility) ---

  /// Converts a [CameraImage] to an [InputImage] for ML Kit processing.
  /// This includes crucial logic for handling image format, rotation, and mirroring.
  Future<InputImage?> _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) async {
    // Get the device's current orientation
    final deviceOrientation = await NativeDeviceOrientationCommunicator().orientation(useSensor: true);
    final deviceRotation = _orientationToDegrees(deviceOrientation);

    // Calculate the rotation compensation
    final sensorOrientation = camera.sensorOrientation;
    int rotationCompensation = (sensorOrientation - deviceRotation + 360) % 360;

    // Special handling for the front camera to account for mirroring
    if (camera.lensDirection == CameraLensDirection.front) {
      if (Platform.isAndroid) {
        rotationCompensation = (360 - rotationCompensation) % 360;
      } else if (Platform.isIOS) {
        rotationCompensation = (rotationCompensation + 180) % 360;
      }
    }

    final rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    if (rotation == null) return null;

    // Dynamically get format from image, but force NV21 for Android camera (yuv420 output)
    InputImageFormat format;
    if (Platform.isAndroid) {
      format = InputImageFormat.nv21;  // Matches camera's NV21 output
    } else {
      format = InputImageFormat.bgra8888;
    }

    // Concatenate planes into single buffer (works for NV21: Y + VU interleaved)
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // Metadata: bytesPerRow=0 for NV21 (single buffer, no row stride needed)
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format,
      bytesPerRow: Platform.isAndroid ? 0 : image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  /// Converts a [NativeDeviceOrientation] enum to an integer value in degrees.
  int _orientationToDegrees(NativeDeviceOrientation orientation) {
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
        return 90;
      case NativeDeviceOrientation.portraitDown:
        return 180;
      case NativeDeviceOrientation.landscapeRight:
        return 270;
      default:
        return 0; // PortraitUp and Unknown
    }
  }
}