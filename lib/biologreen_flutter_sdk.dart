/// The official Flutter SDK for the BioLogreen Facial Authentication API.
///
/// This library provides a headless, robust, and modern toolkit for integrating
/// face-based authentication into Flutter applications. It handles all the complex
/// logic for camera management, on-device face detection, and API communication,
/// allowing developers to build their own custom UI.
library biologreen_flutter_sdk;

// --- Public API Exports ---

// Export the main client facade, which is the primary entry point for the SDK.
export 'src/biologreen_client.dart';

// Export the state manager so developers can listen to reactive state changes.
export 'src/state/state_manager.dart';

// Export the core data models and custom exceptions for robust, type-safe code.
export 'src/services/api_service.dart'
    show FaceAuthResponse, BioLogreenApiException;
