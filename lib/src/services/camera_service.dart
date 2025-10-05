// lib/src/services/camera_service.dart
import 'dart:async';
import 'package:camera/camera.dart';

/// A robust service dedicated to managing all camera-related operations.
///
/// This service handles initializing the camera, managing the image stream,
/// and capturing high-quality still images, isolating all interactions
/// with the `camera` plugin.
class CameraService {
  CameraController? _controller;
  CameraDescription? _cameraDescription;
  bool _isDisposed = false;

  // A StreamController to broadcast the camera image stream to listeners.
  final StreamController<CameraImage> _imageStreamController =
      StreamController.broadcast();

  /// A public stream of camera images that other services can listen to.
  Stream<CameraImage> get imageStream => _imageStreamController.stream;

  /// The description of the currently used camera device.
  CameraDescription? get cameraDescription => _cameraDescription;

  /// The main CameraController instance.
  CameraController? get controller => _controller;

  /// Finds the front-facing camera, initializes the CameraController,
  /// and starts the image stream.
  /// Throws an exception if no cameras are found or if initialization fails.
  Future<void> initialize() async {
    if (_controller != null) return; // Already initialized

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras found on this device.');
    }

    // Prefer the front camera for face authentication
    _cameraDescription = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      _cameraDescription!,
      ResolutionPreset.high,
      enableAudio: false,
      // Use yuv420 for broad compatibility with ML Kit, as recommended
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    await _controller!.startImageStream((image) {
      if (!_isDisposed && !_imageStreamController.isClosed) {
        _imageStreamController.add(image);
      }
    });
  }

  /// Captures a high-resolution still image from the camera.
  ///
  /// This method temporarily stops the image stream to ensure the highest quality
  /// capture and then restarts it.
  Future<XFile> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera is not initialized.');
    }

    // Stop the stream for a high-quality capture, as streaming can reduce quality.
    await _controller!.stopImageStream();

    final XFile imageFile = await _controller!.takePicture();

    // Restart the stream after capturing the image.
    if (!_isDisposed) {
      await _controller!.startImageStream((image) {
        if (!_isDisposed && !_imageStreamController.isClosed) {
          _imageStreamController.add(image);
        }
      });
    }

    return imageFile;
  }

  /// Disposes of the camera controller and stream to free up system resources.
  /// This must be called when the camera is no longer needed.
  void dispose() {
    _isDisposed = true;
    _controller?.stopImageStream();
    _controller?.dispose();
    _imageStreamController.close();
  }
}
