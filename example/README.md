# BioLogreen Flutter SDK Example

This example demonstrates how to integrate the `biologreen_flutter_sdk` for face-based authentication in a Flutter app.

## Setup
1. Run `flutter pub get` in this directory.
2. Update `lib/main.dart` with your API key and base URL.
3. Run `flutter run` on a physical device (emulator may not support camera).

## Key Code
- Initialize: `BioLogreenClient(apiKey: 'your_key')` and `await client.initialize()`.
- State Listening: Use `AnimatedBuilder` on `client.state` for reactive UI.
- Auth: Call `signupWithFace()` or `loginWithFace()` on button press.

See `lib/main.dart` for full code.