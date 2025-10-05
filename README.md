# BioLogreen Flutter SDK

[![Pub](https://img.shields.io/pub/v/biologreen_flutter_sdk.svg)](https://pub.dev/packages/biologreen_flutter_sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Dart SDK](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev/)

A headless Flutter SDK for seamless face-based user authentication. Provide camera control, on-device face detection, and secure API integration—without any UI widgets. Build custom experiences while we handle the heavy lifting.

## Features
- **Headless Design**: No built-in UI—integrate with your custom `CameraPreview`, overlays, and buttons.
- **Real-Time Face Detection**: Powered by Google ML Kit for fast, accurate on-device processing.
- **Automatic Capture**: Detects stable faces (750ms hold) and captures high-quality images.
- **Secure API Integration**: Base64 encoding + POST to your backend (signup/login endpoints).
- **Reactive State**: Expose loading, detection, and error states via `ChangeNotifier`.
- **Cross-Platform**: Android (10+) and iOS (12+).

## Compatibility
- **Android**: 10+ (API 29+) recommended for optimal real-time performance. Tested on Android 14+ devices (e.g., Pixel, Samsung Galaxy). On legacy devices (Android 8-9), face detection may require format tweaks due to hardware quirks—report issues for support.
- **iOS**: 12+ (physical/simulator).
- **Flutter**: ^3.22.0 or higher.
- **Permissions**: Ensure `<uses-permission android:name="android.permission.CAMERA" />` and `<uses-permission android:name="android.permission.INTERNET" />` in `AndroidManifest.xml` (for model download).

## Installation
Add to your `pubspec.yaml`:

```yaml
dependencies:
  biologreen_flutter_sdk: ^1.0.0

Then run

flutter pub get

Quick Start

Initialize the Client:
dartimport 'package:biologreen_flutter_sdk/biologreen_flutter_sdk.dart';

final client = BioLogreenClient(apiKey: 'your_api_key'); (always put in in the environemt) this api is got from your dashboard on biologreen.com
await client.initialize(); // Starts front camera + detection

## Example
A complete demo app is in the [example/](example/) folder. Run it with:
cd example
flutter pub get
flutter run




Listen to State (in your widget):
dartAnimatedBuilder(
  animation: client.state,
  builder: (context, child) {
    if (client.state.isFaceDetected) {
      // Show overlay: "Hold steady!"
    }
    if (client.state.isLoading) {
      // Show progress
    }
    return CameraPreview(client.cameraController!);
  },
)

Trigger Auth (e.g., on button press):
darttry {
  final response = await client.signupWithFace(customFields: {'email': 'user@example.com'});
  // Handle success: response.userId, response.isNewUser
} catch (e) {
  // Handle error: client.state.error
}

Dispose (in widget dispose):
dartclient.dispose(); // Releases camera/ML resources


API Reference

BioLogreenClient: Facade for orchestration.

initialize(): Starts camera stream and detection.
signupWithFace({Map<String, dynamic>? customFields}) → Future<FaceAuthResponse>: Triggers signup flow.
loginWithFace() → Future<FaceAuthResponse>: Triggers login flow.
dispose(): Cleanup.


BioLogreenStateManager (extends ChangeNotifier):

isInitializing: Camera startup.
isLoading: Auth in progress.
isFaceDetected: Face visible (single/stable).
error: Last error message.


FaceAuthResponse:

userId: int (created/recognized user).
isNewUser: bool (signup vs. login).
customFields: Map? (echoed back).



Example
See the example app for a full integration with CameraPreview and buttons.
Configuration

Backend Endpoints: Defaults to /auth/signup-face and /auth/login-face (POST with image_base64 and X-API-KEY header).
Custom Base URL: Pass baseUrl: 'https://your-api.com/v1' to constructor.
Stability Threshold: Hardcoded 750ms—customize in FaceDetectionService if needed.

Troubleshooting

No Face Detected: Ensure good lighting/face size (40-60% frame). On legacy devices, try accurate mode.
Camera Errors: Check permissions; test on Android 10+.
API Failures: Verify key/endpoints; handle BioLogreenApiException.
Logs: Add print in processImage for debug.

Contributing
Pull requests welcome! Fork, branch, and submit PRs. Run dart test before pushing.
License
MIT License—see LICENSE.

Built with ❤️ by [Atuhurra Solomon] – Questions? Open an issue!