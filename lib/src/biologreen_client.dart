// lib/src/biologreen_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'services/api_service.dart';
import 'services/camera_service.dart';
import 'services/face_detection_service.dart';
import 'state/state_manager.dart';

/// The main public entry point for the BioLogreen Flutter SDK.
///
/// This class acts as a facade, orchestrating the underlying services
/// for camera management, face detection, and API communication to provide
/// a simple and powerful developer experience.
class BioLogreenClient {
  // The internal services that power the SDK
  final CameraService _cameraService;
  final FaceDetectionService _faceDetectionService;
  final ApiService _apiService;

  /// The reactive state manager for the SDK.
  /// Developers can listen to this to update their UI.
  final BioLogreenStateManager state;

  // Internal state for managing the capture process
  Completer<FaceAuthResponse>? _captureCompleter;
  Map<String, dynamic>? _signupCustomFields;
  String _captureMode = 'login';

  CameraController? get cameraController => _cameraService.controller;

  /// Creates a new instance of the BioLogreenClient.
  ///
  /// [apiKey] is your secret API key from the BioLogreen developer dashboard.
  /// [baseUrl] is optional and can be used to point to a local testing server.
  BioLogreenClient({
    required String apiKey,
    String? baseUrl,
    // Services can be injected for advanced testing, but have default implementations.
    CameraService? cameraService,
    FaceDetectionService? faceDetectionService,
    ApiService? apiService,
  })  : _cameraService = cameraService ?? CameraService(),
        _faceDetectionService = faceDetectionService ?? FaceDetectionService(),
        _apiService = apiService ?? ApiService(apiKey: apiKey, baseUrl: baseUrl ?? 'https://api.biologreen.com/v1'),
        state = BioLogreenStateManager();

  /// Initializes the SDK.
  ///
  /// This must be called before any other methods. It starts the camera,
  /// begins processing the video stream, and sets up face detection.
  Future<void> initialize() async {
    try {
      state.isInitializing = true;
      state.error = null;

      // Start the camera service
      await _cameraService.initialize();

      // Listen for images from the camera and pass them to the face detector
      _cameraService.imageStream.listen((image) async {
        if (_cameraService.cameraDescription != null) {
          await _faceDetectionService.processImage(
            image: image,
            cameraDescription: _cameraService.cameraDescription!,
          );
          state.isFaceDetected = _faceDetectionService.isFaceDetected;
        }
      });

      // Set up the callback for when a stable face is found
      _faceDetectionService.onStableFaceFound = _onStableFaceFound;

      state.isInitializing = false;
    } catch (e) {
      state.isInitializing = false;
      state.error = 'Failed to initialize BioLogreen SDK: ${e.toString()}';
      rethrow;
    }
  }

  /// Initiates a face signup attempt.
  /// Returns a `Future` that completes with the API response once a stable face is captured.
  Future<FaceAuthResponse> signupWithFace({Map<String, dynamic>? customFields}) {
    if (state.isLoading) {
      return Future.error(Exception("An authentication process is already in progress."));
    }
    _captureMode = 'signup';
    _signupCustomFields = customFields;
    _captureCompleter = Completer<FaceAuthResponse>();
    return _captureCompleter!.future;
  }

  /// Initiates a face login attempt.
  /// Returns a `Future` that completes with the API response once a stable face is captured.
  Future<FaceAuthResponse> loginWithFace() {
    if (state.isLoading) {
      return Future.error(Exception("An authentication process is already in progress."));
    }
    _captureMode = 'login';
    _signupCustomFields = null;
    _captureCompleter = Completer<FaceAuthResponse>();
    return _captureCompleter!.future;
  }

  /// Internal callback that is triggered when the FaceDetectionService finds a stable face.
  Future<void> _onStableFaceFound() async {
    if (_captureCompleter == null || state.isLoading) return;

    state.isLoading = true;
    state.error = null;

    try {
      // Capture a high-quality image using the camera service
      final XFile imageFile = await _cameraService.captureImage();
      final bytes = await File(imageFile.path).readAsBytes();
      final imageBase64 = base64Encode(bytes);

      // Call the appropriate API method
      FaceAuthResponse response;
      if (_captureMode == 'login') {
        response = await _apiService.login(imageBase64: imageBase64);
      } else {
        response = await _apiService.signup(
          imageBase64: imageBase64,
          customFields: _signupCustomFields,
        );
      }
      _captureCompleter?.complete(response);
    } catch (e) {
      state.error = e.toString();
      _captureCompleter?.completeError(e);
    } finally {
      state.isLoading = false;
      _captureCompleter = null; // Reset for the next operation
    }
  }

  /// Disposes of all services to free up system resources (camera, etc.).
  /// This must be called when the client is no longer needed.
  void dispose() {
    _cameraService.dispose();
    _faceDetectionService.dispose();
    state.dispose();
  }
}